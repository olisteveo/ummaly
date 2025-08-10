import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemUiOverlayStyle
import 'package:get/get.dart';

import '../../core/controllers/scan_history_controller.dart';
import 'widgets/scan_history_item.dart';
import 'package:ummaly/theme/styles.dart';

class ScanHistoryScreen extends StatefulWidget {
  final String firebaseUid;
  const ScanHistoryScreen({Key? key, required this.firebaseUid}) : super(key: key);

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  final ScanHistoryController controller = Get.put(ScanHistoryController());
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  bool _deletingAll = false;

  @override
  void initState() {
    super.initState();

    // Fetch once after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchHistory(widget.firebaseUid);
    });

    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showScrollToTop) {
        setState(() => _showScrollToTop = show);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await controller.refreshHistory(widget.firebaseUid);
  }

  Future<void> _confirmDeleteAll() async {
    if (controller.history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No history to delete')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all history?'),
        content: const Text('This will permanently delete all scan history on your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deletingAll = true);
    final deletedCount = await controller.deleteAllHistory(widget.firebaseUid);
    if (!mounted) return;
    setState(() => _deletingAll = false);

    if (deletedCount != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted $deletedCount item${deletedCount == 1 ? '' : 's'}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete all history')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent, // gradient behind
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text('Scan History'),

        // Gradient to match Home/Scanner
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.homeBackground,
          ),
        ),

        // Small count under title
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Obx(() {
            final count = controller.history.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '$count scan${count == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _deletingAll
                ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
                : IconButton(
              tooltip: 'Delete all history',
              onPressed: _confirmDeleteAll,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ),
        ],
      ),

      body: Obx(() {
        if (controller.isLoading.value && controller.history.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.history.isEmpty) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No scans yet. Pull to refresh.')),
                SizedBox(height: 120),
              ],
            ),
          );
        }

        // Build grouped list: Today / Yesterday / Last 7 Days / Older
        final entries = _buildGroupedEntries(controller.history);

        final showFooterLoader = controller.hasMore.value;
        final itemCount = entries.length + (showFooterLoader ? 1 : 0);

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (!controller.isLoading.value &&
                  controller.hasMore.value &&
                  scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent) {
                controller.fetchHistory(widget.firebaseUid, loadMore: true);
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                // Footer loader row (pagination)
                if (index >= entries.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final entry = entries[index];

                if (entry.type == _RowType.header) {
                  return _SectionHeader(label: entry.header!);
                }

                final item = entry.item!;

                return Obx(() {
                  final barcode = item['product']?['barcode'] ?? '';
                  final timestamp = item['latest_scan'] ??
                      item['scan_timestamp'] ??
                      DateTime.now().toIso8601String();

                  return Dismissible(
                    key: Key('${barcode}_$timestamp'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: const Text(
                                'Are you sure you want to delete this scan history entry?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) async {
                      // Backend delete, then UI update
                      await controller.deleteHistoryItem(item, widget.firebaseUid);
                      controller.history.remove(item);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Scan history entry deleted')),
                      );
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: ScanHistoryItem(
                      item: item,
                      index: entries[index].originalIndex ?? index,
                      isExpanded: controller.expandedIndex.value ==
                          (entries[index].originalIndex ?? index),
                      onToggle: () => controller.toggleExpanded(
                        entries[index].originalIndex ?? index,
                      ),
                    ),
                  );
                });
              },
            ),
          ),
        );
      }),

      // Scroll-to-top FAB
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
        backgroundColor: AppColors.scanner,
        onPressed: () => _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        ),
        child: const Icon(Icons.arrow_upward, color: Colors.white),
      )
          : null,
    );
  }
}

/// Section header chip
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor: AppColors.scanner.withOpacity(0.1),
          side: BorderSide.none,
        ),
      ),
    );
  }
}

/// Entry used by the grouped list (either a header or an item)
class _ListEntry {
  final _RowType type;
  final String? header;
  final Map<String, dynamic>? item;
  final int? originalIndex; // useful for toggle/expanded index

  _ListEntry.header(this.header)
      : type = _RowType.header,
        item = null,
        originalIndex = null;

  _ListEntry.item(this.item, this.originalIndex)
      : type = _RowType.item,
        header = null;
}

enum _RowType { header, item }

/// Build grouped entries without touching the controller
List<_ListEntry> _buildGroupedEntries(List history) {
  // Defensive copy
  final items = history.cast<Map<String, dynamic>>().toList();

  DateTime? _parseTs(Map<String, dynamic> it) {
    final raw = it['latest_scan'] ?? it['scan_timestamp'];
    if (raw == null) return null;
    try {
      if (raw is DateTime) return raw.toLocal();
      return DateTime.parse(raw.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  // Buckets
  final buckets = <String, List<Map<String, dynamic>>>{
    'Today': [],
    'Yesterday': [],
    'Last 7 Days': [],
    'Older': [],
  };

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final yesterdayStart = todayStart.subtract(const Duration(days: 1));
  final sevenDaysStart = todayStart.subtract(const Duration(days: 7));

  for (var i = 0; i < items.length; i++) {
    final it = items[i];
    final ts = _parseTs(it);
    if (ts == null) {
      buckets['Older']!.add(it);
      continue;
    }

    if (ts.isAfter(todayStart)) {
      buckets['Today']!.add(it);
    } else if (ts.isAfter(yesterdayStart)) {
      buckets['Yesterday']!.add(it);
    } else if (ts.isAfter(sevenDaysStart)) {
      buckets['Last 7 Days']!.add(it);
    } else {
      buckets['Older']!.add(it);
    }
  }

  // Sort each bucket by newest first
  int _cmp(Map<String, dynamic> a, Map<String, dynamic> b) {
    final ta = _parseTs(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final tb = _parseTs(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return tb.compareTo(ta);
  }
  for (final k in buckets.keys) {
    buckets[k]!.sort(_cmp);
  }

  // Build final list with headers
  final order = ['Today', 'Yesterday', 'Last 7 Days', 'Older'];
  final result = <_ListEntry>[];

  for (final label in order) {
    final list = buckets[label]!;
    if (list.isEmpty) continue;
    result.add(_ListEntry.header(label));
    for (final it in list) {
      final originalIndex = items.indexOf(it);
      result.add(_ListEntry.item(it, originalIndex));
    }
  }

  return result;
}
