import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:provider/provider.dart';
import 'package:roadway/app_state.dart';
import 'package:roadway/core/text.dart';
import 'package:roadway/core/mime.dart';
import 'package:mime/mime.dart';

class DataTableComponent extends StatelessWidget {
  final Function(Map<String, dynamic>) onDataCellTap;

  const DataTableComponent({super.key, required this.onDataCellTap});

  Icon _getItemIcon(Object item) {
    if (item is Map<String, dynamic>) {
      if (item['type'] == 'folder') {
        return const Icon(Icons.folder);
      } else if (item['type'] == 'file') {
        return getIconForMimeType(
            lookupMimeType(item['value']) ?? 'text/unknown');
      } else {
        return const Icon(Icons.link);
      }
    }
    return const Icon(Icons.device_unknown);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: appState.getAllItems(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No data available'));
            } else {
              return Container(
                padding: const EdgeInsets.all(10),
                child: DataTable2(
                  columns: const [
                    DataColumn2(label: Text('Value'), size: ColumnSize.L),
                    DataColumn2(label: Text('ID'), size: ColumnSize.S),
                  ],
                  rows: snapshot.data!
                      .map((item) => DataRow(cells: [
                            DataCell(
                              Row(children: [
                                _getItemIcon(item),
                                const SizedBox(width: 10),
                                Text(item['value']),
                              ]),
                              onTap: () => onDataCellTap(item),
                            ),
                            DataCell(Text(
                                truncateStringWithEllipsis(item['id'] ?? ''))),
                          ]))
                      .toList(),
                  columnSpacing: 12,
                  horizontalMargin: 12,
                ),
              );
            }
          },
        );
      },
    );
  }
}
