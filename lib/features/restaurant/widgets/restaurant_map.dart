import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ummaly/theme/styles.dart';
import 'package:ummaly/theme/map_styles.dart';

/// Branded Google Map widget for Ummaly's restaurant search feature.
///
/// Applies [UmmalyMapStyles] automatically via the [style] parameter and
/// the [onMapCreated] callback for maximum compatibility across platforms.
///
/// Includes a recenter button and a graceful fallback placeholder when
/// Google Maps fails to load (e.g. missing API key on web).
class RestaurantMap extends StatefulWidget {
  final CameraPosition initialCamera;
  final Set<Marker> markers;
  final ValueChanged<GoogleMapController> onMapCreated;
  final bool myLocationEnabled;
  final VoidCallback onRecenter;
  final double recenterTop;

  /// Must be EdgeInsets (GoogleMap.padding requires this concrete type).
  final EdgeInsets padding;

  final MapType mapType;

  const RestaurantMap({
    super.key,
    required this.initialCamera,
    required this.markers,
    required this.onMapCreated,
    this.myLocationEnabled = true,
    required this.onRecenter,
    this.recenterTop = 140,
    this.padding = EdgeInsets.zero,
    this.mapType = MapType.normal,
  });

  @override
  State<RestaurantMap> createState() => _RestaurantMapState();
}

class _RestaurantMapState extends State<RestaurantMap> {
  bool _mapFailed = false;

  @override
  void initState() {
    super.initState();
    // On web, catch global Flutter errors from GoogleMap rendering.
    // If the Maps JS API is not activated, GoogleMap throws
    // "Cannot read properties of undefined (reading 'MapTypeId')"
    if (kIsWeb) {
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        final msg = details.exceptionAsString();
        if (msg.contains('MapTypeId') || msg.contains('google')) {
          if (mounted && !_mapFailed) {
            setState(() => _mapFailed = true);
          }
          return; // swallow the Maps-specific error
        }
        original?.call(details); // forward everything else
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mapFailed) {
      return _MapPlaceholder(markerCount: widget.markers.length);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: widget.initialCamera,
            markers: widget.markers,
            myLocationEnabled: !kIsWeb && widget.myLocationEnabled,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: kIsWeb, // show +/- buttons on web for easier zoom
            tiltGesturesEnabled: false,
            rotateGesturesEnabled: !kIsWeb, // disable rotation on web (confusing with mouse)
            // On web, disable scroll-based zoom/pan to prevent the map from
            // intercepting scroll events meant for the results list overlay.
            // Users can still zoom via +/- buttons shown on web.
            zoomGesturesEnabled: !kIsWeb,
            scrollGesturesEnabled: !kIsWeb,
            mapType: widget.mapType,
            padding: widget.padding,
            style: UmmalyMapStyles.light,
            onMapCreated: widget.onMapCreated,
          ),
        ),
        Positioned(
          top: widget.recenterTop,
          right: AppSpacing.l,
          child: Material(
            color: AppColors.surface,
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: AppColors.darkSurface.withOpacity(0.15),
            child: IconButton(
              tooltip: 'Recenter',
              onPressed: widget.onRecenter,
              icon: const Icon(
                Icons.my_location_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A graceful placeholder shown when Google Maps can't load.
class _MapPlaceholder extends StatelessWidget {
  final int markerCount;
  const _MapPlaceholder({this.markerCount = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.creamMuted,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text(
              'Map unavailable',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              kIsWeb
                  ? 'Enable Maps JavaScript API in\nGoogle Cloud Console'
                  : 'Could not load Google Maps',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (markerCount > 0) ...[
              const SizedBox(height: 8),
              const Text(
                'See results list below',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
