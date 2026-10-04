import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// One DNS-over-HTTPS endpoint.
///
/// [address] is an IP literal on purpose. Bootstrapping a resolver through the
/// resolver is circular, so each provider is reached by address — and the
/// certificate is still checked against [name], so an address that has been
/// taken over cannot answer in the provider's place.
class DohProvider {
  const DohProvider({
    required this.address,
    required this.name,
    required this.path,
  });

  /// The IP the provider is reached at, e.g. `223.5.5.5`.
  final String address;

  /// The name its certificate must cover, and the SNI sent, e.g.
  /// `dns.alidns.com`.
  final String name;

  /// The query path: `/resolve` for AliDNS and Google, `/dns-query` for
  /// DNSPod and Cloudflare.
  final String path;
}

/// The providers, in the order they are tried.
///
/// AliDNS and DNSPod lead because they answer from inside mainland China,
/// which is where a phone that has had its resolver tampered with is most
/// likely to be; Cloudflare and Google follow as a last resort for everywhere
/// else.
const kDohProviders = <DohProvider>[
  DohProvider(address: '223.5.5.5', name: 'dns.alidns.com', path: '/resolve'),
  DohProvider(address: '1.12.12.12', name: 'doh.pub', path: '/dns-query'),
  DohProvider(
    address: '1.1.1.1',
    name: 'cloudflare-dns.com',
    path: '/dns-query',
  ),
  DohProvider(address: '8.8.8.8', name: 'dns.google', path: '/resolve'),
];

/// The A records in a DoH JSON answer.
///
/// The shape differs by provider — AliDNS echoes `Question` as an object,
/// DNSPod as an array — but `Answer` is a list of `{type, data}` in both, and
/// only the `type == 1` entries are addresses a socket can be pointed at.
/// Anything unparseable is skipped rather than thrown over: a resolver that
/// answers with something unexpected should cost one provider, not the
/// lookup.
List<String> parseDohAnswers(String body) {
  Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    return const [];
  }
  if (decoded is! Map) return const [];
  final answers = decoded['Answer'];
  if (answers is! List) return const [];

  final addresses = <String>[];
  for (final entry in answers) {
    if (entry is! Map) continue;
    if (entry['type'] != 1) continue;
    final data = entry['data'];
    if (data is! String) continue;
    final parsed = InternetAddress.tryParse(data);
    if (parsed == null || parsed.type != InternetAddressType.IPv4) continue;
    if (!addresses.contains(data)) addresses.add(data);
  }
  return addresses;
}

/// The name a DoH provider is known by, mapped to the address it is reached
/// at — the bootstrap that lets the first lookup skip the system resolver.
String? pinnedAddressOf(String host, {List<DohProvider>? providers}) {
  for (final provider in providers ?? kDohProviders) {
    if (provider.name == host) return provider.address;
  }
  return null;
}

/// Resolves hostnames over HTTPS instead of the platform resolver.
///
/// The platform resolver is what a poisoned router or a meddling middlebox
/// gets to rewrite, and a rewritten answer is worse than no answer: the
/// connection succeeds, against a server that is not the one that was asked
/// for. DoH answers arrive inside a TLS session whose certificate is checked
/// against a name reached by address, so the same tampering yields a failed
/// lookup instead of a wrong one.
class DohResolver {
  DohResolver({
    List<DohProvider>? providers,
    Future<String> Function(DohProvider provider, String host, Duration timeout)?
    fetch,
    Future<List<String>> Function(String host)? lookup,
    DateTime Function()? clock,
    this.ttl = const Duration(minutes: 5),
    this.timeout = const Duration(seconds: 5),
  }) : providers = providers ?? kDohProviders,
       _fetch = fetch,
       _lookup = lookup,
       _clock = clock ?? DateTime.now;

  final List<DohProvider> providers;
  final Future<String> Function(DohProvider, String, Duration)? _fetch;
  final Future<List<String>> Function(String)? _lookup;
  final DateTime Function() _clock;

  /// How long an answer is reused.
  ///
  /// Long enough that a burst of requests costs one lookup, short enough that
  /// an address which moves is picked up without a restart. A CDN edge moving
  /// is the normal case here, not the exception.
  final Duration ttl;

  /// How long one provider gets before the next is tried.
  final Duration timeout;

  final _cache = <String, _Cached>{};

  /// The addresses [host] resolves to, or empty when no provider answered.
  Future<List<String>> resolve(String host) async {
    final cached = _cache[host];
    if (cached != null && _clock().isBefore(cached.expiresAt)) {
      return cached.addresses;
    }

    for (final provider in providers) {
      try {
        final body = await (_fetch ?? _fetchOverHttps)(provider, host, timeout);
        final addresses = parseDohAnswers(body);
        if (addresses.isEmpty) continue;
        _cache[host] = _Cached(addresses, _clock().add(ttl));
        return addresses;
      } catch (_) {
        // This provider is unreachable or answered with nonsense; the next one
        // is a different network path, which is the whole reason there is a
        // list.
      }
    }
    // Not cached: a resolver that was briefly unreachable is worth asking
    // again, and remembering the failure would pin the host to the fallback
    // for a whole ttl.
    return const [];
  }

  /// [resolve], falling back to the platform resolver.
  ///
  /// The fallback is deliberately last: it is the path being worked around,
  /// and it is still better than failing outright on a network where DoH is
  /// blocked but the resolver is honest.
  Future<List<String>> resolveOrSystem(String host) async {
    final pinned = pinnedAddressOf(host, providers: providers);
    if (pinned != null) return [pinned];

    final resolved = await resolve(host);
    if (resolved.isNotEmpty) return resolved;

    try {
      return await (_lookup ?? _systemLookup)(host);
    } catch (_) {
      return const [];
    }
  }

  Future<String> _fetchOverHttps(
    DohProvider provider,
    String host,
    Duration timeout,
  ) async {
    final client = _bootstrapClient(providers);
    try {
      final uri = Uri.https(provider.name, provider.path, {
        'name': host,
        'type': 'A',
      });
      final request = await client.getUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/dns-json');
      final response = await request.close().timeout(timeout);
      final body = await response.transform(utf8.decoder).join().timeout(timeout);
      if (response.statusCode != 200) {
        throw HttpException('DoH ${response.statusCode}', uri: uri);
      }
      return body;
    } finally {
      client.close(force: true);
    }
  }

  static Future<List<String>> _systemLookup(String host) async {
    final results = await InternetAddress.lookup(host);
    return [
      for (final address in results)
        if (address.type == InternetAddressType.IPv4) address.address,
    ];
  }
}

class _Cached {
  _Cached(this.addresses, this.expiresAt);

  final List<String> addresses;
  final DateTime expiresAt;
}

/// An [HttpClient] that connects to addresses resolved over DoH.
///
/// Every connection is opened to an address this resolver chose, while the TLS
/// handshake still uses the real hostname for SNI and for the certificate
/// check — so pinning the address does not weaken the verification, it only
/// takes the choice of address away from the system resolver.
HttpClient buildDohHttpClient({
  DohResolver? resolver,
  SecurityContext? context,
  bool Function(X509Certificate certificate, String host, int port)?
  onBadCertificate,
}) {
  final doh = resolver ?? kDohResolver;
  final client = HttpClient(context: context);
  client.connectionFactory = (uri, proxyHost, proxyPort) async {
    final host = uri.host;
    final port = uri.port;
    final addresses = await doh.resolveOrSystem(host);
    if (addresses.isEmpty) {
      throw SocketException('No address for $host');
    }

    Object? lastError;
    for (final address in addresses) {
      try {
        final literal = InternetAddress.tryParse(address);
        final socket = await Socket.connect(
          literal ?? address,
          port,
          timeout: const Duration(seconds: 10),
        );
        if (uri.scheme != 'https') {
          return ConnectionTask.fromSocket<Socket>(
            Future.value(socket),
            socket.destroy,
          );
        }
        final secure = await SecureSocket.secure(
          socket,
          host: host,
          context: context,
          onBadCertificate: onBadCertificate == null
              ? null
              : (certificate) => onBadCertificate(certificate, host, port),
        );
        return ConnectionTask.fromSocket<Socket>(
          Future.value(secure),
          secure.destroy,
        );
      } catch (e) {
        // An edge that has gone away is worth the next address in the same
        // answer before the whole lookup is written off.
        lastError = e;
      }
    }
    throw lastError ?? SocketException('No address for $host');
  };
  return client;
}

/// The resolver the app's CF connections share, so one lookup serves the
/// poll, the history fetch and the WebSocket alike.
final kDohResolver = DohResolver();

HttpClient? _bootstrap;

/// The client used to reach the DoH providers themselves.
///
/// It cannot use [buildDohHttpClient] — that resolves through DoH, which is
/// what this client is for. Instead it pins the provider names to their known
/// addresses, which is the one lookup that cannot be bootstrapped, and leaves
/// everything else to the platform.
HttpClient _bootstrapClient(List<DohProvider> providers) {
  final existing = _bootstrap;
  if (existing != null) return existing;

  final client = HttpClient();
  client.connectionFactory = (uri, proxyHost, proxyPort) async {
    final pinned = pinnedAddressOf(uri.host, providers: providers);
    final host = pinned ?? uri.host;
    final socket = await Socket.connect(
      InternetAddress.tryParse(host) ?? host,
      uri.port,
      timeout: const Duration(seconds: 10),
    );
    if (uri.scheme != 'https') {
      return ConnectionTask.fromSocket<Socket>(
        Future.value(socket),
        socket.destroy,
      );
    }
    // The hostname, not the address, is what SNI and the certificate are
    // checked against — the provider's address being pinned does not mean its
    // identity is taken on faith.
    final secure = await SecureSocket.secure(socket, host: uri.host);
    return ConnectionTask.fromSocket<Socket>(
      Future.value(secure),
      secure.destroy,
    );
  };
  return _bootstrap = client;
}
