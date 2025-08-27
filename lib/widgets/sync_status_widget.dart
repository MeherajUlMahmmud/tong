import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tong/services/connectivity_service.dart';
import 'package:tong/services/sync_service.dart';
import 'package:tong/utils/theme.dart';

class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  final SyncService _syncService = SyncService();
  Map<String, dynamic> _syncStatus = {};
  bool _isLoading = false;

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

  Future<void> _manualSync() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _syncService.syncNow();
      await _loadSyncStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synchronized successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivityService = Provider.of<ConnectivityService>(context);
    final isOnline = connectivityService.isConnected;
    final isSyncing = _syncStatus['isSyncing'] ?? false;
    final unsyncedItems = _syncStatus['unsyncedItems'] ?? 0;
    final queuedOperations = _syncStatus['queuedOperations'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(isOnline, isSyncing, unsyncedItems),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getBorderColor(isOnline, isSyncing, unsyncedItems),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildStatusIcon(isOnline, isSyncing),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusText(isOnline, isSyncing, unsyncedItems),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (unsyncedItems > 0 || queuedOperations > 0)
                  Text(
                    '$unsyncedItems items pending sync',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
          if (isOnline && (unsyncedItems > 0 || queuedOperations > 0))
            IconButton(
              onPressed: _isLoading ? null : _manualSync,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.sync,
                      color: Colors.white,
                      size: 16,
                    ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(bool isOnline, bool isSyncing) {
    if (isSyncing) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (isOnline) {
      return const Icon(
        Icons.cloud_done,
        color: Colors.white,
        size: 16,
      );
    } else {
      return const Icon(
        Icons.cloud_off,
        color: Colors.white,
        size: 16,
      );
    }
  }

  Color _getStatusColor(bool isOnline, bool isSyncing, int unsyncedItems) {
    if (isSyncing) {
      return AppTheme.infoColor;
    }

    if (!isOnline) {
      return AppTheme.warningColor;
    }

    if (unsyncedItems > 0) {
      return AppTheme.secondaryColor;
    }

    return AppTheme.successColor;
  }

  Color _getBorderColor(bool isOnline, bool isSyncing, int unsyncedItems) {
    if (isSyncing) {
      return AppTheme.infoColor.withOpacity(0.3);
    }

    if (!isOnline) {
      return AppTheme.warningColor.withOpacity(0.3);
    }

    if (unsyncedItems > 0) {
      return AppTheme.secondaryColor.withOpacity(0.3);
    }

    return AppTheme.successColor.withOpacity(0.3);
  }

  String _getStatusText(bool isOnline, bool isSyncing, int unsyncedItems) {
    if (isSyncing) {
      return 'Syncing...';
    }

    if (!isOnline) {
      return 'Offline Mode';
    }

    if (unsyncedItems > 0) {
      return 'Sync Pending';
    }

    return 'Synced';
  }
}
