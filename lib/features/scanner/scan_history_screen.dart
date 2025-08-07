import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/scan_history_controller.dart';
import 'widgets/scan_history_item.dart';

class ScanHistoryScreen extends StatelessWidget {
  final String firebaseUid;
  ScanHistoryScreen({required this.firebaseUid});

  final ScanHistoryController controller = Get.put(ScanHistoryController());

  @override
  Widget build(BuildContext context) {
    controller.fetchHistory(firebaseUid); // Trigger initial load

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.history.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.history.isEmpty) {
          return const Center(child: Text('No scans yet.'));
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (!controller.isLoading.value &&
                controller.hasMore.value &&
                scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
              controller.fetchHistory(firebaseUid, loadMore: true);
            }
            return false;
          },
          child: ListView.builder(
            itemCount: controller.history.length,
            itemBuilder: (context, index) {
              final item = controller.history[index];

              return Obx(() {
                final barcode = item['product']?['barcode'] ?? '';
                final timestamp =
                    item['latest_scan'] ?? item['scan_timestamp'] ?? DateTime.now().toIso8601String();

                return Dismissible(
                  key: Key('${barcode}_$timestamp'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: const Text('Are you sure you want to delete this scan history entry?'),
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
                    // ✅ Delete from backend
                    await controller.deleteHistoryItem(item, firebaseUid);

                    // ✅ Then remove from UI
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
                    index: index,
                    isExpanded: controller.expandedIndex.value == index,
                    onToggle: () => controller.toggleExpanded(index),
                  ),
                );
              });
            },
          ),
        );
      }),
    );
  }
}
