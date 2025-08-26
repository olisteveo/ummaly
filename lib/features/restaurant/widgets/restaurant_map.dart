import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ummaly/theme/styles.dart';

class RestaurantMap extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: initialCamera,
            markers: markers,
            myLocationEnabled: myLocationEnabled,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            tiltGesturesEnabled: false,
            rotateGesturesEnabled: true,
            zoomGesturesEnabled: true,
            mapType: mapType,

            // <- important
            padding: padding,

            onMapCreated: onMapCreated,
          ),
        ),
        Positioned(
          top: recenterTop,
          right: AppSpacing.l,
          child: Material(
            color: AppColors.surface,
            shape: const CircleBorder(),
            elevation: 2,
            child: IconButton(
              tooltip: 'Recenter',
              onPressed: onRecenter,
              icon: const Icon(Icons.center_focus_strong),
            ),
          ),
        ),
      ],
    );
  }
}
