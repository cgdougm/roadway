import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; // Added for date formatting

/// Given a long string, return a string that is a truncated version of the original string, with an ellipsis in the middle.
/// The optional argument is the number of characters to include before the ellipsis and after the ellipsis.
String truncateStringWithEllipsis(String input,
    {int before = 4, int after = 4}) {
  if (input.length <= before + after + 3) {
    return input;
  }
  return '${input.substring(0, before)}...${input.substring(input.length - after)}';
}

String generateId(String pathOrUrl) {
  final bytes = utf8.encode(pathOrUrl);
  return sha256.convert(bytes).toString();
}

/// Returns a formatted date string for a given date, with the
///  option to include "ago" format
String formatDateTime(DateTime date, {bool withAgo = false}) {
  final formatter = DateFormat('EEE MMM d, yyyy h:mm a');
  final formattedDate = formatter.format(date);
  if (!withAgo) return formattedDate;

  final timeAgo = getTimeAgo(date);
  return '$formattedDate ($timeAgo)';
}

/// Returns a string with the time "ago format" for a given date
String getTimeAgo(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inDays > 0) return '${difference.inDays} days ago';
  if (difference.inHours > 0) return '${difference.inHours} hours ago';
  if (difference.inMinutes > 0) return '${difference.inMinutes} minutes ago';
  return 'just now';
}

String formatFileSize(int fileLength) {
  if (fileLength < 1024) return '$fileLength bytes';
  if (fileLength < 1024 * 1024) return '${(fileLength / 1024).round()}K';
  if (fileLength < 1024 * 1024 * 1024) {
    return '${(fileLength / (1024 * 1024)).round()}M';
  }
  return '${(fileLength / (1024 * 1024 * 1024)).round()}G';
}

// Given a String, remove its enclosing quote marks (either ' or ")
// Will remove multiple pairs of the same quote, eg. ''my string''
String removeEnclosingQuotes(String text) {
  String clean = text;
  for (int i = 0; i < 3; i++) { // They might have used '''
    if (clean.length >= 2) {
      if ((clean.startsWith("'") && clean.endsWith("'")) ||
          (clean.startsWith('"') && clean.endsWith('"'))) {
        return clean.substring(1, clean.length - 1);
      }
    }
  }
  return text;
}
