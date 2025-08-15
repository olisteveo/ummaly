import 'package:flutter/material.dart';
import 'package:ummaly/core/models/restaurant.dart'; // ✅ canonical import

class RestaurantCard extends StatelessWidget {
  const RestaurantCard({super.key, required this.item});
  final Restaurant item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = <String>[];
    if (item.rating != null) {
      final cnt = item.ratingCount != null ? ' (${item.ratingCount})' : '';
      meta.add('${item.rating!.toStringAsFixed(1)}★$cnt');
    }
    if (item.categories.isNotEmpty) meta.add(item.categories.take(3).join(' • '));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: theme.textTheme.titleMedium),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(meta.join(' • '), style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.address.isNotEmpty ? item.address : 'Address unavailable',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: -8,
              children: [
                Chip(
                  label: Text(item.provider.toUpperCase()),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
                ),
                if (item.priceLevel != null)
                  Chip(
                    label: Text('\$' * item.priceLevel!.clamp(1, 4)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
