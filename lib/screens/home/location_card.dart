import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationCard extends StatefulWidget {
  @override
  _LocationCardState createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  // GoogleMapController to interact with the map
  GoogleMapController? mapController;

  // Set of markers, you can dynamically add or update them
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Initial marker setup
    _markers.add(
      Marker(
        markerId: const MarkerId('location'),
        position: const LatLng(6.3341, 80.8524), // Location coordinates
        infoWindow: const InfoWindow(title: 'Our Location'),
      ),
    );
  }

  // Function to move the camera programmatically
  void _moveCamera() {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: LatLng(6.3341, 80.8524), // Same location as the marker
          zoom: 15,
        ),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Column(
    children: [
      const Text(
        'Find Us On',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      const Text(
        'No. 50,\nMoraketiya Road,\nPallegama, Embilipitiya.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      SizedBox(
        height: 300,
        child: GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(6.3341, 80.8524),
            zoom: 15,
          ),
          markers: _markers, 
          onMapCreated: (GoogleMapController controller) {
            mapController = controller;
            print("Google Map Created");
          },
        ),
      ),
      ElevatedButton(
        onPressed: _moveCamera,
        child: const Text('Move Camera to Location'),
      ),
    ],
  );
}

}
