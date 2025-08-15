import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ummaly/theme/styles.dart';
import 'package:ummaly/features/scanner/widgets/product_flag_dialog.dart';

class ScanHistoryItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggle;

  /// Called after user flags/unflags from the row dialog.
  /// Provides (flagged, flagsCountDelta).
  final void Function(bool flagged, int delta)? onFlagChanged;

  const ScanHistoryItem({
    super.key,
    required this.item,
    required this.index,
    required this.isExpanded,
    required this.onToggle,
    this.onFlagChanged,
  });

  @override
  Widget build(BuildContext context) {
    final product = (item['product'] ?? {}) as Map<String, dynamic>;
    final String name = (product['name'] ?? 'Unknown Product').toString();
    final String brand = (product['brand'] ?? '').toString();
    final String halalStatus =
    (product['halal_status'] ?? product['halalStatus'] ?? 'unknown')
        .toString()
        .toUpperCase();
    final String imageUrl =
    (product['image_url'] ?? product['imageUrl'] ?? '').toString();
    final String barcode =
    (product['barcode'] ?? item['barcode'] ?? '').toString();
    final int productId = _asInt(product['id']);
    final bool myFlagged =
    (item['myFlagged'] is bool) ? item['myFlagged'] as bool : false;

    final int flagsCount = _asInt(item['flagsCount'] ?? item['flags_count']);
    final String timestamp =
    (item['latest_scan'] ?? item['scan_timestamp'] ?? '').toString();
    final int scanCount = _asInt(item['scan_count'] ?? 1);
    final String ingredientsRaw = (product['ingredients'] ?? '').toString();

    // Date (separate, visible row)
    String formattedDate = '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      formattedDate = DateFormat('d MMM yyyy • HH:mm').format(date);
    } catch (_) {
      formattedDate = timestamp;
    }

    // Status color
    final Color statusColor = AppStyleHelpers.halalStatusColor(halalStatus);

    // Ingredients split (parentheses-aware + cleanup)
    final List<String> ingredients = _smartSplitIngredients(ingredientsRaw);

    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: onToggle, // tap anywhere toggles ingredients
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: image + title/brand
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Thumb(url: imageUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (brand.isNotEmpty)
                            Text(
                              brand,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.black54),
                            ),
                          const SizedBox(height: 6),

                          // ==== META BAR (chip left, actions right; no date here) ====
                          Row(
                            children: [
                              // Left: status chip
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Chip(
                                    label: Text(halalStatus),
                                    backgroundColor:
                                    statusColor.withOpacity(0.12),
                                    side: BorderSide(color: statusColor),
                                    labelStyle: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                    padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                  ),
                                ),
                              ),
                              // Right: flags badge + flag icon (fixed width)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (flagsCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: Colors.red),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.flag,
                                              size: 14, color: Colors.red),
                                          const SizedBox(width: 4),
                                          Text('$flagsCount',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                        ],
                                      ),
                                    ),
                                  IconButton(
                                    tooltip: myFlagged
                                        ? 'You flagged this'
                                        : 'Flag / unflag',
                                    icon: Icon(myFlagged
                                        ? Icons.flag
                                        : Icons.outlined_flag),
                                    color: myFlagged
                                        ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        : null,
                                    onPressed: () async {
                                      final res = await showModalBottomSheet<
                                          ProductFlagResult>(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (_) => ProductFlagDialog(
                                          productId: productId,
                                          barcode: barcode,
                                          initiallyFlagged: myFlagged,
                                        ),
                                      );
                                      if (res != null && onFlagChanged != null) {
                                        onFlagChanged!(
                                            res.flagged, res.flagsCountDelta ?? 0);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // ==== /META BAR ====
                        ],
                      ),
                    ),
                  ],
                ),

                // ===== Date row (prominent, its own line) =====
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        formattedDate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.black87),
                      ),
                    ),
                  ],
                ),

                // ===== Barcode + scan count row =====
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.qr_code_2,
                        size: 16, color: Colors.black45),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Barcode: $barcode',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Scanned $scanCount time${scanCount > 1 ? 's' : ''}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),

                // ===== Inline "Ingredients" toggle row =====
                const SizedBox(height: 4),
                InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.format_list_bulleted,
                            size: 18, color: Colors.black54),
                        const SizedBox(width: 8),
                        Text(
                          'Ingredients',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 22,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),

                // ===== Expandable ingredients (clean bullets) =====
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => SizeTransition(
                    sizeFactor:
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    child: child,
                  ),
                  child: isExpanded && ingredients.isNotEmpty
                      ? Padding(
                    key: const ValueKey('expanded'),
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            ingredients.length,
                                (i) => SizedBox(
                              width: (MediaQuery.of(context).size.width - 64) / 2,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ',
                                      style: TextStyle(fontSize: 14)),
                                  Expanded(
                                    child: Text(
                                      ingredients[i],
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
      ),
    );
  }

  // ---------- helpers ----------

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  /// Split by comma/semicolon **only when not inside parentheses**.
  /// Also merges standalone percentages (e.g. "8%") into the previous item,
  /// and filters out boilerplate like "see ingredients in bold".
  List<String> _smartSplitIngredients(String text) {
    if (text.trim().isEmpty) return const [];

    final List<String> tokens = [];
    final buf = StringBuffer();
    int depth = 0;

    void flush() {
      final t = buf.toString().trim();
      buf.clear();
      if (t.isEmpty) return;

      // Filter boilerplate / non-ingredients
      if (_looksLikeDisclaimer(t)) return;

      // If just a percentage, append to previous token
      final pct = RegExp(r'^\d+(\.\d+)?\s*%$');
      if (pct.hasMatch(t)) {
        if (tokens.isNotEmpty) {
          tokens[tokens.length - 1] = '${tokens.last} ($t)';
        }
        return;
      }

      tokens.add(t);
    }

    for (int i = 0; i < text.length; i++) {
      final ch = text[i];

      if (ch == '(') {
        depth++;
        buf.write(ch);
        continue;
      }
      if (ch == ')') {
        depth = depth > 0 ? depth - 1 : 0;
        buf.write(ch);
        continue;
      }

      if ((ch == ',' || ch == ';' || ch == '/') && depth == 0) {
        flush();
      } else {
        buf.write(ch);
      }
    }
    flush();

    // Final tidy: collapse spaces and remove duplicates
    final seen = <String>{};
    final cleaned = <String>[];
    for (final t in tokens) {
      final s = t.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (s.isEmpty) continue;
      if (seen.add(s.toLowerCase())) cleaned.add(s);
    }
    return cleaned;
  }

  bool _looksLikeDisclaimer(String s) {
    final x = s.toLowerCase().trim();
    if (x.isEmpty) return true;
    if (x.startsWith('see ingredient')) return true;
    if (x.startsWith('see ingredients')) return true;
    if (x.startsWith('for allergen')) return true;
    if (x.contains('for allergens')) return true;
    if (RegExp(r'^\d+\s*ml$').hasMatch(x)) return true; // e.g. "100ml"
    if (RegExp(r'^\d+\s*g$').hasMatch(x)) return true;  // e.g. "30g"
    return false;
  }
}

class _Thumb extends StatelessWidget {
  final String url;
  const _Thumb({required this.url});

  @override
  Widget build(BuildContext context) {
    final ph = Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.image, color: Colors.white70),
    );

    if (url.isEmpty) return ph;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ph,
      ),
    );
  }
}
