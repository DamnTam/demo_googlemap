import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  LocationData? currentLocation;
  Location location = Location();
  List<LatLng> polylineCoordinates = [];
  late StreamSubscription locationSubscription;
  LatLng ? previousLocation;
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(23.6850, 90.3563),
    zoom: 13.0,
  );

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  Future<void> requestPermission() async {
    await location.requestPermission().then((granted) {
      if (granted == PermissionStatus.granted) {
        locationSubscription = location.onLocationChanged.listen((LocationData onChangeLocation) {
          log(onChangeLocation.latitude.toString());
          log(onChangeLocation.longitude.toString());

          currentLocation = onChangeLocation;
          updatePolyline();
          animateCamera(zoom: 19.5);
          ///fetch the user current location every 10 seconds
          locationSubscription.pause(Future.delayed(const Duration(seconds: 10))
              .then((value) => locationSubscription.resume()));
          setState(() {});
        });
      }
    });
  }

  void animateCamera({required double zoom}) {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
              double.parse(currentLocation?.latitude.toString() ?? '0.0'),
              double.parse(currentLocation?.longitude.toString() ?? '0.0')),
          zoom: zoom,
        ),
      ),
    );
  }

  void updatePolyline() {
    if (polylineCoordinates.isNotEmpty) {
       previousLocation = polylineCoordinates.last;
      log('previousLocation: $previousLocation');
      LatLng currentLatLng = LatLng(
          double.parse(currentLocation?.latitude.toString() ?? '0.0'),
          double.parse(currentLocation?.longitude.toString() ?? '0.0'));
      if (previousLocation != currentLatLng) {
        setState(() {
          polylineCoordinates.add(currentLatLng);
        });
      }
    }
    else {
      // First time adding current location to polylineCoordinates
      polylineCoordinates.add(LatLng(
          double.parse(currentLocation?.latitude.toString() ?? '0.0'),
          double.parse(currentLocation?.longitude.toString() ?? '0.0')));
      setState(() {});
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    locationSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          elevation: 5,
          title: const Text('Flutter Map App'),
        ),
        body: currentLocation == null
            ? const Center(
                child: CircularProgressIndicator(color: Colors.black,),
              )
            : Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      setState(() {
                        mapController = controller;
                      });
                    },
                    zoomControlsEnabled: false,
                    initialCameraPosition: _initialCameraPosition,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    markers: {
                      Marker(
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        markerId: const MarkerId('MyLocation'),
                        position: LatLng(currentLocation!.latitude!.toDouble(),
                            currentLocation!.longitude!.toDouble()),
                        onTap: () {
                          // Show info window when marker is tapped
                          mapController.showMarkerInfoWindow(const MarkerId('MyLocation'));
                        },
                        infoWindow: InfoWindow(
                          title: 'My current location',
                          snippet:
                              'Lat: ${currentLocation!.latitude}, Lng: ${currentLocation!.longitude}',
                        ),
                      ),

                    },
                    polylines: {
                      Polyline(
                        color: Colors.black,
                        polylineId: const PolylineId('Polyline'),
                        points: polylineCoordinates,

                      ),
                    },
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (currentLocation != null) {
            animateCamera(zoom: 17);
          }
        },
        child: const Icon(Icons.center_focus_strong),
      ),
        );
  }
}
