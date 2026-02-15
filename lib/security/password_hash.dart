import 'dart:convert';
import 'package:crypto/crypto.dart';

String generatePasswordHash(String input) {
  return sha256.convert(utf8.encode(input)).toString();
}
