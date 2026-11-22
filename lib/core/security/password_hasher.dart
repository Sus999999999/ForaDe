import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Almacenamiento seguro de contraseñas: PBKDF2-HMAC-SHA256 con sal aleatoria
/// por contraseña. Nunca se guarda la contraseña, solo la cadena
/// `pbkdf2-sha256$iteraciones$sal$hash` que devuelve [hash].
///
/// Implementado en Dart puro para no depender de paquetes. Si más adelante
/// agregas el paquete `crypto`, solo hay que reemplazar [_hmacSha256].
class PasswordHasher {
  PasswordHasher._();

  static const _scheme = 'pbkdf2-sha256';

  /// Iteraciones de PBKDF2. Súbelas (OWASP recomienda ≥ 600 000) cuando el
  /// hash se calcule en un servidor; 10 000 mantiene fluida la app de prueba.
  static const iterations = 10000;

  static const _saltBytes = 16;
  static const _hashBytes = 32;

  /// Devuelve el hash listo para guardar.
  static String hash(String password) {
    final rng = Random.secure();
    final salt =
        Uint8List.fromList(List<int>.generate(_saltBytes, (_) => rng.nextInt(256)));
    final derived = _pbkdf2(utf8.encode(password), salt, iterations);
    return '$_scheme\$$iterations\$${base64.encode(salt)}\$${base64.encode(derived)}';
  }

  /// true si [password] corresponde a [stored].
  static bool verify(String password, String stored) {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != _scheme) return false;
    final rounds = int.tryParse(parts[1]);
    if (rounds == null || rounds <= 0) return false;
    try {
      final salt = base64.decode(parts[2]);
      final expected = base64.decode(parts[3]);
      final actual = _pbkdf2(utf8.encode(password), salt, rounds);
      return constantTimeEquals(actual, expected);
    } on FormatException {
      return false;
    }
  }

  /// Comparación que tarda lo mismo aunque difieran los primeros bytes.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  // ------------------------------------------------------------------
  // PBKDF2 (RFC 8018) con un solo bloque de 32 bytes
  // ------------------------------------------------------------------
  static Uint8List _pbkdf2(List<int> password, List<int> salt, int rounds) {
    final first = Uint8List(salt.length + 4)
      ..setRange(0, salt.length, salt)
      ..[salt.length + 3] = 1; // INT(1), big-endian

    var u = _hmacSha256(password, first);
    final t = Uint8List.fromList(u);
    for (var i = 1; i < rounds; i++) {
      u = _hmacSha256(password, u);
      for (var j = 0; j < _hashBytes; j++) {
        t[j] ^= u[j];
      }
    }
    return t;
  }

  // ------------------------------------------------------------------
  // HMAC-SHA256 (RFC 2104)
  // ------------------------------------------------------------------
  static Uint8List _hmacSha256(List<int> key, List<int> message) {
    var k = key;
    if (k.length > 64) k = _sha256(k);
    final ipad = Uint8List(64);
    final opad = Uint8List(64);
    for (var i = 0; i < 64; i++) {
      final b = i < k.length ? k[i] : 0;
      ipad[i] = b ^ 0x36;
      opad[i] = b ^ 0x5c;
    }
    final inner = _sha256([...ipad, ...message]);
    return _sha256([...opad, ...inner]);
  }

  // ------------------------------------------------------------------
  // SHA-256 (FIPS 180-4)
  // ------------------------------------------------------------------
  static const _mask = 0xFFFFFFFF;

  static const List<int> _k = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
    0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
    0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
    0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
    0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
    0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  static int _rotr(int x, int n) =>
      ((x & _mask) >> n) | ((x << (32 - n)) & _mask);

  static Uint8List _sha256(List<int> data) {
    // Relleno: 0x80, ceros y la longitud en bits (64 bits, big-endian).
    final bitLength = data.length * 8;
    final padded = <int>[...data, 0x80];
    while (padded.length % 64 != 56) {
      padded.add(0);
    }
    for (var i = 7; i >= 0; i--) {
      padded.add((bitLength >> (8 * i)) & 0xFF);
    }

    var h0 = 0x6a09e667, h1 = 0xbb67ae85, h2 = 0x3c6ef372, h3 = 0xa54ff53a;
    var h4 = 0x510e527f, h5 = 0x9b05688c, h6 = 0x1f83d9ab, h7 = 0x5be0cd19;
    final w = List<int>.filled(64, 0);

    for (var offset = 0; offset < padded.length; offset += 64) {
      for (var i = 0; i < 16; i++) {
        final j = offset + i * 4;
        w[i] = ((padded[j] << 24) |
                (padded[j + 1] << 16) |
                (padded[j + 2] << 8) |
                padded[j + 3]) &
            _mask;
      }
      for (var i = 16; i < 64; i++) {
        final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
        final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & _mask;
      }

      var a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7;
      for (var i = 0; i < 64; i++) {
        final bigS1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final ch = (e & f) ^ ((~e & _mask) & g);
        final t1 = (h + bigS1 + ch + _k[i] + w[i]) & _mask;
        final bigS0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final t2 = (bigS0 + maj) & _mask;
        h = g;
        g = f;
        f = e;
        e = (d + t1) & _mask;
        d = c;
        c = b;
        b = a;
        a = (t1 + t2) & _mask;
      }

      h0 = (h0 + a) & _mask;
      h1 = (h1 + b) & _mask;
      h2 = (h2 + c) & _mask;
      h3 = (h3 + d) & _mask;
      h4 = (h4 + e) & _mask;
      h5 = (h5 + f) & _mask;
      h6 = (h6 + g) & _mask;
      h7 = (h7 + h) & _mask;
    }

    final out = Uint8List(32);
    final words = [h0, h1, h2, h3, h4, h5, h6, h7];
    for (var i = 0; i < 8; i++) {
      out[i * 4] = (words[i] >> 24) & 0xFF;
      out[i * 4 + 1] = (words[i] >> 16) & 0xFF;
      out[i * 4 + 2] = (words[i] >> 8) & 0xFF;
      out[i * 4 + 3] = words[i] & 0xFF;
    }
    return out;
  }
}
