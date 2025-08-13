import 'package:flutter/material.dart';
import 'package:ummaly/theme/styles.dart';
import 'package:ummaly/core/services/product_flag_service.dart';
import 'package:ummaly/features/scanner/widgets/product_flag_dialog.dart';

/// Product card (V2, refined header + interactions)
/// - hero header (image + brand)
/// - status chip below title/brand, right-aligned
/// - AI confidence rating label + progress bar
/// - flagged items as chips
/// - collapsible ingredients
/// - timeline-style steps
/// - tap name to view full title; tap image to view fullscreen zoomable image
/// - flag icon to create/retract a user flag, with count
class ProductCard extends StatefulWidget {
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
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool? _myFlagged; // null until loaded
  int? _flagsCount; // null until loaded
  bool _loadingFlagMeta = false;

  int? get _productId {
    final pd = widget.productData;
    if (pd == null) return null;
    final v = pd['id'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  String? get _barcode {
    final pd = widget.productData;
    if (pd == null) return null;
    final v = pd['barcode'];
    if (v == null) return null;
    return v.toString();
  }

  @override
  void initState() {
    super.initState();
    // Prefer values provided by the API payload to avoid extra calls
    _myFlagged = widget.productData?['myFlagged'] as bool?;
    final fc = widget.productData?['flagsCount'];
    _flagsCount = fc is int ? fc : (fc is String ? int.tryParse(fc) : null);

    // If not present, try to fetch metadata in the background
    if ((_myFlagged == null || _flagsCount == null) && _productId != null) {
      _fetchFlagMeta(_productId!);
    }
  }

  Future<void> _fetchFlagMeta(int productId) async {
    setState(() => _loadingFlagMeta = true);
    try {
      final svc = ProductFlagService();
      final me = await svc.getMyFlag(productId: productId);
      final summary = await svc.getSummary(productId: productId);
      setState(() {
        _myFlagged = (me?['flagged'] as bool?) ?? false;
        _flagsCount = (summary['count'] as int?) ?? 0;
      });
    } catch (_) {
      // Non-fatal: leave values as-is
    } finally {
      if (mounted) setState(() => _loadingFlagMeta = false);
    }
  }

  Future<void> _onFlagPressed() async {
    // Allow dialog if we have either a numeric product id OR a barcode
    final pid = _productId;
    final code = _barcode;
    if (pid == null && (code == null || code.isEmpty)) return;

    final result = await showModalBottomSheet<ProductFlagResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductFlagDialog(
        productId: pid,           // nullable; dialog will prefer barcode for creation
        barcode: code,
        initiallyFlagged: _myFlagged ?? false,
      ),
    );
    if (result != null) {
      setState(() {
        _myFlagged = result.flagged;
        if (result.flagsCountDelta != null) {
          final current = _flagsCount ?? 0;
          final next = current + result.flagsCountDelta!;
          _flagsCount = next < 0 ? 0 : next;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = widget.errorMessage;
    final productData = widget.productData;

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
    final confidence =
    (pd?['confidence'] is num) ? (pd!['confidence'] as num).toDouble() : null;
    final ingredientsText = pd?['ingredients']?.toString() ?? '';

    final name = pd?['name']?.toString() ?? 'Unnamed Product';
    final brand = pd?['brand']?.toString();
    final imageUrl = pd?['image_url']?.toString();

    // Determine if we can open the flag dialog from this UI state
    final bool _canOpenFlag =
        _productId != null || ((_barcode ?? '').isNotEmpty);

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
                // HEADER (image + text column; chip and flag area are below title)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroImage(
                      url: imageUrl,
                      onTap: () => _showImageDialog(context, imageUrl),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title can wrap up to 2 lines with ellipsis — tap to view full
                          InkWell(
                            onTap: () => _showNameDialog(context, name, brand),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ),
                          if (brand != null && brand.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                brand,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: Colors.black54),
                              ),
                            ),
                          // Status + Flag bar
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _StatusChip(
                                      text: status,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                                // Flag action and count
                                if (_loadingFlagMeta)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: _canOpenFlag ? _onFlagPressed : null,
                                        tooltip: (_myFlagged ?? false)
                                            ? 'You flagged this'
                                            : 'Flag this product',
                                        icon: Icon(
                                          (_myFlagged ?? false)
                                              ? Icons.flag
                                              : Icons.outlined_flag,
                                        ),
                                        color: (_myFlagged ?? false)
                                            ? theme.colorScheme.primary
                                            : null,
                                      ),
                                      if (_flagsCount != null)
                                        Padding(
                                          padding:
                                          const EdgeInsets.only(right: 4.0),
                                          child: Text(
                                            _flagsCount.toString(),
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // AI CONFIDENCE LABEL + BAR
                if (confidence != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('AI confidence rating',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          )),
                      const Spacer(),
                      Text(
                        '${(confidence * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: confidence.clamp(0, 1),
                      minHeight: 8,
                    ),
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

                // FLAGS AS CHIPS (ingredient-level flags from the AI scan)
                if (flags.isNotEmpty) ...[
                  Text('Flagged ingredients & terms',
                      style: theme.textTheme.titleMedium),
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
                        label: Text('$label (${st.toUpperCase()})'),
                        avatar: Icon(Icons.flag, size: 16, color: c),
                        backgroundColor: c.withOpacity(0.08),
                        shape: StadiumBorder(side: BorderSide(color: c)),
                        labelStyle: theme.textTheme.bodySmall,
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      );
                    }).toList(),
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'No flagged items found',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.green),
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
                      subtitle:
                      (detail != null && detail.isNotEmpty) ? detail : null,
                      showConnector: !isLast,
                    );
                  }),
                ],

                const SizedBox(height: 16),

                // SCAN AGAIN
                ElevatedButton(
                  style: AppButtons.secondaryButton,
                  onPressed: widget.onScanAgain,
                  child: const Text('Scan Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==== Dialog helpers ====

  void _showNameDialog(BuildContext context, String name, String? brand) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Product name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(ctx).textTheme.titleMedium),
            if (brand != null && brand.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Brand: $brand', style: AppTextStyles.body),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String? url) {
    if (url == null || url.isEmpty) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Image',
      barrierColor: Colors.black.withOpacity(0.85),
      pageBuilder: (_, __, ___) {
        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Colors.black.withOpacity(0.95),
              child: SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(url, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 160),
      transitionBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String? url;
  final VoidCallback? onTap;
  const _HeroImage({this.url, this.onTap});

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

    final child = (url == null || url!.isEmpty)
        ? ph
        : ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url!,
        height: 84,
        width: 84,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ph,
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: child,
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
