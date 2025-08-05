import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScanHistoryItem extends StatefulWidget {
  final Map<String, dynamic> item;
  const ScanHistoryItem({required this.item});

  @override
  State<ScanHistoryItem> createState() => _ScanHistoryItemState();
}

class _ScanHistoryItemState extends State<ScanHistoryItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.item['product'] ?? {};
    final String name = product['name'] ?? 'Unknown Product';
    final String halalStatus = product['halal_status'] ?? 'unknown';
    final String imageUrl = product['image_url'] ?? '';
    final String timestamp = widget.item['scan_timestamp'] ?? '';
    final String ingredientsRaw = product['ingredients'] ?? '';

    // Format date
    String formattedDate = '';
    try {
      final date = DateTime.parse(timestamp);
      formattedDate = DateFormat('d MMM yyyy • HH:mm').format(date);
    } catch (_) {
      formattedDate = timestamp;
    }

    // Color for halal status
    Color statusColor;
    switch (halalStatus.toLowerCase()) {
      case 'halal':
        statusColor = Colors.green;
        break;
      case 'haram':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    // Parse ingredients into list
    final List<String> ingredients = ingredientsRaw
        .split(RegExp(r'[,;/]+'))
        .map((i) => i.trim())
        .where((i) => i.isNotEmpty)
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported, size: 50),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Scanned on: $formattedDate', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(halalStatus.toUpperCase()),
                    backgroundColor: statusColor.withOpacity(0.2),
                    labelStyle: TextStyle(color: statusColor),
                  ),
                ],
              ),
              if (_isExpanded && ingredients.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    ingredients.length,
                        (index) => SizedBox(
                      width: (MediaQuery.of(context).size.width - 64) / 2, // 2-column
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 14)),
                          Expanded(child: Text(ingredients[index], style: const TextStyle(fontSize: 14))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
