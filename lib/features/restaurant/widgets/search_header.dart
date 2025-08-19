import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ummaly/theme/styles.dart';

class SearchHeader extends StatefulWidget {
  final TextEditingController qController;
  final TextEditingController nearController;

  final double radiusKm;
  final bool radiusExpanded;
  final bool useMiles;
  final String radiusLabel;

  final VoidCallback onMeasureRequested;
  final VoidCallback onCollapseSheet;
  final VoidCallback onToggleRadius;
  final VoidCallback onSearchPressed;
  final VoidCallback onSubmit;

  final void Function(double valueInUnits) onPresetTap;
  final void Function(double v) onRadiusChanged;
  final void Function(double v) onRadiusChangeEnd;

  const SearchHeader({
    super.key,
    required this.qController,
    required this.nearController,
    required this.radiusKm,
    required this.radiusExpanded,
    required this.useMiles,
    required this.radiusLabel,
    required this.onMeasureRequested,
    required this.onCollapseSheet,
    required this.onToggleRadius,
    required this.onSearchPressed,
    required this.onSubmit,
    required this.onPresetTap,
    required this.onRadiusChanged,
    required this.onRadiusChangeEnd,
  });

  @override
  State<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<SearchHeader>
    with TickerProviderStateMixin {
  static const _kAnim = Duration(milliseconds: 220);
  Timer? _measureDebounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re‑measure after first frame (height affects map offset & sheet snap)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMeasureRequested();
    });
  }

  @override
  void didUpdateWidget(covariant SearchHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When expand/collapse changes, re‑measure after the animation settles.
    if (oldWidget.radiusExpanded != widget.radiusExpanded) {
      _scheduleMeasureAfterAnim();
    }
  }

  @override
  void dispose() {
    _measureDebounce?.cancel();
    super.dispose();
  }

  void _scheduleMeasureAfterAnim() {
    _measureDebounce?.cancel();
    _measureDebounce = Timer(_kAnim + const Duration(milliseconds: 40), () {
      // Let layout settle, then ask parent to re‑measure.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onMeasureRequested();
      });
    });
  }

  double get _kmToMi => 0.621371;

  @override
  Widget build(BuildContext context) {
    final presets = widget.useMiles ? [1.0, 3.0, 10.0] : [1.0, 5.0, 10.0];

    String _labelForUnit(double valueInUnits) =>
        widget.useMiles ? '${valueInUnits.toStringAsFixed(0)} mi' : '${valueInUnits.toStringAsFixed(0)} km';

    final radiusControls = Column(
      children: [
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            for (final p in presets)
              _PresetChip(
                label: _labelForUnit(p),
                onTap: () => widget.onPresetTap(p),
              ),
          ],
        ),
        Slider(
          value: widget.radiusKm,
          min: 0.5,
          max: 40.0,
          divisions: 79,
          label: widget.radiusLabel,
          onChangeStart: (_) => widget.onCollapseSheet(),
          onChanged: widget.onRadiusChanged,
          onChangeEnd: widget.onRadiusChangeEnd,
        ),
      ],
    );

    return Material(
      color: AppColors.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(AppRadius.l),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search/near row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.qController,
                    textInputAction: TextInputAction.search,
                    decoration: AppInput.decoration(
                      label: 'Search',
                      hint: 'e.g. halal, pizza',
                      prefix: Icons.search,
                    ),
                    onTap: widget.onCollapseSheet,
                    onSubmitted: (_) => widget.onSubmit(),
                  ),
                ),
                const SizedBox(width: AppSpacing.l),
                Expanded(
                  child: TextField(
                    controller: widget.nearController,
                    textInputAction: TextInputAction.search,
                    decoration: AppInput.decoration(
                      label: 'Near',
                      hint: 'city/postcode (optional)',
                      prefix: Icons.place_outlined,
                    ),
                    onTap: widget.onCollapseSheet,
                    onSubmitted: (_) => widget.onSubmit(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.m),

            // Radius header row (tap to expand/collapse)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                widget.onToggleRadius();
                // parent updates radiusExpanded; we’ll catch it in didUpdateWidget
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.radar, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      'Search radius',
                      style: AppTextStyles.caption.copyWith(fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      widget.radiusLabel,
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    AnimatedRotation(
                      turns: widget.radiusExpanded ? 0.5 : 0.0,
                      duration: _kAnim,
                      curve: Curves.easeOut,
                      child: const Icon(Icons.expand_more, size: 22),
                    ),
                  ],
                ),
              ),
            ),

            // Smooth expand/collapse (no flicker)
            AnimatedSize(
              duration: _kAnim,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Align(
                // heightFactor smoothly shrinks/grows without rebuilding children
                heightFactor: widget.radiusExpanded ? 1.0 : 0.0,
                alignment: Alignment.topCenter,
                child: AnimatedOpacity(
                  duration: _kAnim,
                  curve: Curves.easeOut,
                  opacity: widget.radiusExpanded ? 1.0 : 0.0,
                  child: radiusControls,
                ),
              ),
            ),

            // Search button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onSearchPressed,
                icon: const Icon(Icons.search),
                label: const Text('Search'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
