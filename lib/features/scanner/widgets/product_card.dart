import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ummaly/theme/styles.dart';
import 'package:ummaly/core/models/product.dart';
import 'package:ummaly/core/services/product_flag_service.dart';
import 'package:ummaly/core/services/favorites_service.dart';
import 'package:ummaly/features/auth/register_screen.dart';
import 'package:ummaly/features/subscription/paywall_screen.dart';
import 'package:ummaly/features/scanner/widgets/product_flag_dialog.dart';

/// Product card (V3, typed Product model)
/// - hero header (image + brand)
/// - status chip below title/brand, right-aligned
/// - AI confidence rating label + progress bar
/// - flagged items as chips
/// - collapsible ingredients
/// - timeline-style steps
/// - tap name to view full title; tap image to view fullscreen zoomable image
/// - flag icon to create/retract a user flag, with count
class ProductCard extends StatefulWidget {
  final Product? product;
  final String? errorMessage;
  final VoidCallback onScanAgain;
  final VoidCallback? onRetry;

  /// When true, the error is a scan-quota limit and should show upgrade CTA.
  final bool isQuotaBlock;

  const ProductCard({
    Key? key,
    this.product,
    this.errorMessage,
    required this.onScanAgain,
    this.onRetry,
    this.isQuotaBlock = false,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool? _myFlagged;
  int? _flagsCount;
  bool _loadingFlagMeta = false;
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _myFlagged = p.myFlagged;
      _flagsCount = p.flagsCount;
      _isFavorited = FavoritesService.instance.isFavorited(p.barcode);

      // If not provided by API, fetch in background
      if ((_myFlagged == null || _flagsCount == null) && p.id != null) {
        _fetchFlagMeta(p.id!);
      }
    }
  }

  Future<void> _fetchFlagMeta(int productId) async {
    if (!mounted) return;
    setState(() => _loadingFlagMeta = true);
    try {
      final svc = ProductFlagService();
      final me = await svc.getMyFlag(productId: productId);
      final summary = await svc.getSummary(productId: productId);
      if (!mounted) return;
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
    final p = widget.product;
    if (p == null) return;
    if (p.id == null && p.barcode.isEmpty) return;

    final result = await showModalBottomSheet<ProductFlagResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductFlagDialog(
        productId: p.id,
        barcode: p.barcode.isNotEmpty ? p.barcode : null,
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
    final p = widget.product;

    if (errorMessage == null && p == null) return const SizedBox();
    final theme = Theme.of(context);

    // If error only (no product), show error card
    if (p == null) {
      return _buildErrorCard(theme, errorMessage!);
    }

    final statusColor = AppStyleHelpers.halalStatusColor(p.halalStatus);
    final bool canOpenFlag = p.id != null || p.barcode.isNotEmpty;

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
                // HEADER (image + text column)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroImage(
                      url: p.imageUrl,
                      onTap: () => _showImageDialog(context, p.imageUrl),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => _showNameDialog(context, p.name, p.brand),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                p.name,
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
                          if (p.brand != null && p.brand!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                p.brand!,
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
                                      text: p.halalStatus,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
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
                                        onPressed: canOpenFlag ? _onFlagPressed : null,
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
                                          padding: const EdgeInsets.only(right: 4.0),
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
                if (p.confidence != null) ...[
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
                        '${(p.confidence! * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: p.confidence!.clamp(0, 1),
                      minHeight: 8,
                    ),
                  ),
                ],

                // NOTES
                if (p.notes != null && p.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    p.notes!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // FLAGGED INGREDIENTS AS CHIPS
                if (p.halalMatches.isNotEmpty) ...[
                  Text('Flagged ingredients & terms',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: p.halalMatches.map((match) {
                      final c = AppStyleHelpers.halalStatusColor(match.status);
                      final label = match.notes != null && match.notes!.isNotEmpty
                          ? '${match.term} — ${match.notes}'
                          : match.term;
                      return Chip(
                        label: Text('$label (${match.status.toUpperCase()})'),
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
                if (p.ingredients != null && p.ingredients!.isNotEmpty)
                  _IngredientsTile(text: p.ingredients!),

                const SizedBox(height: 8),

                // TIMELINE STEPS
                if (p.analysisSteps.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Checks', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  ...List.generate(p.analysisSteps.length, (i) {
                    final step = p.analysisSteps[i];
                    final (icon, color) = AppStyleHelpers.stepVisual(step.status);
                    final isLast = i == p.analysisSteps.length - 1;

                    return _TimelineRow(
                      icon: icon,
                      color: color,
                      title: step.label,
                      subtitle: step.detail,
                      showConnector: !isLast,
                    );
                  }),
                ],

                const SizedBox(height: 16),

                // ACTION BUTTONS (Favorite + Share + Scan Again)
                Row(
                  children: [
                    // Favorite button
                    _FavIconButton(
                      isFavorited: _isFavorited,
                      onPressed: () async {
                        final fav = FavoriteProduct(
                          barcode: p.barcode,
                          name: p.name,
                          brand: p.brand,
                          halalStatus: p.halalStatus,
                          imageUrl: p.imageUrl,
                        );
                        final nowFav =
                            await FavoritesService.instance.toggle(fav);
                        setState(() => _isFavorited = nowFav);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(nowFav
                                  ? 'Added to favorites'
                                  : 'Removed from favorites'),
                              duration: const Duration(milliseconds: 1500),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    // Share button
                    OutlinedButton.icon(
                      onPressed: () => _shareProduct(p),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.m),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Scan Again
                    Expanded(
                      child: ElevatedButton(
                        style: AppButtons.secondaryButton,
                        onPressed: widget.onScanAgain,
                        child: const Text('Scan Again'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme, String error) {
    final isQuota = widget.isQuotaBlock;
    final isGuest = FirebaseAuth.instance.currentUser == null;

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppCards.modalShadows,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isQuota ? Icons.lock_outline : Icons.error_outline,
                color: isQuota ? AppColors.gold : Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                error,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),

              // ── Quota block CTAs ──
              if (isQuota) ...[
                // Primary: Subscribe / Upgrade
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: AppButtons.primaryButton,
                    onPressed: () async {
                      final upgraded = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => const PaywallScreen(),
                        ),
                      );
                      // If they subscribed, retry the scan
                      if (upgraded == true && widget.onRetry != null) {
                        widget.onRetry!();
                      }
                    },
                    icon: const Icon(Icons.workspace_premium, size: 20),
                    label: Text(isGuest
                        ? 'Subscribe for Unlimited'
                        : 'Upgrade to Premium'),
                  ),
                ),
                const SizedBox(height: 10),

                // Guest: also offer account creation without subscription
                if (isGuest) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.l),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Create Free Account'),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],

              // ── Regular error CTAs ──
              if (!isQuota && widget.onRetry != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: AppButtons.secondaryButton,
                    onPressed: widget.onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Always show scan-different option
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onScanAgain,
                  child: const Text('Scan Different Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==== Share helper ====

  void _shareProduct(Product p) {
    final status = p.halalStatus.toUpperCase();
    final flagged = p.halalMatches
        .map((m) => '  • ${m.term} (${m.status})')
        .join('\n');
    final confidence = p.confidence != null
        ? '\nAI Confidence: ${(p.confidence! * 100).toStringAsFixed(0)}%'
        : '';

    final text = StringBuffer()
      ..writeln('${p.name}${p.brand != null ? ' by ${p.brand}' : ''}')
      ..writeln('Halal Status: $status$confidence')
      ..writeln()
      ..writeln(flagged.isNotEmpty
          ? 'Flagged ingredients:\n$flagged'
          : 'No flagged ingredients found.')
      ..writeln()
      ..writeln('Checked with Ummaly — halal verification app');

    SharePlus.instance.share(ShareParams(text: text.toString()));
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

class _FavIconButton extends StatelessWidget {
  final bool isFavorited;
  final VoidCallback onPressed;
  const _FavIconButton({required this.isFavorited, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: isFavorited ? 'Remove from favorites' : 'Add to favorites',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: Icon(
          isFavorited ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          key: ValueKey(isFavorited),
          color: isFavorited ? Colors.redAccent : AppColors.textSecondary,
          size: 24,
        ),
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
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(subtitle!, style: AppTextStyles.caption),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
