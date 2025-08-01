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
              return ScanHistoryItem(item: item);
            },
          ),
        );
      }),
    );
  }
}
