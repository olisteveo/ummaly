import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Custom Google Maps styles aligned with Ummaly's Islamic-inspired design system.
///
/// Light theme: warm cream/emerald palette matching [AppColors.background],
/// [AppColors.primary], and [AppColors.emerald].
///
/// Dark theme: deep navy surfaces matching [AppColors.darkSurface] with
/// emerald road accents.
class UmmalyMapStyles {
  /// Light map — warm cream surfaces, emerald roads, teal labels.
  static const String light = '''
[
  {"elementType":"geometry","stylers":[{"color":"#F7F3EE"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#1A1A2E"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#FFFFFF"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#D6D0C6"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#0D7377"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#F5F0E8"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6B7280"}]},
  {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#E3F0E8"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#166534"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#FFFFFF"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#6B7280"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#FDFCF8"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#E8D5B0"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#C9A96E"}]},
  {"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#E5E0D8"}]},
  {"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#F5F0E8"}]},
  {"featureType":"water","elementType":"geometry.fill","stylers":[{"color":"#CDDEED"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#0E7490"}]}
]
''';

  /// Dark map — deep navy with emerald accents.
  static const String dark = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0F1A2E"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#E5E0D8"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0F1A2E"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#1A1A2E"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#14897E"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#1A1A2E"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6B7280"}]},
  {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#0D2B2E"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1A2744"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9CA3AF"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#1A2744"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#115E59"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#0D7377"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#162038"}]},
  {"featureType":"water","elementType":"geometry.fill","stylers":[{"color":"#0A1929"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#0E7490"}]}
]
''';

  /// Apply the appropriate map style based on the current theme brightness.
  static Future<void> apply(GoogleMapController controller, BuildContext context) async {
    final brightness = Theme.of(context).brightness;
    final style = brightness == Brightness.dark ? dark : light;
    await controller.setMapStyle(style);
  }
}
