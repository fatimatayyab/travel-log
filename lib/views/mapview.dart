import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travellog3/utilities/side_menu.dart';
import 'package:travellog3/views/add_trip_view.dart';

class MapView extends StatefulWidget {
  final String? initialPlace;
  final double? latitude;
  final double? longitude;
  final bool fromEditTrip;
  const MapView(
      {Key? key,
      this.initialPlace,
      this.latitude,
      this.longitude,
      this.fromEditTrip = false})
      : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late BuildContext scaffoldContext;
  late final TextEditingController searchPlace;
  String maptheme = '';
  final Completer<GoogleMapController> _controller = Completer();
  Position? position;
  late LatLng currentLatLng;
  static CameraPosition _kGooglePlex = const CameraPosition(
    target: LatLng(24.937022621795442, 67.03132710941534),
    zoom: 14,
  );
  late Marker _marker = Marker(
    markerId: MarkerId('initialMarker'),
    position: _kGooglePlex.target,
  );
  @override
  void initState() {
    super.initState();
    searchPlace = TextEditingController();
    DefaultAssetBundle.of(context)
        .loadString('assets/maptheme/standard_theme.json')
        .then((value) {
      maptheme = value;
    });
    addMarker(false);
  }

  Future<void> addMarker(bool fab) async {
    // Request location permission
    await Geolocator.requestPermission();

    // Check if location permission is granted
    bool isLocationPermissionGranted =
        await Geolocator.isLocationServiceEnabled();

    if (widget.initialPlace != null && !fab) {
      searchPlace.text = widget.initialPlace!;

      currentLatLng = LatLng(widget.latitude ?? 24.937022621795442,
          widget.longitude ?? 67.03132710941534);
    } else if (!isLocationPermissionGranted) {
      // Location permission is not granted, handle it gracefully
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Location permission denied. Defaulting to default location.'),
      ));
      currentLatLng = const LatLng(
          24.937022621795442, 67.03132710941534); // Set default location
    } else {
      // Location permission is granted, fetch the user's current position
      Position positionOfUser = await Geolocator.getCurrentPosition();
      LatLng latLng = LatLng(positionOfUser.latitude, positionOfUser.longitude);
      currentLatLng = latLng;
    }
    String placeName = await getPlaceNameFromCoordinates(currentLatLng);
    setState(() {
      searchPlace.text = placeName;
      _marker = Marker(
        markerId: const MarkerId('currentLocation'),
        position: currentLatLng,
        infoWindow: const InfoWindow(title: 'Current Location'),
        draggable: true,
        onDragEnd: (newPosition) async {
          currentLatLng = newPosition;

          String newPlaceName = await getPlaceNameFromCoordinates(newPosition);

          setState(() {
            _marker = _marker.copyWith(
              positionParam: newPosition,
            );
            searchPlace.text = newPlaceName;
          });
        },
        onDrag: (newPosition) async {
          // Update camera position while dragging
          final GoogleMapController controller = await _controller.future;
          controller.animateCamera(CameraUpdate.newLatLng(newPosition));
        },
      );
    });
    CameraPosition cameraPosition =
        CameraPosition(target: currentLatLng, zoom: 14);
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: const MyDrawer(),
      body: SafeArea(
        child: Builder(builder: (context) {
          scaffoldContext = context;
          return Stack(
            children: [
              GoogleMap(
                markers: {_marker}.toSet(),
                initialCameraPosition: _kGooglePlex,
                compassEnabled: true,
                myLocationEnabled: true,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                onMapCreated: (GoogleMapController controller) async {
                  controller.setMapStyle(maptheme);
                  _controller.complete(controller);
                },
              ),
              Positioned(
                bottom: 140, // Adjust bottom padding as needed
                right: 20,
                // Adjust right padding as needed
                child: Container(
                  width: 52,
                  decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 202, 138, 234),
                      borderRadius: BorderRadius.circular(15.0)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () async {
                          GoogleMapController controller =
                              await _controller.future;
                          controller.animateCamera(
                            CameraUpdate.zoomIn(),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          // decoration: BoxDecoration(
                          //   boxShadow: [
                          //     BoxShadow(
                          //       color: Colors.black.withOpacity(0.2),
                          //       spreadRadius: 2,
                          //       blurRadius: 6,
                          //       offset: Offset(0, 3),
                          //     ),
                          //   ],
                          // ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          GoogleMapController controller =
                              await _controller.future;
                          controller.animateCamera(
                            CameraUpdate.zoomOut(),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          // decoration: BoxDecoration(
                          //   boxShadow: [
                          //     BoxShadow(
                          //       color: Colors.black.withOpacity(0.2),
                          //       spreadRadius: 2,
                          //       blurRadius: 6,
                          //       offset: const Offset(0, 3),
                          //     ),
                          //   ],
                          // ),
                          child: const Icon(
                            Icons.remove,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10.0,
                left: 16.0,
                right: 8.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Stack(
                    children: [
                      TextField(
                        onTap: () {
                          bool edityesorno = widget.fromEditTrip;
                          print("$edityesorno");
                          Navigator.of(context)
                              .pushNamed(
                            '/searchplaces/',
                            arguments: widget.fromEditTrip,
                          )
                              .then((_) {
                            // Code to execute after returning from SearchPlaces
                            addMarker(false);
                          });
                        },
                        controller: searchPlace,
                        cursorColor: Colors.white,
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            size: 30,
                          ),
                          prefixIconColor: Color.fromARGB(255, 202, 138, 234),

                          hintText: '  Search here',

                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 15.0),
                          // filled: true,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Colors.black,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(255, 202, 138, 234),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8.0, // Adjust the position as needed
                        top: 4.0,
                        child: PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          iconSize: 30,
                          iconColor: const Color.fromARGB(255, 202, 138, 234),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              onTap: () {
                                _controller.future.then(
                                  (value) {
                                    DefaultAssetBundle.of(context)
                                        .loadString(
                                            'assets/maptheme/silver_theme.json')
                                        .then((string) {
                                      value.setMapStyle(string);
                                    });
                                  },
                                );
                              },
                              child: const Text(
                                'silver',
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () {
                                _controller.future.then(
                                  (value) {
                                    DefaultAssetBundle.of(context)
                                        .loadString(
                                            'assets/maptheme/retro_theme.json')
                                        .then((string) {
                                      value.setMapStyle(string);
                                    });
                                  },
                                );
                              },
                              child: const Text(
                                'Retro',
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () {
                                _controller.future.then(
                                  (value) {
                                    DefaultAssetBundle.of(context)
                                        .loadString(
                                            'assets/maptheme/night_theme.json')
                                        .then((string) {
                                      value.setMapStyle(string);
                                    });
                                  },
                                );
                              },
                              child: const Text(
                                'Night',
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () {
                                _controller.future.then(
                                  (value) {
                                    DefaultAssetBundle.of(context)
                                        .loadString(
                                            'assets/maptheme/standard_theme.json')
                                        .then((string) {
                                      value.setMapStyle(string);
                                    });
                                  },
                                );
                              },
                              child: const Text(
                                'normal',
                              ),
                            ),
                          ],
                          offset: Offset(0, 40),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 16,
                right: 16,
                child: MaterialButton(
                  height: 45,
                  color: Color.fromARGB(255, 202, 138, 234),
                  highlightColor: Color.fromARGB(255, 160, 100, 190),
                  splashColor: Color.fromARGB(255, 160, 100, 190),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      color: Color.fromARGB(255, 202, 138, 234),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onPressed: () async {
                    String placeName =
                        await getPlaceNameFromCoordinates(currentLatLng);
                    if (widget.fromEditTrip) {
                      // If opened from EditTripView, return to it
                      Navigator.of(context).pop({
                        'placeName': placeName,
                        'latitude': currentLatLng.latitude,
                        'longitude': currentLatLng.longitude,
                      });
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddTrip(
                            placeName: placeName,
                            latitude: currentLatLng.latitude,
                            longitude: currentLatLng.longitude,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50.0),
        child: FloatingActionButton(
          backgroundColor: const Color.fromARGB(255, 202, 138, 234),
          child: const Icon(
            Icons.location_searching_sharp,
            color: Colors.white,
          ),
          onPressed: () {
            addMarker(true);
          },
          elevation: 6.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

Future<String> getPlaceNameFromCoordinates(LatLng position) async {
  List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);
  if (placemarks.isNotEmpty) {
    Placemark placemark = placemarks.first;
    return "${placemark.name}, ${placemark.locality}, ${placemark.country}";
  } else {
    return "Unknown place";
  }
}
