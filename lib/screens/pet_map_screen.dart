import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class PetMapScreen extends StatefulWidget {
  final String petId;
  final String petName;

  const PetMapScreen({Key? key, required this.petId, required this.petName}) : super(key: key);

  @override
  _PetMapScreenState createState() => _PetMapScreenState();
}

class _PetMapScreenState extends State<PetMapScreen> {
  final ApiService _apiService = ApiService();
  GoogleMapController? _mapController;
  Timer? _refreshTimer;
  Marker? _petMarker;
  
  // Default start location (e.g., your city, you can change this)
  final LatLng _initialCameraPosition = const LatLng(12.9716, 77.5946); 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndUpdateMap(); // Get first location immediately
    
    // Start a timer to auto-refresh the location every 10 seconds
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      print("Auto-refreshing pet location...");
      _fetchLocationAndUpdateMap();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Stop the timer when the screen is closed
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchLocationAndUpdateMap() async {
    try {
      final locationData = await _apiService.getLatestLocation(widget.petId);
      
      if (!mounted) return; // Check if the widget is still on screen

      if (locationData == null) {
        print("No location data found for this pet yet.");
        setState(() { _isLoading = false; }); // Stop loading, show default map
        return;
      }

      final newPosition = LatLng(locationData['latitude'], locationData['longitude']);
      final timestamp = DateTime.parse(locationData['timestamp']);
      final formattedTime = DateFormat.jms().format(timestamp.toLocal());

      setState(() {
        _isLoading = false;
        _petMarker = Marker(
          markerId: MarkerId(widget.petId),
          position: newPosition,
          infoWindow: InfoWindow(
            title: widget.petName,
            snippet: "Last update: $formattedTime",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );
      });

      // Animate camera to the new pet position
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPosition, 16.0));
      
    } catch (e) {
      print("Error fetching location: $e");
      if(mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.petName}'s Location"),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _initialCameraPosition,
              zoom: 14,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            markers: _petMarker != null ? {_petMarker!} : {}, // Show the pet marker
          ),
          if (_isLoading)
            Center(child: CircularProgressIndicator()),
          
          if (!_isLoading && _petMarker == null)
             Center(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Text(
                  "Waiting for first GPS signal from collar...",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}