import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ummaly/theme/styles.dart';

/// Processing overlay that can work with either:
///  - explicit [step]/[totalSteps], or
///  - a backend-provided list length passed via [dynamicTotalSteps].
class ProcessingOverlay extends StatelessWidget {
  final String title;
  final String? subtitle;

  /// Optional short label for the current phase, e.g. "AI adjudication…"
  /// Shown under "Step n of m" when provided.
  final String? phaseLabel;

  /// If you already know the step index (1-based) and total,
  /// pass them in. Otherwise you can just pass [dynamicTotalSteps].
  final int? step;
  final int? totalSteps;

  /// Optional total count derived from a dynamic steps list (e.g., analysis_steps.length).
  /// Only used when [totalSteps] is null.
  final int? dynamicTotalSteps;

  /// When true, replaces the spinner with a check icon on final step.
  final bool showCheckOnComplete;

  const ProcessingOverlay({
    super.key,
    required this.title,
    this.subtitle,
    this.phaseLabel,
    this.step,
    this.totalSteps,
    this.dynamicTotalSteps,
    this.showCheckOnComplete = true,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedTotal = totalSteps ?? dynamicTotalSteps;
    final isComplete = step != null &&
        resolvedTotal != null &&
        step! >= resolvedTotal &&
        showCheckOnComplete;

    return IgnorePointer(
      ignoring: true,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.45),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: const SizedBox.expand(),
              ),
            ),
            Center(
              child: _LoadingCard(
                title: title,
                subtitle: subtitle,
                phaseLabel: phaseLabel,
                step: step,
                totalSteps: resolvedTotal,
                isComplete: isComplete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? phaseLabel;
  final int? step;
  final int? totalSteps;
  final bool isComplete;

  const _LoadingCard({
    required this.title,
    this.subtitle,
    this.phaseLabel,
    this.step,
    this.totalSteps,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width * 0.86;

    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBackground.withOpacity(0.98),
            AppColors.cardBackground.withOpacity(0.92),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.25),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/ummaly_logo.jpg',
              height: 60,
              width: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),

          if (step != null && totalSteps != null) ...[
            Text(
              'Step $step of $totalSteps',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (phaseLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                phaseLabel!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.9),
                ),
              ),
            ],
            const SizedBox(height: 6),
          ],

          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Shimmer lines remain for visual movement even when complete
          const SizedBox(height: 2, width: 160, child: _ShimmerBar()),
          const SizedBox(height: 8),
          const SizedBox(height: 2, width: 120, child: _ShimmerBar()),
          const SizedBox(height: 16),

          // Spinner → Checkmark when final step is reached
          SizedBox(
            height: 28,
            width: 28,
            child: isComplete
                ? const Icon(Icons.check_circle_outline, size: 28)
                : const CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBar extends StatefulWidget {
  const _ShimmerBar();

  @override
  State<_ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<_ShimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (context, _) {
        return CustomPaint(
          painter: _ShimmerPainter(progress: _ac.value),
        );
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  _ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = Colors.white.withOpacity(0.18);
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(2));
    canvas.drawRRect(r, base);

    final w = size.width * 0.35;
    final x = (size.width + w) * progress - w;
    final rect = Rect.fromLTWH(x, 0, w, size.height);
    final gradient = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.transparent, Colors.white, Colors.transparent],
      stops: [0.0, 0.5, 1.0],
    ).createShader(rect);
    final p = Paint()..shader = gradient;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), p);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) => old.progress != progress;
}
