import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roadway/app_state.dart';
import 'package:roadway/component/entity.dart';

class DataCardsComponent extends StatelessWidget {
  const DataCardsComponent(
      {super.key,
      required this.onDataCellTap,
      required this.contentWidth,
      required this.contentHeight,
      required this.widthUnits,
      required this.heightUnits});

  final Function(Map<String, dynamic>) onDataCellTap;
  final double contentWidth;
  final double contentHeight;
  final int widthUnits;
  final int heightUnits;

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
              // a scrollable list of Entity widgets
              return SizedBox(
                width: contentWidth,
                height: contentHeight,
                child: ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Entity(
                        widthUnits: widthUnits,
                        heightUnits: heightUnits,
                        item: snapshot.data![index],
                        onTap: () => onDataCellTap(snapshot.data![index]),
                      ),
                    );
                  },
                ),
              );
            }
          },
        );
      },
    );
  }
}
