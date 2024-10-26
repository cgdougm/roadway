import 'package:flutter/material.dart';
import 'package:roadway/icon/markdown.dart';

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
    print('mimeType: $mimeType');
    return const Icon(Icons.file_present);
  }
}
