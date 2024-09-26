import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:travellog3/services/auth/auth_service.dart';
import 'package:travellog3/utilities/app_links.dart';

class SummaryView extends StatefulWidget {
  const SummaryView({super.key});

  @override
  State<SummaryView> createState() => _SummaryViewState();
}

class _SummaryViewState extends State<SummaryView> {
  List<Map<String, dynamic>> trips = [];
  final Set<Polyline> _polylines = {};

  bool isLoading = true;
  late BuildContext scaffoldContext;

  String maptheme = '';
  final Completer<GoogleMapController> _controller = Completer();
  CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();
  Position? position;
  late LatLng currentLatLng;
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(24.937022621795442, 67.03132710941534),
    zoom: 10,
  );
  final List<Marker> _markers = <Marker>[];

  Future<void> fetchUserTrips() async {
    final user = AuthService.firebase().currentUser;
    if (user != null) {
      String userId = user.id!;
      List<Map<String, dynamic>> userTrips =
          await fetchTripsFromFirestore(userId);
      setState(() {
        trips = userTrips;
        isLoading = false;
        addTripMarkers();
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchTripsFromFirestore(
      String userId) async {
    List<Map<String, dynamic>> userTrips = [];
    try {
      CollectionReference tripsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('trips');

      QuerySnapshot querySnapshot =
          await tripsCollection.orderBy('dateTime', descending: true).get();
      for (var doc in querySnapshot.docs) {
        if (doc.exists) {
          Map<String, dynamic> tripData = {
            'id': doc.id,
            'description': doc['description'],
            'latitude': doc['latitude'],
            'longitude': doc['longitude'],
            'placeName': doc['placeName'],
            'pictureUrls': List<String>.from(doc['pictureUrls'] ?? []),
            'dateTime': doc['dateTime'], // Assuming you have a visitedAt field
          };
          userTrips.add(tripData);
        }
      }
    } catch (e) {
      // Log the error
      print("Error fetching trips: $e");
    }
    return userTrips;
  }

  @override
  void initState() {
    super.initState();
    fetchUserTrips();
    DefaultAssetBundle.of(context)
        .loadString('assets/maptheme/standard_theme.json')
        .then((value) {
      maptheme = value;
    });
    addTripMarkers();
  }

  void addTripMarkers() async {
    // Load the custom marker image
    final BitmapDescriptor customMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(
        size: Size(30, 30),
      ),
      'assets/images/placeholder.png',
    );
    List<LatLng> polylinePoints = [];
    setState(() {
      _markers.clear(); // Clear existing markers to avoid duplicates
      _polylines.clear(); // Clear existing polylines to avoid duplicates

      for (var trip in trips) {
        String imageUrl = '';
        String formattedDate = '';
        String formattedTime = '';
        if (trip['dateTime'] != null) {
          try {
            DateTime tripDateTime = DateTime.parse(trip['dateTime']);
            formattedDate = DateFormat('yyyy-MM-dd').format(tripDateTime);
            formattedTime = DateFormat('HH:mm').format(tripDateTime);
          } catch (e) {
            print("Error parsing dateTime: $e");
          }
        }
        print("trip Date and Time not accessed !!!!!!!!!!!!");
        if (trip['pictureUrls'].isNotEmpty) {
          imageUrl = trip['pictureUrls'][0];
        }
        final marker = Marker(
          markerId: MarkerId(trip['id']),
          position: LatLng(trip['latitude'], trip['longitude']),
          icon: customMarker,
          onTap: () {
            _customInfoWindowController.addInfoWindow!(
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 221, 220, 221),
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            trip['placeName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            trip['description'],
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Visited at: $formattedDate $formattedTime ",
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Container(
                            width: 200,
                            height: 100,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8.0),
                              ),
                            ),
                            child: imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.fitWidth,
                                      filterQuality: FilterQuality.high,
                                      placeholder: (context, url) =>
                                          const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                LatLng(trip['latitude'], trip['longitude']));
          },
        );
        _markers.add(marker);
        polylinePoints.add(LatLng(trip['latitude'], trip['longitude']));
      }

      if (polylinePoints.isNotEmpty) {
        PolylineId polylineId = const PolylineId('trips_line');
        Polyline polyline = Polyline(
          polylineId: polylineId,
          points: polylinePoints,
          width: 3, // Adjust width as needed
          color: const Color.fromARGB(255, 202, 138, 234),
          patterns: [
            PatternItem.dot,
          ],
          jointType: JointType.bevel,
          startCap: Cap.roundCap,
          endCap: Cap.squareCap,
          // Adjust color as needed
        );

        _polylines.add(polyline);
      }

      if (_markers.isNotEmpty) {
        LatLngBounds bounds = calculateBounds(_markers);
        _controller.future.then((controller) {
          controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
        });
      }
    });
  }

  LatLngBounds calculateBounds(List<Marker> markers) {
    double? minLat, maxLat, minLng, maxLng;

    for (var marker in markers) {
      if (minLat == null || marker.position.latitude < minLat) {
        minLat = marker.position.latitude;
      }
      if (maxLat == null || marker.position.latitude > maxLat) {
        maxLat = marker.position.latitude;
      }
      if (minLng == null || marker.position.longitude < minLng) {
        minLng = marker.position.longitude;
      }
      if (maxLng == null || marker.position.longitude > maxLng) {
        maxLng = marker.position.longitude;
      }
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  @override
  void dispose() {
    _customInfoWindowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Builder(builder: (context) {
          scaffoldContext = context;
          return Stack(
            children: [
              GoogleMap(
                polylines: _polylines,
                markers: Set<Marker>.of(_markers),
                initialCameraPosition: _kGooglePlex,
                compassEnabled: true,
                myLocationEnabled: true,
                zoomGesturesEnabled: true,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                onMapCreated: (GoogleMapController controller) async {
                  controller.setMapStyle(maptheme);
                  _controller.complete(controller);
                  _customInfoWindowController.googleMapController = controller;
                },
                gestureRecognizers: {
                  Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                  Factory<ScaleGestureRecognizer>(
                      () => ScaleGestureRecognizer()),
                },
                onTap: (_) {
                  print("map tapped");
                  _customInfoWindowController.hideInfoWindow!();
                },
              ),
              CustomInfoWindow(
                controller: _customInfoWindowController,
                height: 200,
                width: 200,
                offset: 35,
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
                          //       offset: const Offset(0, 3),
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
                bottom: 10,
                left: 16,
                right: 16,
                child: MaterialButton(
                  height: 45,
                  color: const Color.fromARGB(255, 202, 138, 234),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      color: Color.fromARGB(255, 202, 138, 234),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onPressed: () async {
                    // Use the new AppLinkProvider to create the link
                    String link = AppLinkProvider().createMapSummaryLink();
                    print("Sharing Map Summary Link: $link");

                    // Share the link using the Share package
                    Share.share(' $link');
                  },
                  child: const Text(
                    'Share',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              )
            ],
          );
        }),
      ),
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
