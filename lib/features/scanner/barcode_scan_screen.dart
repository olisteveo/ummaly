import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ummaly/theme/styles.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({Key? key}) : super(key: key);

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  String? scannedCode; // Holds last scanned barcode

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Scan Product"),
        backgroundColor: AppColors.scanner,
      ),
      body: Column(
        children: [
          // Camera viewfinder
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: MobileScanner(
                fit: BoxFit.cover,
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final code = barcodes.first.rawValue;
                    setState(() {
                      scannedCode = code ?? 'Unknown';
                    });
                  }
                },
              ),
            ),
          ),

          // Result & Actions section
          Expanded(
            flex: 1,
            child: Center(
              child: scannedCode == null
                  ? Text(
                "Point your camera at a barcode",
                style: AppTextStyles.instruction,
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Scanned Code:",
                    style: AppTextStyles.heading,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scannedCode!,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 20,
                      color: AppColors.scanner,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: AppButtons.secondaryButton,
                    onPressed: () => setState(() => scannedCode = null),
                    child: const Text("Scan Again"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
