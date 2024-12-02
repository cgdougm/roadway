import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roadway/app_state.dart';
import 'package:roadway/component/entity.dart';

class DataCardsComponent extends StatelessWidget {
  const DataCardsComponent({super.key, required this.onDataCellTap});

  final Function(Map<String, dynamic>) onDataCellTap;

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
              return const Center(child: Text('Drop file'));
            } else {
              print('Num items: ${snapshot.data!.length}');
              // a scrollable list of Entity widgets
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return Entity(
                    item: snapshot.data![index],
                    onTap: () => onDataCellTap(snapshot.data![index]),
                  );
                },
              );
            }
          },
        );
      },
    );
  }
}
