import 'package:sqflite/sqflite.dart';
import 'package:csv/csv.dart';
import 'dart:io';

Future<void> exportCsv(
    Database db,
    String tableName,
    String filePath, {
    List<int>? columnIndices,
  }) async {
  List<Map<String, dynamic>> tableData = await db.query(tableName);

  // If no columns are selected, export all columns  
  columnIndices = columnIndices ?? List.generate(tableData[0].keys.length, (index) => index);

  // Export selected columns
  List<List<dynamic>> csvData = [];
  csvData.add(columnIndices.map((index) => tableData[0].keys.toList()[index]).toList()); // Add headers for selected columns
  
  for (var row in tableData) {
    csvData.add(columnIndices.map((index) => row.values.toList()[index]).toList()); // Export selected columns
  }

  String csvString = const ListToCsvConverter().convert(csvData);

  File file = File(filePath);
  await file.writeAsString(csvString);
}
