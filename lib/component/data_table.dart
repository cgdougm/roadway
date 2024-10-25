import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../core/text.dart';

class DataTableComponent extends StatelessWidget {
  final Function(Map<String, dynamic>) onDataCellTap;

  const DataTableComponent({super.key, required this.onDataCellTap});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<AppState>().getAllItems(),
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
                            Icon(item['type'] == 'file'
                                ? Icons.insert_drive_file
                                : Icons.link),
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
  }
}
