import 'package:flutter/material.dart';
import 'package:roadway/core/file.dart';
import 'package:provider/provider.dart';
import 'package:roadway/app_state.dart';
import 'package:roadway/core/mime.dart';

class FileCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const FileCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: FutureBuilder<FileInfo>(
        future: FileInfo.fromPath(item['value']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Loading...'),
            );
          } else if (snapshot.hasError) {
            return ListTile(
              leading: const Icon(Icons.error),
              title: Text('Error: ${snapshot.error}'),
            );
          } else {
            final fileInfo = snapshot.data!;
            return ListTile(
              leading: getIconForMimeType(fileInfo.mimeType),
              title: Text(fileInfo.fileName),
              subtitle: Text('${fileInfo.fileLengthFormatted}  ${fileInfo.lastModified}'),
            );
          }
        },
      ),
    );
  }

  // IconData _getIconForFileType(String mimeType) {
  //   // Implement logic to return appropriate icon based on mime type
  //   if (mimeType.startsWith('image/')) {
  //     return Icons.image;
  //   } else if (mimeType.startsWith('text/')) {
  //     return Icons.description;
  //   } else {
  //     return Icons.insert_drive_file;
  //   }
  // }
}

class FileCardList extends StatelessWidget {
  const FileCardList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: context.read<AppState>().getAllItems(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No files found'));
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final item = snapshot.data![index];
                  return item['type'] == 'file' ? FileCard(item: item) : null;
                },
              );
            }
          },
        );
      },
    );
  }
}
