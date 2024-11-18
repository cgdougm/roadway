import 'package:roadway/core/file.dart';

Future<String> dumpedDbItemsAsString(List<Map<String, Object?>> items) async {
  // final List<Map<String, Object?>> items =
  //     await context.read<AppState>().getAllItems();
  List<String> dumpLines = [];
  dumpLines.add('# Items');
  for (var item in items) {
    String filePath = item['value'] as String;
    if (FileInfo.isUri(filePath)) {
      dumpLines.add('### $filePath');
    } else {
      FileInfo fileInfo = await FileInfo.fromPath(filePath);
      // Convert FileInfo to a Map and filter out null values
      Map<String, dynamic> mappedFileInfo = fileInfo.toMap()
        ..removeWhere((key, value) =>
            value == null); // Not sure why this filder is needed
      dumpLines.add('### ${mappedFileInfo["fileName"]}');
      dumpLines.add('* ${mappedFileInfo["fileFolder"]}');
      dumpLines.add(
          '* ${mappedFileInfo["mimeType"]} / ${mappedFileInfo["fileLengthFormatted"]}');
      dumpLines.add(
          '* ${mappedFileInfo["lastModifiedFormatted"]} (${mappedFileInfo["lastModifiedAgo"]})');
    }
    dumpLines.add('\n'); // Separator between items
  }
  return dumpLines.join('\n');
}

