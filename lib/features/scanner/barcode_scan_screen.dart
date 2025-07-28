import 'dart:convert';
import 'dart:io'; // ✅ Needed for Platform check
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ummaly/theme/styles.dart';

/// ✅ Detect whether running on emulator or real device and choose correct base URL
String getBaseUrl() {
  if (Platform.isAndroid) {
    return "http://192.168.0.3:5000"; // ✅ Real device uses local IP
  } else {
    return "http://10.0.2.2:5000"; // ✅ Emulator uses 10.0.2.2
  }
}

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({Key? key}) : super(key: key);

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen>
    with SingleTickerProviderStateMixin {
  String? scannedCode;
  Map<String, dynamic>? productData; // ✅ Hold all product details
  bool isLoading = false;
  String? errorMessage;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // ✅ Pulse animation for scan box
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

  /// ✅ Call Node.js backend with scanned barcode
  Future<void> fetchProductFromBackend(String barcode) async {
    print("📤 Sending barcode $barcode to backend...");
    setState(() {
      isLoading = true;
      productData = null;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse("${getBaseUrl()}/scan"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"barcode": barcode}),
      );

      print("📥 Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Product from backend: ${data['product']['name']}");
        setState(() {
          productData = data['product']; // ✅ Save full product object
        });
      } else {
        print("❌ Backend returned ${response.statusCode}");
        setState(() {
          errorMessage = "❌ Product not found (status ${response.statusCode})";
        });
      }
    } catch (e) {
      print("⚠️ Error contacting backend: $e");
      setState(() {
        errorMessage = "⚠️ Error connecting to server";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// ✅ Helper to get badge color based on halal status
  Color _getHalalStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case "halal":
        return Colors.green;
      case "haram":
        return Colors.red;
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
          // 📸 Camera view
          MobileScanner(
            fit: BoxFit.cover,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final code = barcodes.first.rawValue;

                // ✅ Prevent duplicate calls
                if (code != null && code != scannedCode) {
                  print("🔍 New barcode detected: $code");
                  setState(() {
                    scannedCode = code;
                  });
                  fetchProductFromBackend(code);
                }
              }
            },
          ),

          // ✅ Animated Guide Box Overlay
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

          // ✅ Persistent Footer: “Scan barcode”
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

          // 📊 Overlay (Product Info / Loading / Error)
          if (isLoading || errorMessage != null || productData != null)
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
                          if (isLoading) ...[
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            const Text("Fetching product details..."),
                          ] else if (errorMessage != null) ...[
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
                            // ✅ Product Image
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

                            // ✅ Product Name & Brand
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

                            // ✅ Halal Status: Label + Badge
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

                            const SizedBox(height: 10),

                            // ✅ Ingredients
                            if (productData!['ingredients'] != null)
                              Text(
                                "📝 Ingredients: ${productData!['ingredients']}",
                                style: const TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                          ],

                          const SizedBox(height: 20),

                          // ✅ Scan Again Button
                          ElevatedButton(
                            style: AppButtons.secondaryButton,
                            onPressed: () => setState(() {
                              scannedCode = null;
                              productData = null;
                              errorMessage = null;
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
