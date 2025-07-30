import 'dart:io'; // ✅ For platform check
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ummaly/core/services/scan_service.dart';
import 'package:ummaly/theme/styles.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({Key? key}) : super(key: key);

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen>
    with SingleTickerProviderStateMixin {
  final ScanService _scanService = ScanService();

  // ✅ NEW: Camera controller for scanner & torch control
  final MobileScannerController _cameraController = MobileScannerController();

  String? scannedCode;
  Map<String, dynamic>? productData; // ✅ Holds product details
  bool isLoading = false;
  bool isScannerPaused = false; // ✅ Pauses scanning while showing a product
  String? errorMessage;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// ✅ Uses ScanService to fetch product details (debounced)
  Future<void> _handleScan(String barcode) async {
    print("📤 [UI] Sending barcode to ScanService: $barcode");

    setState(() {
      isLoading = true;
      productData = null;
      errorMessage = null;
    });

    final product = await _scanService.scanProduct(barcode);

    if (!mounted) return;

    if (product != null) {
      print("✅ [UI] Product loaded: ${product.name}");
      setState(() {
        productData = product.toJson(); // ✅ Will include halal_matches, notes, confidence now
      });
    } else {
      print("❌ [UI] Failed to fetch product");
      setState(() {
        errorMessage = "❌ Product not found or server error";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  /// ✅ Badge colors for Halal/Haram/Unknown
  Color _getHalalStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case "halal":
        return Colors.green;
      case "haram":
        return Colors.red;
      case "conditional":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Scan Product"),
        backgroundColor: AppColors.scanner,
      ),
      body: Stack(
        children: [
          /// 📸 Camera view
          MobileScanner(
            controller: _cameraController, // ✅ Controller added
            fit: BoxFit.cover,
            onDetect: (capture) {
              if (isScannerPaused) return;
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final code = barcodes.first.rawValue;

                if (code != null && code != scannedCode) {
                  print("🔍 [UI] Detected new barcode: $code");
                  setState(() {
                    scannedCode = code;
                    isScannerPaused = true;
                  });
                  _handleScan(code);
                }
              }
            },
          ),

          /// 🔦 Torch toggle button (top-right)
          Positioned(
            top: 20,
            right: 20,
            child: ValueListenableBuilder<TorchState>(
              valueListenable: _cameraController.torchState,
              builder: (context, state, child) {
                final isTorchOn = state == TorchState.on;
                return IconButton(
                  icon: Icon(
                    isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color: isTorchOn ? Colors.yellow : Colors.white,
                    size: 30,
                  ),
                  onPressed: () => _cameraController.toggleTorch(),
                );
              },
            ),
          ),

          /// ✅ Animated guide box overlay
          Center(
            child: ScaleTransition(
              scale: _pulseController,
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

          /// ✅ Loading spinner overlay on the camera while fetching
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          /// ✅ Footer with instructions
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

          /// 📊 Product or error card
          if (!isLoading && (errorMessage != null || productData != null))
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (errorMessage != null) ...[
                            Text(
                              errorMessage!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ] else if (productData != null) ...[
                            /// ✅ Product image
                            if (productData!['image_url'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  productData!['image_url'],
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                height: 150,
                                width: 150,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported,
                                    size: 50, color: Colors.grey),
                              ),

                            const SizedBox(height: 12),

                            /// ✅ Product name & brand
                            Text(
                              productData!['name'] ?? "Unnamed Product",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (productData!['brand'] != null)
                              Text(
                                productData!['brand'],
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black54),
                              ),

                            const SizedBox(height: 10),

                            /// ✅ Halal status badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Halal Status: ",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getHalalStatusColor(
                                        productData!['halal_status']),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    productData!['halal_status']
                                        ?.toString()
                                        .toUpperCase() ??
                                        "UNKNOWN",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),

                            /// ✅ Confidence score
                            if (productData!['confidence'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "Confidence: ${(productData!['confidence'] * 100).toStringAsFixed(1)}%",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ),

                            /// ✅ Summary notes
                            if (productData!['notes'] != null &&
                                productData!['notes'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 4.0, left: 12.0, right: 12.0),
                                child: Text(
                                  productData!['notes'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            const SizedBox(height: 10),

                            /// ✅ Ingredients
                            if (productData!['ingredients'] != null)
                              Text(
                                "📝 Ingredients: ${productData!['ingredients']}",
                                style: const TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),

                            const SizedBox(height: 12),

                            /// ✅ Halal matches section
                            if ((productData!['halal_matches'] as List).isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "🚩 Flagged Ingredients & Terms:",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  ...List.generate(
                                    (productData!['halal_matches'] as List)
                                        .length,
                                        (index) {
                                      final match =
                                      productData!['halal_matches'][index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0),
                                        child: Text(
                                          "• ${match['name']} (${match['status'].toUpperCase()}) – ${match['notes']}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: match['status'] == 'haram'
                                                ? Colors.red
                                                : (match['status'] ==
                                                'conditional'
                                                ? Colors.orange
                                                : Colors.green),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              )
                            else
                              const Text(
                                "✅ No flagged items found",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.green),
                              ),
                          ],

                          const SizedBox(height: 20),

                          /// ✅ Scan Again button
                          ElevatedButton(
                            style: AppButtons.secondaryButton,
                            onPressed: () => setState(() {
                              scannedCode = null;
                              productData = null;
                              errorMessage = null;
                              isScannerPaused = false; // ✅ Resume scanning
                            }),
                            child: const Text("Scan Again"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
