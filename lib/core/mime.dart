import 'package:flutter/material.dart';
import 'package:roadway/icon/markdown.dart';
import 'package:mime/mime.dart';

Icon getIconForFilePath(String filePath) {
  final mimeType = lookupMimeType(filePath);
  if (mimeType == null) {
    return const Icon(Icons.device_unknown);
  }
  return getIconForMimeType(mimeType);
}

Icon getIconForMimeType(String mimeType) {
  if (mimeType.startsWith('text/')) {
    if (mimeType.endsWith('/markdown')) {
      return const Icon(MarkdownIcon.markdown);
    } else {
      return const Icon(Icons.text_snippet);
    }
  } else if (mimeType.startsWith('image/')) {
    return const Icon(Icons.image);
  } else if (mimeType == 'Unknown') { // folder
    return const Icon(Icons.folder);
  } else {
    // debugPrint('mimeType: $mimeType');
    return const Icon(Icons.file_present);
  }
}
