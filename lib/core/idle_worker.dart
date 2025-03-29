import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'file_metadata_cache.dart';

class IdleWorker {
  static final IdleWorker instance = IdleWorker._();
  IdleWorker._();

  Timer? _idleTimer;
  final List<String> _pendingPaths = [];
  bool _isProcessing = false;
  static const Duration _idleTimeout = Duration(seconds: 5);
  static const Duration _processingInterval = Duration(milliseconds: 100);

  void scheduleMetadataUpdate(String filePath) {
    if (!_pendingPaths.contains(filePath)) {
      _pendingPaths.add(filePath);
      _scheduleIdleProcessing();
    }
  }

  void _scheduleIdleProcessing() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, _processPendingUpdates);
  }

  Future<void> _processPendingUpdates() async {
    if (_isProcessing || _pendingPaths.isEmpty) return;

    _isProcessing = true;
    while (_pendingPaths.isNotEmpty) {
      final filePath = _pendingPaths.removeAt(0);
      try {
        final metadata = await FileMetadataCache.instance.gatherMetadata(filePath);
        await FileMetadataCache.instance.setMetadata(metadata);
      } catch (e) {
        print('Error processing metadata for $filePath: $e');
      }
      await Future.delayed(_processingInterval);
    }
    _isProcessing = false;
  }

  void dispose() {
    _idleTimer?.cancel();
    _pendingPaths.clear();
  }
} 