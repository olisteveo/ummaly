import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScanHistoryItem extends StatelessWidget {
  final Map<String, dynamic> item;
  const ScanHistoryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final product = item['product'] ?? {};
    final String name = product['name'] ?? 'Unknown Product';
    final String halalStatus = product['halal_status'] ?? 'unknown';
    final String imageUrl = product['image_url'] ?? '';
    final String timestamp = item['scan_timestamp'] ?? '';

    // Format date nicely
    String formattedDate = '';
    try {
      final date = DateTime.parse(timestamp);
      formattedDate = DateFormat('d MMM yyyy • HH:mm').format(date);
    } catch (_) {
      formattedDate = timestamp;
    }

    // Color for halal status
    Color statusColor;
    if (halalStatus.toLowerCase() == 'halal') {
      statusColor = Colors.green;
    } else if (halalStatus.toLowerCase() == 'haram') {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: imageUrl.isNotEmpty
            ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
            : const Icon(Icons.image_not_supported),
        title: Text(name),
        subtitle: Text('Scanned on: $formattedDate'),
        trailing: Chip(
          label: Text(halalStatus.toUpperCase()),
          backgroundColor: statusColor.withOpacity(0.2),
          labelStyle: TextStyle(color: statusColor),
        ),
      ),
    );
  }
}
