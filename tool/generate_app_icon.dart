// ignore_for_file: avoid_print
/// Run this script to generate an app icon PNG.
/// Usage: dart run tool/generate_app_icon.dart
///
/// NOTE: This script creates an SVG file that can be converted to PNG
/// using any SVG-to-PNG tool or opened in a browser and screenshotted.
/// For production, use a tool like flutter_launcher_icons.

import 'dart:io';

void main() {
  // Generate a 1024x1024 SVG of the Ummaly logo (crescent + star + mosque)
  // Dark navy background with gold logo — no text, just the icon.

  const int size = 1024;
  const double cx = size / 2;
  const double cy = size / 2;
  const String gold = '#D4A574';
  const String darkBg = '#0F1A2E';

  final sb = StringBuffer();
  sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  sb.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $size $size" width="$size" height="$size">');

  // Background with rounded corners (for iOS style)
  sb.writeln('  <rect width="$size" height="$size" rx="224" fill="$darkBg"/>');

  // Subtle radial glow behind logo
  sb.writeln('  <defs>');
  sb.writeln('    <radialGradient id="glow" cx="50%" cy="45%" r="40%">');
  sb.writeln('      <stop offset="0%" stop-color="$gold" stop-opacity="0.12"/>');
  sb.writeln('      <stop offset="100%" stop-color="$gold" stop-opacity="0"/>');
  sb.writeln('    </radialGradient>');
  sb.writeln('  </defs>');
  sb.writeln('  <circle cx="$cx" cy="${cy * 0.85}" r="380" fill="url(#glow)"/>');

  // ── Mosque silhouette (lower portion) ──
  final double mosqueTop = size * 0.48;
  final double mosqueBottom = size * 0.82;
  final double mh = mosqueBottom - mosqueTop;

  final double minaretW = size * 0.045;
  final double leftMinX = size * 0.22;
  final double rightMinX = size * 0.735;
  final double domeStartX = size * 0.34;
  final double domeEndX = size * 0.66;

  // Mosque fill (subtle)
  sb.write('  <path d="');
  sb.write('M ${size * 0.15} $mosqueBottom ');
  sb.write('L $leftMinX $mosqueBottom ');
  sb.write('L $leftMinX ${mosqueTop + mh * 0.18} ');
  sb.write('Q ${leftMinX + minaretW / 2} ${mosqueTop + mh * 0.04} ${leftMinX + minaretW} ${mosqueTop + mh * 0.18} ');
  sb.write('L ${leftMinX + minaretW} $mosqueBottom ');
  sb.write('L $domeStartX $mosqueBottom ');
  sb.write('L $domeStartX ${mosqueTop + mh * 0.48} ');
  sb.write('Q $cx ${mosqueTop + mh * 0.08} $domeEndX ${mosqueTop + mh * 0.48} ');
  sb.write('L $domeEndX $mosqueBottom ');
  sb.write('L $rightMinX $mosqueBottom ');
  sb.write('L $rightMinX ${mosqueTop + mh * 0.18} ');
  sb.write('Q ${rightMinX + minaretW / 2} ${mosqueTop + mh * 0.04} ${rightMinX + minaretW} ${mosqueTop + mh * 0.18} ');
  sb.write('L ${rightMinX + minaretW} $mosqueBottom ');
  sb.write('L ${size * 0.85} $mosqueBottom ');
  sb.write('Z');
  sb.writeln('" fill="$gold" fill-opacity="0.25"/>');

  // Mosque stroke
  sb.write('  <path d="');
  sb.write('M ${size * 0.15} $mosqueBottom ');
  sb.write('L $leftMinX $mosqueBottom ');
  sb.write('L $leftMinX ${mosqueTop + mh * 0.18} ');
  sb.write('Q ${leftMinX + minaretW / 2} ${mosqueTop + mh * 0.04} ${leftMinX + minaretW} ${mosqueTop + mh * 0.18} ');
  sb.write('L ${leftMinX + minaretW} $mosqueBottom ');
  sb.write('L $domeStartX $mosqueBottom ');
  sb.write('L $domeStartX ${mosqueTop + mh * 0.48} ');
  sb.write('Q $cx ${mosqueTop + mh * 0.08} $domeEndX ${mosqueTop + mh * 0.48} ');
  sb.write('L $domeEndX $mosqueBottom ');
  sb.write('L $rightMinX $mosqueBottom ');
  sb.write('L $rightMinX ${mosqueTop + mh * 0.18} ');
  sb.write('Q ${rightMinX + minaretW / 2} ${mosqueTop + mh * 0.04} ${rightMinX + minaretW} ${mosqueTop + mh * 0.18} ');
  sb.write('L ${rightMinX + minaretW} $mosqueBottom ');
  sb.write('L ${size * 0.85} $mosqueBottom');
  sb.writeln('" fill="none" stroke="$gold" stroke-width="3" stroke-opacity="0.6"/>');

  // Finial dots
  sb.writeln('  <circle cx="${leftMinX + minaretW / 2}" cy="${mosqueTop + mh * 0.02}" r="6" fill="$gold" fill-opacity="0.5"/>');
  sb.writeln('  <circle cx="${rightMinX + minaretW / 2}" cy="${mosqueTop + mh * 0.02}" r="6" fill="$gold" fill-opacity="0.5"/>');
  sb.writeln('  <circle cx="$cx" cy="${mosqueTop + mh * 0.06}" r="8" fill="$gold" fill-opacity="0.5"/>');

  // ── Crescent moon (upper portion) ──
  final double moonCy = size * 0.36;
  final double moonR = size * 0.19;
  final double cutR = moonR * 0.82;
  final double cutOffsetX = moonR * 0.38;

  // Using clipPath to create crescent
  sb.writeln('  <defs>');
  sb.writeln('    <clipPath id="crescent-clip">');
  sb.writeln('      <rect x="0" y="0" width="$size" height="$size"/>');
  sb.writeln('    </clipPath>');
  sb.writeln('  </defs>');

  // Draw crescent using two circles and masking
  sb.writeln('  <mask id="crescent-mask">');
  sb.writeln('    <rect width="$size" height="$size" fill="black"/>');
  sb.writeln('    <circle cx="$cx" cy="$moonCy" r="$moonR" fill="white"/>');
  sb.writeln('    <circle cx="${cx + cutOffsetX}" cy="${moonCy - moonR * 0.05}" r="$cutR" fill="black"/>');
  sb.writeln('  </mask>');

  sb.writeln('  <rect width="$size" height="$size" fill="$gold" mask="url(#crescent-mask)"/>');

  // ── Five-pointed star ──
  final double starCx = cx + moonR * 0.52;
  final double starCy = moonCy - moonR * 0.10;
  final double starR = moonR * 0.24;
  final double starInnerR = starR * 0.45;

  sb.write('  <polygon points="');
  for (int i = 0; i < 10; i++) {
    final double r = i.isEven ? starR : starInnerR;
    final double angle = -3.14159 / 2 + (i * 3.14159 / 5);
    final double px = starCx + r * _cos(angle);
    final double py = starCy + r * _sin(angle);
    if (i > 0) sb.write(' ');
    sb.write('${px.toStringAsFixed(2)},${py.toStringAsFixed(2)}');
  }
  sb.writeln('" fill="$gold"/>');

  sb.writeln('</svg>');

  // Write to file
  final outputDir = Directory('assets/images');
  if (!outputDir.existsSync()) outputDir.createSync(recursive: true);

  final file = File('assets/images/ummaly_icon.svg');
  file.writeAsStringSync(sb.toString());
  print('✅ App icon SVG generated: ${file.path}');
  print('   Open in a browser or use an SVG→PNG converter to generate the icon at 1024x1024.');
  print('   Then use flutter_launcher_icons to set it as the app icon.');
}

double _cos(double angle) {
  // Simple cosine using dart:math would require import, using Taylor series approx
  // Actually let's just import dart:math
  return _cosVal(angle);
}

double _sin(double angle) {
  return _sinVal(angle);
}

// Manual math since we can't easily import in this context
double _cosVal(double x) {
  // Normalize to [-pi, pi]
  while (x > 3.14159) x -= 2 * 3.14159;
  while (x < -3.14159) x += 2 * 3.14159;
  // Taylor series
  double result = 1.0;
  double term = 1.0;
  for (int i = 1; i <= 10; i++) {
    term *= -x * x / ((2 * i - 1) * (2 * i));
    result += term;
  }
  return result;
}

double _sinVal(double x) {
  while (x > 3.14159) x -= 2 * 3.14159;
  while (x < -3.14159) x += 2 * 3.14159;
  double result = x;
  double term = x;
  for (int i = 1; i <= 10; i++) {
    term *= -x * x / ((2 * i) * (2 * i + 1));
    result += term;
  }
  return result;
}
