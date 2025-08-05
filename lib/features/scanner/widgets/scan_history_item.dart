import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScanHistoryItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggle;

  const ScanHistoryItem({
    required this.item,
    required this.index,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final product = item['product'] ?? {};
    final String name = product['name'] ?? 'Unknown Product';
    final String halalStatus = product['halal_status'] ?? 'unknown';
    final String imageUrl = product['image_url'] ?? '';
    final String timestamp = item['latest_scan'] ?? item['scan_timestamp'] ?? '';
    final int scanCount = item['scan_count'] ?? 1;
    final String ingredientsRaw = product['ingredients'] ?? '';

    // Format date with local timezone correction
    String formattedDate = '';
    try {
      final date = DateTime.parse(timestamp).toLocal(); // local time fix here
      formattedDate = DateFormat('d MMM yyyy • HH:mm').format(date);
    } catch (_) {
      formattedDate = timestamp;
    }

    // Halal status colour
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

    // Ingredients to list
    final List<String> ingredients = ingredientsRaw
        .split(RegExp(r'[,;/]+'))
        .map((i) => i.trim())
        .where((i) => i.isNotEmpty)
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onToggle,
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
                        Text('Scanned $scanCount time${scanCount > 1 ? 's' : ''}', style: const TextStyle(fontSize: 12)),
                        Text('Latest: $formattedDate', style: const TextStyle(fontSize: 12)),
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
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                  child: child,
                ),
                child: isExpanded && ingredients.isNotEmpty
                    ? Padding(
                  key: const ValueKey('expanded'),
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          ingredients.length,
                              (index) => SizedBox(
                            width: (MediaQuery.of(context).size.width - 64) / 2,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontSize: 14)),
                                Expanded(
                                  child: Text(
                                    ingredients[index],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
