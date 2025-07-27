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

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  String? scannedCode;
  Map<String, dynamic>? productData; // ✅ Hold all product details
  bool isLoading = false;
  String? errorMessage;

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
          // 📸 Camera viewfinder
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
            ),
          ),

          // 📊 Result section
          Expanded(
            flex: 2,
            child: SingleChildScrollView( // ✅ Fixes overflow issues
              padding: const EdgeInsets.all(12),
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

                    // ✅ Loader or Product Info
                    if (isLoading)
                      const CircularProgressIndicator()
                    else if (errorMessage != null)
                      Text(
                        errorMessage!,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.red,
                        ),
                      )
                    else if (productData != null) ...[
                        // ✅ Show product image if exists
                        if (productData!['image_url'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              productData!['image_url'],
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            height: 120,
                            width: 120,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported,
                                size: 40, color: Colors.grey),
                          ),

                        const SizedBox(height: 12),

                        // ✅ Product name & brand
                        Text(
                          productData!['name'] ?? "Unnamed Product",
                          style: AppTextStyles.body.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          productData!['brand'] ?? "Unknown Brand",
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: 10),

                        // ✅ Ingredients if available
                        if (productData!['ingredients'] != null)
                          Text(
                            "📝 Ingredients: ${productData!['ingredients']}",
                            style: AppTextStyles.body.copyWith(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                      ],

                    const SizedBox(height: 16),

                    // ✅ Reset Scan Button
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
        ],
      ),
    );
  }
}
