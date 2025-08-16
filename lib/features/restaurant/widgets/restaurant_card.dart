import 'package:flutter/material.dart';
import 'package:ummaly/core/models/restaurant.dart'; // canonical import
import 'package:ummaly/theme/styles.dart';

/// Rich card used elsewhere in the app.
/// Supports optional distance + actions and uses app tokens.
class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.item,
    this.distance,
    this.onTap,
    this.onDirections,
  });

  final Restaurant item;
  final String? distance;
  final VoidCallback? onTap;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[];
    if (item.rating != null) {
      final cnt = item.ratingCount != null ? ' (${item.ratingCount})' : '';
      meta.add('${item.rating!.toStringAsFixed(1)}★$cnt');
    }
    if (item.categories.isNotEmpty) meta.add(item.categories.take(3).join(' • '));
    if (distance != null && distance!.isNotEmpty) meta.add(distance!);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.l),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  if (onDirections != null)
                    IconButton(onPressed: onDirections, icon: const Icon(Icons.directions), tooltip: 'Open in Maps'),
                ],
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(meta.join(' • '), style: AppTextStyles.caption),
              ],
              const SizedBox(height: AppSpacing.m),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      item.address.isNotEmpty ? item.address : 'Address unavailable',
                      style: AppTextStyles.body,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              Wrap(
                spacing: AppSpacing.s,
                runSpacing: -AppSpacing.s,
                children: [
                  Chip(
                    label: Text(item.provider.toUpperCase()),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
                  ),
                  if (item.priceLevel != null)
                    Chip(
                      label: Text('£' * item.priceLevel!.clamp(1, 4)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lightweight card for raw search results (no dependency on Restaurant ctor).
/// Used by the Search screen’s sheet.
class RestaurantCardLite extends StatelessWidget {
  const RestaurantCardLite({
    super.key,
    required this.name,
    required this.address,
    required this.provider,
    required this.categories,
    this.rating,
    this.ratingCount,
    this.priceLevel,
    this.distance,
    this.onTap,
    this.onDirections,
  });

  final String name;
  final String address;
  final String provider;
  final List<String> categories;
  final double? rating;
  final int? ratingCount;
  final int? priceLevel;
  final String? distance;
  final VoidCallback? onTap;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[];
    if (rating != null) {
      final cnt = ratingCount != null ? ' ($ratingCount)' : '';
      meta.add('${rating!.toStringAsFixed(1)}★$cnt');
    }
    if (categories.isNotEmpty) meta.add(categories.take(3).join(' • '));
    if (distance != null && distance!.isNotEmpty) meta.add(distance!);

    return Card(
      color: AppColors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.l),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.restaurants),
                alignment: Alignment.center,
                child: const Icon(Icons.restaurant, color: AppColors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(meta.join(' • '), style: AppTextStyles.caption),
                    ],
                    const SizedBox(height: AppSpacing.s),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          child: Text(address.isNotEmpty ? address : 'Address unavailable', style: AppTextStyles.body),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: -AppSpacing.s,
                      children: [
                        Chip(
                          label: Text(provider.toUpperCase()),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
                        ),
                        if (priceLevel != null)
                          Chip(
                            label: Text('£' * priceLevel!.clamp(1, 4)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDirections != null)
                IconButton(
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions),
                  tooltip: 'Open in Maps',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
