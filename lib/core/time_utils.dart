import 'package:intl/intl.dart';

/// Returns a human-readable string representing how long ago the given DateTime was
/// (e.g. "2 hours ago", "3 days ago", etc.)
String getTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays > 0) {
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
  } else if (difference.inSeconds > 0) {
    return '${difference.inSeconds} second${difference.inSeconds == 1 ? '' : 's'} ago';
  } else {
    return 'just now';
  }
}

/// Formats a DateTime into a human-readable string
/// If withAgo is true, appends "ago" to the end
String formatDateTime(DateTime dateTime, {bool withAgo = false}) {
  final formatter = DateFormat('MMM d, y HH:mm:ss');
  final formatted = formatter.format(dateTime);
  return withAgo ? '$formatted (${getTimeAgo(dateTime)})' : formatted;
} 