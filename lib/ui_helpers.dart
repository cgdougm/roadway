import 'package:flutter/material.dart';

Icon getIconForMimeType(String mimeType) {
  if (mimeType.startsWith('text/')) {
    return const Icon(Icons.text_snippet);
  } else if (mimeType.startsWith('image/')) {
    return const Icon(Icons.image);
  } else {
    return const Icon(Icons.file_present);
  }
}
