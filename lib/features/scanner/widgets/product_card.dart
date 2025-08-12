import 'package:flutter/material.dart';
import 'package:ummaly/theme/styles.dart';

/// Product card (V2, refined header)
/// - hero header (image + brand)
/// - status chip sits BELOW the title/brand, right-aligned (prevents title crowding)
/// - confidence progress bar
/// - flagged items as chips
/// - collapsible ingredients
/// - timeline-style steps
class ProductCard extends StatelessWidget {
  final Map<String, dynamic>? productData;
  final String? errorMessage;
  final VoidCallback onScanAgain;

  const ProductCard({
    Key? key,
    this.productData,
    this.errorMessage,
    required this.onScanAgain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (errorMessage == null && productData == null) return const SizedBox();
    final theme = Theme.of(context);
    final pd = productData;

    // Steps (timeline)
    final List<dynamic> steps = (pd?['analysis_steps'] as List?) ?? const [];

    // Flags — support {term,status,notes?} or {name,status,notes?}
    final List<dynamic> rawFlags = (pd?['halal_matches'] as List?) ?? const [];
    final flags = rawFlags
        .map((e) => e is Map ? e.cast<String, dynamic>() : <String, dynamic>{})
        .where((m) => (m['term'] ?? m['name'] ?? '').toString().trim().isNotEmpty)
        .toList();

    final status = (pd?['halal_status']?.toString() ?? 'UNKNOWN').toUpperCase();
    final statusColor = AppStyleHelpers.halalStatusColor(status);
    final confidence = (pd?['confidence'] is num) ? (pd!['confidence'] as num).toDouble() : null;
    final ingredientsText = pd?['ingredients']?.toString() ?? '';

    final name = pd?['name']?.toString() ?? 'Unnamed Product';
    final brand = pd?['brand']?.toString();

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppCards.modalShadows,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER (image + text column; chip is below title to avoid crowding)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroImage(url: pd?['image_url']?.toString()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title can wrap up to 2 lines with ellipsis
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          if (brand != null && brand!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                brand!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                              ),
                            ),
                          // Chip placed on its own line, right-aligned within the text column
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _StatusChip(text: status, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // CONFIDENCE BAR
                if (confidence != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: confidence.clamp(0, 1),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(confidence * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],

                // NOTES
                if (pd?['notes'] != null && pd!['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    pd['notes'].toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // FLAGS AS CHIPS
                if (flags.isNotEmpty) ...[
                  Text('Flagged ingredients & terms', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: flags.map((m) {
                      final term = (m['term'] ?? m['name']).toString();
                      final st = (m['status'] ?? 'conditional').toString();
                      final notes = (m['notes'] ?? '').toString();
                      final c = AppStyleHelpers.halalStatusColor(st);
                      final label = notes.isNotEmpty ? '$term — $notes' : term;
                      return Chip(
                        label: Text('${label} (${st.toUpperCase()})'),
                        avatar: Icon(Icons.flag, size: 16, color: c),
                        backgroundColor: c.withOpacity(0.08),
                        shape: StadiumBorder(side: BorderSide(color: c)),
                        labelStyle: theme.textTheme.bodySmall,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      );
                    }).toList(),
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'No flagged items found',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // COLLAPSIBLE INGREDIENTS
                if (ingredientsText.isNotEmpty)
                  _IngredientsTile(text: ingredientsText),

                const SizedBox(height: 8),

                // TIMELINE STEPS
                if (steps.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Checks', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  ...List.generate(steps.length, (i) {
                    final step = (steps[i] as Map).cast<String, dynamic>();
                    final label = step['label']?.toString() ?? '';
                    final s = step['status']?.toString() ?? 'done';
                    final detail = step['detail']?.toString();

                    final (icon, color) = AppStyleHelpers.stepVisual(s);
                    final isLast = i == steps.length - 1;

                    return _TimelineRow(
                      icon: icon,
                      color: color,
                      title: label,
                      subtitle: (detail != null && detail.isNotEmpty) ? detail : null,
                      showConnector: !isLast,
                    );
                  }),
                ],

                const SizedBox(height: 16),

                // SCAN AGAIN
                ElevatedButton(
                  style: AppButtons.secondaryButton,
                  onPressed: onScanAgain,
                  child: const Text('Scan Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String? url;
  const _HeroImage({this.url});

  @override
  Widget build(BuildContext context) {
    final ph = Container(
      height: 84,
      width: 84,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image_not_supported, size: 36, color: Colors.grey),
    );

    if (url == null || url!.isEmpty) return ph;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url!,
        height: 84,
        width: 84,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ph,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _IngredientsTile extends StatelessWidget {
  final String text;
  const _IngredientsTile({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: false,
        maintainState: true,
        title: Text('Ingredients', style: theme.textTheme.titleMedium),
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool showConnector;

  const _TimelineRow({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.showConnector,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // timeline gutter
        Column(
          children: [
            Icon(icon, size: 18, color: color),
            if (showConnector)
              Container(
                width: 2,
                height: 18,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: color.withOpacity(0.35),
              ),
          ],
        ),
        const SizedBox(width: 8),
        // content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyMedium),
                if (subtitle != null)
                  Text(subtitle!, style: AppTextStyles.caption),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
