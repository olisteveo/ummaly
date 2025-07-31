import 'package:flutter/material.dart';
import 'package:ummaly/theme/styles.dart';

/// Displays product info, errors, and the scan again button
class ProductCard extends StatelessWidget {
  final Map<String, dynamic>? productData;
  final String? errorMessage;
  final VoidCallback onScanAgain;

  const ProductCard({
    Key? key,
    this.productData,
    this.errorMessage,
    required this.onScanAgain,
  }) : super(key: key);

  /// Badge colors for Halal/Haram/Unknown
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
    if (errorMessage == null && productData == null) return const SizedBox();

    return Positioned.fill(
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
                    /// Product image
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

                    /// Product name & brand
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

                    /// Halal status badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Halal Status: ",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
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

                    /// Confidence score
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

                    /// Notes
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

                    /// Ingredients
                    if (productData!['ingredients'] != null)
                      Text(
                        "📝 Ingredients: ${productData!['ingredients']}",
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),

                    const SizedBox(height: 12),

                    /// Flagged items
                    if ((productData!['halal_matches'] as List).isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "🚩 Flagged Ingredients & Terms:",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          ...List.generate(
                            (productData!['halal_matches'] as List).length,
                                (index) {
                              final match =
                              productData!['halal_matches'][index];
                              return Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  "• ${match['name']} (${match['status'].toUpperCase()}) – ${match['notes']}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: match['status'] == 'haram'
                                        ? Colors.red
                                        : (match['status'] == 'conditional'
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
                        style: TextStyle(fontSize: 14, color: Colors.green),
                      ),
                  ],

                  const SizedBox(height: 20),

                  /// Scan Again button
                  ElevatedButton(
                    style: AppButtons.secondaryButton,
                    onPressed: onScanAgain,
                    child: const Text("Scan Again"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
