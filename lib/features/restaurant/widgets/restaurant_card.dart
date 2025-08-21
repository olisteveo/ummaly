import 'package:flutter/material.dart';
import 'package:ummaly/theme/styles.dart';

/// Lightweight, tappable restaurant card with an optional [footer] area that
/// renders INSIDE the rounded container (useful for status chips / actions).
class RestaurantCardLite extends StatelessWidget {
  const RestaurantCardLite({
    super.key,
    required this.name,
    this.address,
    this.rating,
    this.ratingCount,
    this.categories = const [],
    this.provider,
    this.priceLevel,
    this.distance,
    this.phone,
    this.website,
    this.openingNow,
    this.openingHours,
    this.isExpanded = false,
    this.onTap,
    this.onDirections,
    this.onCall,
    this.onOpenWebsite,
    this.footer,
  });

  final String name;
  final String? address;

  final double? rating;
  final int? ratingCount;
  final List<String> categories;

  final String? provider; // e.g. GOOGLE, YELP
  final int? priceLevel;  // 0..4 -> "£", "££", etc.
  final String? distance; // e.g. "0.9 km away"

  final String? phone;
  final String? website;

  final bool? openingNow;
  final List<String>? openingHours;

  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onDirections;

  /// New: explicit callbacks so inner buttons don't trigger parent tap.
  final VoidCallback? onCall;
  final VoidCallback? onOpenWebsite;

  /// Extra content rendered at the bottom INSIDE the card (chips, actions, etc.)
  final Widget? footer;

  String _priceLabel(int? level) {
    if (level == null || level <= 0) return '';
    return '£' * level.clamp(1, 4);
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) ??
            Colors.black54;

    final price = _priceLabel(priceLevel);
    final showMetaRow =
        (provider != null && provider!.isNotEmpty) || price.isNotEmpty;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leading icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (address != null && address!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              address!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: muted,
                              ),
                            ),
                          ),
                        // Rating / categories / distance
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              if (rating != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, size: 14, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating!.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (ratingCount != null) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${ratingCount!})',
                                        style: TextStyle(fontSize: 12, color: muted),
                                      ),
                                    ],
                                  ],
                                ),
                              if (categories.isNotEmpty)
                                Text(
                                  categories.join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: muted),
                                ),
                              if (distance != null)
                                Text(
                                  distance!,
                                  style: TextStyle(fontSize: 12, color: muted),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand chevron
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.s, top: 4),
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 20,
                      color: muted,
                    ),
                  ),
                ],
              ),

              if (showMetaRow) const SizedBox(height: AppSpacing.m),

              // Provider / price chips
              if (showMetaRow)
                Wrap(
                  children: [
                    if (provider != null && provider!.isNotEmpty)
                      _chip(provider!.toUpperCase()),
                    if (price.isNotEmpty) _chip(price),
                  ],
                ),

              // Expanded section
              AnimatedCrossFade(
                crossFadeState:
                isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 160),
                firstChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Opening info
                    if (openingNow != null ||
                        (openingHours != null && openingHours!.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (openingNow != null)
                              Text(
                                openingNow! ? 'Open now' : 'Closed now',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: openingNow!
                                      ? const Color(0xFF0A7F3F)
                                      : muted,
                                ),
                              ),
                            if (openingHours != null && openingHours!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  openingHours!.join('\n'),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: muted),
                                ),
                              ),
                          ],
                        ),
                      ),

                    // Phone / website quick actions (buttons)
                    if ((phone != null && phone!.isNotEmpty) ||
                        (website != null && website!.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.m),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            if (phone != null && phone!.isNotEmpty)
                              TextButton.icon(
                                onPressed: onCall,
                                icon: const Icon(Icons.phone, size: 16),
                                label: Text(
                                  phone!,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (website != null && website!.isNotEmpty)
                              TextButton.icon(
                                onPressed: onOpenWebsite,
                                icon: const Icon(Icons.link, size: 16),
                                label: SizedBox(
                                  width: 200,
                                  child: Text(
                                    website!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                    // Directions button
                    if (onDirections != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.m),
                        child: OutlinedButton.icon(
                          onPressed: onDirections,
                          icon: const Icon(Icons.directions),
                          label: const Text('Directions'),
                        ),
                      ),

                    // Footer INSIDE the card (chips, actions, etc.)
                    if (footer != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.m),
                        child: footer!,
                      ),
                  ],
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
