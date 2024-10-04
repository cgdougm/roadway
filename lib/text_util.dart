import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Given a long string, return a string that is a truncated version of the original string, with an ellipsis in the middle.
/// The optional argument is the number of characters to include before the ellipsis and after the ellipsis.
String truncateStringWithEllipsis(String input, {int before = 4, int after = 4}) {
  if (input.length <= before + after + 3) {
    return input;
  }
  return '${input.substring(0, before)}...${input.substring(input.length - after)}';
}

String generateId(String pathOrUrl) {
    final bytes = utf8.encode(pathOrUrl);
    return sha256.convert(bytes).toString();
}
