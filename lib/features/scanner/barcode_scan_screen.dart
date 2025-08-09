import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import 'package:ummaly/core/controllers/barcode_scan_controller.dart';
import 'package:ummaly/features/scanner/widgets/product_card.dart';
import 'package:ummaly/features/scanner/widgets/scanner_overlay.dart';
import 'package:ummaly/features/scanner/scan_history_screen.dart';
import 'package:ummaly/theme/styles.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({Key? key}) : super(key: key);

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late BarcodeScanController _controller;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);

    _controller = BarcodeScanController();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BarcodeScanController>.value(
      value: _controller,
      child: Consumer<BarcodeScanController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text("Scan Product"),
              backgroundColor: AppColors.scanner,
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: "View Scan History",
                  onPressed: () async {
                    final String firebaseUid =
                        FirebaseAuth.instance.currentUser?.uid ?? '';
                    if (firebaseUid.isNotEmpty) {
                      await controller.cameraController.stop();
                      await Get.to(() => ScanHistoryScreen(firebaseUid: firebaseUid));
                      await controller.cameraController.start();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You need to log in first')),
                      );
                    }
                  },
                ),
                ValueListenableBuilder<TorchState>(
                  valueListenable: controller.torchState,
                  builder: (context, state, _) {
                    final isTorchOn = state == TorchState.on;
                    return IconButton(
                      icon: Icon(
                        isTorchOn ? Icons.flash_on : Icons.flash_off,
                        color: isTorchOn ? Colors.yellow : Colors.white,
                      ),
                      onPressed: controller.toggleTorch,
                    );
                  },
                ),
              ],
            ),
            body: Stack(
              children: [
                // Fade animation between scanner and product view
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: controller.productData != null ||
                      controller.errorMessage != null
                      ? ProductCard(
                    key: const ValueKey('productCard'),
                    productData: controller.productData,
                    errorMessage: controller.errorMessage,
                    onScanAgain: () {
                      controller.resetScan(); // resetScan is void; no await
                    },
                  )
                      : Stack(
                    key: const ValueKey('scannerView'),
                    children: [
                      MobileScanner(
                        controller: controller.cameraController,
                        fit: BoxFit.cover,
                        onDetect: (BarcodeCapture capture) {
                          if (controller.isScannerPaused) return;

                          final List<Barcode> barcodes = capture.barcodes;

                          if (barcodes.isNotEmpty) {
                            final String? code = barcodes.first.rawValue;
                            if (code != null &&
                                code != controller.scannedCode) {
                              controller.handleScan(code);
                            }
                          }
                        },
                      ),
                      ScannerOverlay(pulseController: _pulseController),

                      // Ummaly-branded dim/blur overlay while loading
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: controller.isLoading
                            ? const _ProcessingOverlay(
                          title: 'Checking product…',
                          subtitle:
                          'Ummaly is verifying ingredients and sources',
                        )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Dim/blur overlay with a branded loading card.
/// Keep the camera mounted; this sits above it while a scan is processing.
class _ProcessingOverlay extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _ProcessingOverlay({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.35),
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
              child: _LoadingCard(title: title, subtitle: subtitle),
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
  const _LoadingCard({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width * 0.86;

    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.25),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBackground.withOpacity(0.98),
            AppColors.cardBackground.withOpacity(0.92),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // LOGO with rounded corners (no black corners visible)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/ummaly_logo.jpg', // ensure this path is in pubspec.yaml
              height: 70,
              width: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),

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
          const SizedBox(height: 2, width: 160, child: _ShimmerBar()),
          const SizedBox(height: 8),
          const SizedBox(height: 2, width: 120, child: _ShimmerBar()),
          const SizedBox(height: 16),
          const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
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
