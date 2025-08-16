import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UmmalyMapStyles {
  // Light map tinted to brand
  static const String light = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f1f0ff"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#4b3f90"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#d7d4f8"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#e9e7ff"}]},
  {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#e3f2e7"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#fdfcff"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#dad5ff"}]},
  {"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#e1defb"}]},
  {"featureType":"water","elementType":"geometry.fill","stylers":[{"color":"#d6e9ff"}]}
]
''';

  // Optional dark variant
  static const String dark = '''
[
  {"elementType":"geometry","stylers":[{"color":"#202124"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#e8eaed"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#202124"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#3c4043"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#303134"}]},
  {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#263238"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#3c4043"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#3c4043"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#43464a"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3136"}]},
  {"featureType":"water","elementType":"geometry.fill","stylers":[{"color":"#22303c"}]}
]
''';

  static Future<void> apply(GoogleMapController controller, BuildContext context) async {
    final brightness = Theme.of(context).brightness;
    final style = brightness == Brightness.dark ? dark : light;
    await controller.setMapStyle(style);
  }
}
