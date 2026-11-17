import 'package:final_project/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const hasher = PasswordHasher(iterations: 100); // fast for tests

  test('stored format is iterations\$salt\$hash', () {
    final parts = hasher.hash('secret1').split(r'$');
    expect(parts.length, 3);
    expect(parts.first, '100');
  });

  test('right password verifies, wrong one does not', () {
    final h = hasher.hash('secret1');
    expect(hasher.verify('secret1', h), isTrue);
    expect(hasher.verify('secret2', h), isFalse);
  });

  test('same password gives different hashes (random salt)', () {
    expect(hasher.hash('secret1'), isNot(hasher.hash('secret1')));
  });

  test('tampered or malformed hashes never verify', () {
    final parts = hasher.hash('secret1').split(r'$');
    expect(hasher.verify('secret1', [parts[0], parts[1], 'AAAA'].join(r'$')),
        isFalse);
    expect(hasher.verify('secret1', 'plaintext'), isFalse);
    expect(hasher.verify('secret1', r'abc$x$y'), isFalse);
    expect(hasher.verify('secret1', r'99999999$x$y'), isFalse);
    expect(hasher.verify('secret1', r'100$!!!$!!!'), isFalse);
  });
}
