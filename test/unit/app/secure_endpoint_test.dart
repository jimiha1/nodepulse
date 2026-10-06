import 'package:flutter_test/flutter_test.dart';
import 'package:nodepulse/core/utils/secure_endpoint.dart';

/// The rule both the settings page and `CfApi.performLogin` apply before a
/// password or token is put on the wire. Its own tests went with the monitor
/// domain in the trim; the helper stayed, and the CF site's login is what
/// reads it now.
void main() {
  test('a remote plaintext address is refused', () {
    expect(isSecureRemoteEndpoint(Uri.parse('http://example.com')), isFalse);
    expect(isSecureRemoteEndpoint(Uri.parse('http://192.0.2.1:8080')), isFalse);
  });

  test('https is available by default', () {
    expect(isSecureRemoteEndpoint(Uri.parse('https://example.com')), isTrue);
    expect(isSecureRemoteEndpoint(Uri.parse('HTTPS://example.com')), isTrue);
  });

  test('loopback over http is available by default', () {
    // A site being developed on this machine is reached over HTTP, and every
    // test in this suite that talks to a local server uses it.
    expect(isSecureRemoteEndpoint(Uri.parse('http://127.0.0.1:3770')), isTrue);
    expect(isSecureRemoteEndpoint(Uri.parse('http://localhost:3770')), isTrue);
    expect(isSecureRemoteEndpoint(Uri.parse('http://[::1]:3770')), isTrue);
  });

  test('anything that is not http or https is refused', () {
    // By scheme, not by prefix: `startsWith('http')` is also true of these.
    for (final bad in ['ftp://example.com', 'ws://example.com', 'file:///etc/passwd']) {
      expect(
        isSecureRemoteEndpoint(Uri.parse(bad)),
        isFalse,
        reason: bad,
      );
    }
  });

  test('a scheme-less or host-less value is refused', () {
    expect(isSecureRemoteEndpoint(Uri.parse('example.com')), isFalse);
    expect(isSecureRemoteEndpoint(Uri.parse('https://')), isFalse);
  });
}
