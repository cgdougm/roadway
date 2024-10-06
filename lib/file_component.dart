import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'file_ops.dart';
import 'db_helper.dart';

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
          final Icon icon = getIconForMimeType(metadata['mimetype']);

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
}

class FileCardList extends StatelessWidget {
  const FileCardList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: DatabaseHelper.instance.getAllItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No items'));
        } else {
          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              Map<String, Object?> item = items[index];
              if (item['type'] == 'file') {
                String filePath = item['value'] as String;
                return FileCard(
                  xfile: XFile(filePath),
                );
              }
            },
          );
        }
      },
    );
  }
}
