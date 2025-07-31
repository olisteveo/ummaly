import 'package:flutter/material.dart';

/// Displays the animated guide box & footer instructions
class ScannerOverlay extends StatelessWidget {
  final AnimationController pulseController;

  const ScannerOverlay({Key? key, required this.pulseController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// Green animated guide box
        Center(
          child: ScaleTransition(
            scale: pulseController,
            child: Container(
              width: 250,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        /// Footer instructions
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            padding: const EdgeInsets.all(12),
            child: const Text(
              "📷 Align barcode inside the box to scan",
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
