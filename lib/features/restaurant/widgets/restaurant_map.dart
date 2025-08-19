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

  const RestaurantMap({
    super.key,
    required this.initialCamera,
    required this.markers,
    required this.onMapCreated,
    this.myLocationEnabled = true,
    required this.onRecenter,
    this.recenterTop = 140,
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
