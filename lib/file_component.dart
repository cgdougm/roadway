import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'file_ops.dart';


class FileCard extends StatelessWidget {
  final XFile xfile;

  const FileCard({super.key, required this.xfile});

  @override
  Widget build(BuildContext context) {
    if (xfile.path.isEmpty) {
      return const Text('path empty');
    }
    return FutureBuilder<Map<String, dynamic>>(
      future: fileInfo(xFile: xfile),
      builder:
          (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final metadata = snapshot.data!;
          final Icon icon = _getIconForMimeType(metadata['mimetype']);

          final String subtitle =
              '${metadata['lastModifiedFormatted']} (${metadata['lastModifiedAgo']}) ${metadata['fileLengthFormatted']}';
          return ListTile(
            leading: icon,
            title: Text(xfile.name,
                style: const TextStyle(
                    fontFamily: 'HeptaSlab',
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.reorder),
          );
        } else {
          return const Text('No data');
        }
      },
    );
  }

  // You'll need to implement this method
  Icon _getIconForMimeType(String mimeType) {
    if (mimeType.startsWith('text/')) {
      return const Icon(Icons.text_snippet);
    } else if (mimeType.startsWith('image/')) {
      return const Icon(Icons.image);
    } else {
      return const Icon(Icons.file_present);
    }
  }
}
