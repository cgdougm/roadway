import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../core/time_utils.dart';
import 'package:path/path.dart' as path;

class CwdBar extends StatelessWidget {
  const CwdBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  appState.cwd.isEmpty ? 'No directory selected' : appState.cwd,
                  style: const TextStyle(fontFamily: 'Courier'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Tooltip(
                    message: 'Show hidden dot files',
                    child: Checkbox(
                      value: appState.showDotFiles,
                      onChanged: (value) {
                        appState.setShowDotFiles(value ?? false);
                      },
                    ),
                  ),
                  if (appState.directoryVisits.isNotEmpty)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.history),
                      tooltip: 'Directory History',
                      itemBuilder: (context) => appState.directoryVisits
                          .map((visit) => PopupMenuItem<String>(
                                value: visit.path,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      path.basename(visit.path),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      getTimeAgo(visit.visitTime),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onSelected: (path) {
                        appState.setCwd(path);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
} 