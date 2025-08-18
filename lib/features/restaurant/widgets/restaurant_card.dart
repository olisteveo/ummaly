import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ummaly/core/models/restaurant.dart'; // canonical import
import 'package:ummaly/theme/styles.dart';

// Helper: choose the "today" line from Google-style opening hours
String _todayHoursLine(List<String> lines) {
  if (lines.isEmpty) return '';
  const days = [
    'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
  ];
  final i = DateTime.now().weekday - 1; // Mon=1
  final today = days[i];
  return lines.firstWhere(
        (l) => l.startsWith(today),
    orElse: () => lines.first,
  );
}

ButtonStyle _pillBtn(BuildContext context) => OutlinedButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
  shape: const StadiumBorder(),
  side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.6)),
);

/// Rich card used elsewhere in the app.
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
    if (item.categories.isNotEmpty) {
      meta.add(item.categories.take(3).join(' • '));
    }
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
/// Collapsed by default; when expanded, shows a tidy actions row and today's hours.
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
    this.phone,
    this.website,
    this.openingNow,
    this.openingHours,
    required this.isExpanded,
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

  // Lazy-loaded details
  final String? phone;
  final String? website;
  final bool? openingNow;
  final List<String>? openingHours;

  final bool isExpanded;

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

                    // Expanded details
                    if (isExpanded) ...[
                      const SizedBox(height: AppSpacing.s),

                      // Compact status chip (Open/Closed)
                      if (openingNow != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Chip(
                            avatar: Icon(
                              openingNow! ? Icons.check_circle : Icons.cancel,
                              size: 16,
                              color: openingNow! ? Colors.green : Colors.redAccent,
                            ),
                            label: Text(openingNow! ? 'Open now' : 'Closed'),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
                          ),
                        ),

                      // Primary actions: Call / Website / Directions
                      Wrap(
                        spacing: AppSpacing.s,
                        runSpacing: AppSpacing.s,
                        children: [
                          if (phone != null && phone!.isNotEmpty)
                            OutlinedButton.icon(
                              style: _pillBtn(context),
                              onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                              icon: const Icon(Icons.call, size: 16),
                              label: Text(phone!, overflow: TextOverflow.ellipsis),
                            ),
                          if (website != null && website!.isNotEmpty)
                            OutlinedButton.icon(
                              style: _pillBtn(context),
                              onPressed: () => launchUrl(Uri.parse(website!), mode: LaunchMode.externalApplication),
                              icon: const Icon(Icons.language, size: 16),
                              label: const Text('Website'),
                            ),
                          if (onDirections != null)
                            OutlinedButton.icon(
                              style: _pillBtn(context),
                              onPressed: onDirections,
                              icon: const Icon(Icons.directions, size: 16),
                              label: const Text('Directions'),
                            ),
                        ],
                      ),

                      if (openingHours != null && openingHours!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _todayHoursLine(openingHours!),
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],

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
              // caret to hint expand/collapse
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.s, top: 2),
                child: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 20, color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
