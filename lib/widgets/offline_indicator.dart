import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tong/services/connectivity_service.dart';
import 'package:tong/services/sync_service.dart';
import 'package:tong/utils/theme.dart';

class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({super.key});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  final SyncService _syncService = SyncService();
  Map<String, dynamic> _syncStatus = {};

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    final status = await _syncService.getSyncStatus();
    if (mounted) {
      setState(() {
        _syncStatus = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivityService = Provider.of<ConnectivityService>(context);
    final isOnline = connectivityService.isConnected;
    final unsyncedItems = _syncStatus['unsyncedItems'] ?? 0;
    final queuedOperations = _syncStatus['queuedOperations'] ?? 0;

    // Only show when offline or when there are pending syncs
    if (isOnline && unsyncedItems == 0 && queuedOperations == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(isOnline, unsyncedItems, queuedOperations),
        border: Border(
          bottom: BorderSide(
            color: _getBorderColor(isOnline, unsyncedItems, queuedOperations),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getIcon(isOnline, unsyncedItems, queuedOperations),
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getMessage(isOnline, unsyncedItems, queuedOperations),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!isOnline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'OFFLINE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(
      bool isOnline, int unsyncedItems, int queuedOperations) {
    if (!isOnline) {
      return AppTheme.warningColor;
    }

    if (unsyncedItems > 0 || queuedOperations > 0) {
      return AppTheme.secondaryColor;
    }

    return AppTheme.infoColor;
  }

  Color _getBorderColor(
      bool isOnline, int unsyncedItems, int queuedOperations) {
    if (!isOnline) {
      return AppTheme.warningColor.withOpacity(0.3);
    }

    if (unsyncedItems > 0 || queuedOperations > 0) {
      return AppTheme.secondaryColor.withOpacity(0.3);
    }

    return AppTheme.infoColor.withOpacity(0.3);
  }

  IconData _getIcon(bool isOnline, int unsyncedItems, int queuedOperations) {
    if (!isOnline) {
      return Icons.wifi_off;
    }

    if (unsyncedItems > 0 || queuedOperations > 0) {
      return Icons.cloud_upload;
    }

    return Icons.cloud_sync;
  }

  String _getMessage(bool isOnline, int unsyncedItems, int queuedOperations) {
    if (!isOnline) {
      return 'You\'re offline. Changes will be synced when connection is restored.';
    }

    if (unsyncedItems > 0 || queuedOperations > 0) {
      final total = unsyncedItems + queuedOperations;
      return 'Syncing $total items...';
    }

    return 'All data is synced';
  }
}
