import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:server_box/data/provider/server/cf/cf_api.dart';
import 'package:server_box/data/provider/server/cf/cf_credentials.dart';

/// The same fixture as `cf_server_test.dart`: a minimal slice of the live
/// `GET /api/servers` response.
const _serversRaw = '''
{"servers":[{
  "id":"fd978320-c32c-474d-857a-3412a7526a7b","name":"日本节点","server_group":"Default",
  "region":"JP","os":"Debian GNU/Linux 13 (trixie)","arch":"arm64","cpu_info":"arm64 (x2)",
  "cpu":3.23,"cpu_cores":2,"load_avg":"0.22 0.17 0.17",
  "ram_total":12268,"ram_used":4987.9,"swap_total":0,"swap_used":0,
  "disk_total":100454,"disk_used":54886,
  "net_in_speed":13200,"net_out_speed":2980,"net_rx":3160000000,"net_tx":4500000000,
  "net_rx_monthly":3160000000,"net_tx_monthly":4500000000,
  "tcp_conn":34,"udp_conn":8,"processes":347,
  "ping_ct":165,"ping_cu":78,"ping_cm":310,"loss_ct":0,"loss_cu":0,"loss_cm":0,
  "boot_time":"1756000000000","expire_date":"2027-10-02","price":"39.90","billing_cycle":"year",
  "traffic_limit":"10TB","traffic_calc_type":"down","last_updated":1759410000000
}],
"stats":{"total":1,"online":1,"globalSpeedIn":13200,"globalSpeedOut":2980,
 "globalNetRx":3160000000,"globalNetTx":4500000000},
"sysConfig":{"show_price":true,"show_expire":true,"show_tf":true}}''';

void main() {
  test('login stores the token and fetchServers sends it as Bearer', () async {
    var logins = 0;
    Map<String, dynamic>? loginBody;
    String? bearer;
    final server = await _serve((request) async {
      if (request.uri.path == '/admin/api') {
        logins++;
        loginBody =
            jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, dynamic>;
        return _json(request.response, {
          'success': true,
          'token': 'jwt-1',
          'message': 'loginSuccessful',
        });
      }
      if (request.uri.path == '/api/servers') {
        bearer = request.headers.value(HttpHeaders.authorizationHeader);
        return _json(request.response, jsonDecode(_serversRaw));
      }
      request.response.statusCode = HttpStatus.notFound;
      return request.response.close();
    });
    final api = CfApi(baseUrl: 'http://127.0.0.1:${server.port}');
    try {
      await api.login('admin', 'pw');
      final snap = await api.fetchServers();

      expect(loginBody, {'action': 'login', 'username': 'admin', 'password': 'pw'});
      expect(bearer, 'Bearer jwt-1');
      expect(api.token, 'jwt-1');
      expect(logins, 1);
      expect(snap.servers.single.name, '日本节点');
      expect(snap.online, 1);
    } finally {
      api.close();
      await server.close(force: true);
    }
  });

  test('an expired token re-logins once and replays the request', () async {
    var logins = 0;
    var fetches = 0;
    final authSeen = <String?>[];
    final server = await _serve((request) async {
      if (request.uri.path == '/admin/api') {
        logins++;
        return _json(request.response, {
          'success': true,
          'token': 'jwt-$logins',
          'message': 'loginSuccessful',
        });
      }
      if (request.uri.path == '/api/servers') {
        authSeen.add(request.headers.value(HttpHeaders.authorizationHeader));
        if (++fetches == 1) {
          request.response.statusCode = HttpStatus.unauthorized;
          return request.response.close();
        }
        return _json(request.response, jsonDecode(_serversRaw));
      }
      request.response.statusCode = HttpStatus.notFound;
      return request.response.close();
    });
    final api = CfApi(baseUrl: 'http://127.0.0.1:${server.port}');
    try {
      await api.login('admin', 'pw');
      final snap = await api.fetchServers();

      expect(snap.servers.single.name, '日本节点');
      expect(logins, 2, reason: 'one user login plus one silent re-login');
      expect(fetches, 2);
      expect(authSeen, ['Bearer jwt-1', 'Bearer jwt-2']);
      expect(api.token, 'jwt-2');
    } finally {
      api.close();
      await server.close(force: true);
    }
  });

  test('a public site is read without any token', () async {
    String? bearer;
    final server = await _serve((request) async {
      if (request.uri.path == '/api/servers') {
        bearer = request.headers.value(HttpHeaders.authorizationHeader);
        return _json(request.response, jsonDecode(_serversRaw));
      }
      request.response.statusCode = HttpStatus.notFound;
      return request.response.close();
    });
    final api = CfApi(baseUrl: 'http://127.0.0.1:${server.port}');
    try {
      final snap = await api.fetchServers();

      expect(api.token, isNull);
      expect(bearer, isNull);
      expect(snap.total, 1);
    } finally {
      api.close();
      await server.close(force: true);
    }
  });

  test('a refused login surfaces the server error key', () async {
    final server = await _serve((request) async {
      if (request.uri.path == '/admin/api') {
        request.response.statusCode = HttpStatus.unauthorized;
        return _json(request.response, {'error': 'invalidCredentials', 'code': 401});
      }
      request.response.statusCode = HttpStatus.notFound;
      return request.response.close();
    });
    final api = CfApi(baseUrl: 'http://127.0.0.1:${server.port}');
    try {
      await expectLater(
        api.login('admin', 'wrong'),
        throwsA(
          isA<CfApiException>()
              .having((e) => e.code, 'code', 401)
              .having((e) => e.message, 'message', 'invalidCredentials'),
        ),
      );
      expect(api.token, isNull);
    } finally {
      api.close();
      await server.close(force: true);
    }
  });

  test('fetchHistory passes id and hours and parses rows', () async {
    Uri? historyUri;
    String? bearer;
    final server = await _serve((request) async {
      if (request.uri.path == '/admin/api') {
        return _json(request.response, {'success': true, 'token': 'jwt-1'});
      }
      if (request.uri.path == '/api/history/all') {
        historyUri = request.uri;
        bearer = request.headers.value(HttpHeaders.authorizationHeader);
        return _json(request.response, [
          {
            'timestamp': 1790927096022,
            'cpu': 6.51,
            'ram_total': 11943,
            'ram_used': 4912.875,
            'disk_total': 100475,
            'disk_used': 54846,
            'disk_read_bps': 0,
            'disk_write_bps': 117927,
            'net_in_speed': 16115,
            'net_out_speed': 9632,
            'tcp_conn': 34,
            'udp_conn': 7,
            'processes': 348,
            'ping_ct': 174,
            'loss_ct': 0,
            'swap_total': 0,
            'swap_used': 0,
            'load_avg': '0.04 0.12 0.15',
          },
          {'timestamp': 42, 'cpu': false, 'ping_ct': false},
        ]);
      }
      request.response.statusCode = HttpStatus.notFound;
      return request.response.close();
    });
    final api = CfApi(baseUrl: 'http://127.0.0.1:${server.port}');
    try {
      await api.login('admin', 'pw');
      final rows = await api.fetchHistory(id: 'abc', hours: 0.5);

      expect(historyUri!.queryParameters['id'], 'abc');
      expect(historyUri!.queryParameters['hours'], '0.5');
      expect(bearer, 'Bearer jwt-1');
      expect(rows, hasLength(2));
      expect(rows.first.cpu, 6.51);
      expect(rows.first.ramUsed, 4913);
      expect(rows.first.diskWriteBps, 117927);
      expect(rows.last.cpu, 0.0);
      expect(rows.last.pingCt, isNull);
    } finally {
      api.close();
      await server.close(force: true);
    }
  });

  test('fetchServerRaw returns the detail object untouched', () async {
    Uri? detailUri;
    final server = await _serve((request) async {
      if (request.uri.path == '/api/server') {
        detailUri = request.uri;
        return _json(request.response, {'id': 'abc', 'name': 'n', 'cpu': 1.5});
      }
      request.response.statusCode = HttpStatus.notFound;
      return request.response.close();
    });
    final api = CfApi(baseUrl: 'http://127.0.0.1:${server.port}');
    try {
      final raw = await api.fetchServerRaw('abc');

      expect(detailUri!.queryParameters['id'], 'abc');
      expect(raw, {'id': 'abc', 'name': 'n', 'cpu': 1.5});
    } finally {
      api.close();
      await server.close(force: true);
    }
  });

  test('expiryOf reads exp from the JWT payload', () {
    String b64(Map<String, Object?> j) => base64Url.encode(utf8.encode(jsonEncode(j)));
    final token = '${b64({'alg': 'HS256', 'typ': 'JWT'})}.'
        '${b64({'sub': 'admin', 'exp': 1790928464})}.sig';

    expect(
      CfCredentials.expiryOf(token),
      DateTime.fromMillisecondsSinceEpoch(1790928464 * 1000),
    );
    expect(CfCredentials.expiryOf('garbage'), isNull);
    expect(CfCredentials.expiryOf('a.b.c'), isNull);
  });
}

Future<HttpServer> _serve(FutureOr<void> Function(HttpRequest request) handler) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    try {
      await handler(request);
    } catch (_) {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  });
  return server;
}

Future<void> _json(HttpResponse response, Object body) async {
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
  await response.close();
}
