import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  // Başlangıç konumu (İstanbul koordinatları)
  final LatLng _center = const LatLng(41.0082, 28.9784);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haritadaki Fırsatlar', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF7A00),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 15.0,
        ),
        // Haritadaki kırmızı Pin'ler (İşletmelerimiz)
        markers: {
          const Marker(
            markerId: MarkerId('kahve_dunyasi'),
            position: LatLng(41.0082, 28.9784),
            infoWindow: InfoWindow(
              title: 'Kahve Dünyası',
              snippet: '%20 İndirim - Kahve Günü',
            ),
          ),
        },
      ),
    );
  }
}