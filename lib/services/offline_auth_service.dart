import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class OfflineAuthService {
OfflineAuthService._();

static final OfflineAuthService instance =
OfflineAuthService._();

final Pbkdf2 _algorithm = Pbkdf2(
macAlgorithm: Hmac.sha256(),
iterations: 120000,
bits: 256,
);

/// Creates a password verifier containing:
/// version + salt + derived key.
///
/// We NEVER store the original password.
Future<String> createVerifier(String password) async {
if (password.isEmpty) {
throw Exception('Password cannot be empty.');
}

final salt = _generateSalt();

final secretKey = await _algorithm.deriveKeyFromPassword(
password: password,
nonce: salt,
);

final derivedKey = await secretKey.extractBytes();

return jsonEncode({
'version': 1,
'algorithm': 'PBKDF2-HMAC-SHA256',
'iterations': 120000,
'salt': base64Encode(salt),
'hash': base64Encode(derivedKey),
});
}

/// Verifies the supplied password against the stored verifier.
Future<bool> verifyPassword({
required String password,
required String verifier,
}) async {
try {
final decoded = jsonDecode(verifier);

if (decoded is! Map) {
return false;
}

final saltBase64 =
decoded['salt']?.toString();

final storedHashBase64 =
decoded['hash']?.toString();

final iterations =
int.tryParse(
decoded['iterations']?.toString() ?? '',
) ??
120000;

if (saltBase64 == null ||
saltBase64.isEmpty ||
storedHashBase64 == null ||
storedHashBase64.isEmpty) {
return false;
}

final salt = base64Decode(saltBase64);
final storedHash =
base64Decode(storedHashBase64);

final algorithm = Pbkdf2(
macAlgorithm: Hmac.sha256(),
iterations: iterations,
bits: 256,
);

final secretKey =
await algorithm.deriveKeyFromPassword(
password: password,
nonce: salt,
);

final derivedHash =
await secretKey.extractBytes();

return _constantTimeEquals(
Uint8List.fromList(storedHash),
Uint8List.fromList(derivedHash),
);
} catch (_) {
return false;
}
}

List<int> _generateSalt() {
final random = Random.secure();

return List<int>.generate(
16,
(_) => random.nextInt(256),
);
}

bool _constantTimeEquals(
Uint8List a,
Uint8List b,
) {
if (a.length != b.length) {
return false;
}

var result = 0;

for (var i = 0; i < a.length; i++) {
result |= a[i] ^ b[i];
}

return result == 0;
}
}

