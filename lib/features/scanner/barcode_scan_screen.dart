import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Haptics
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import 'package:ummaly/core/controllers/barcode_scan_controller.dart';
import 'package:ummaly/features/scanner/widgets/product_card.dart';
import 'package:ummaly/features/scanner/widgets/scanner_overlay.dart';
import 'package:ummaly/features/scanner/scan_history_screen.dart';
import 'package:ummaly/features/scanner/widgets/processing_overlay.dart'; // <-- use the shared overlay
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
                // Smooth transition between scanner and product view
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    final fade = FadeTransition(opacity: animation, child: child);
                    final slide = SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.02),
                        end: Offset.zero,
                      ).animate(animation),
                      child: fade,
                    );
                    return slide;
                  },
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
                              // Haptic feedback on detection
                              HapticFeedback.selectionClick();
                              controller.handleScan(code);
                            }
                          }
                        },
                      ),
                      ScannerOverlay(pulseController: _pulseController),

                      // Shared Ummaly-branded overlay while loading
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: controller.isLoading
                            ? const ProcessingOverlay(
                          title: 'Checking product…',
                          subtitle:
                          'Ummaly is verifying ingredients and sources',
                          // step support is available; for now show 1/1
                          step: 1,
                          totalSteps: 1,
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
