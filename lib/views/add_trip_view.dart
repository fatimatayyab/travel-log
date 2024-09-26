import 'dart:async';
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travellog3/constants/constants.dart';
import 'package:travellog3/services/auth/auth_user.dart';
import 'package:travellog3/utilities/side_menu.dart';
import 'package:travellog3/utilities/travel_experience.dart';

class AddTrip extends StatefulWidget {
  final String? placeName;
  final double? latitude;
  final double? longitude;
  const AddTrip({super.key, this.placeName, this.latitude, this.longitude});

  @override
  State<AddTrip> createState() => _AddTripState();
}

class _AddTripState extends State<AddTrip> {
  bool _isSaving = false;
  late TextEditingController descriptionController;
  late TextEditingController _placeController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late String currentDate;
  late String currentTime;
  List<XFile>? _selectedImages;
  AuthUser user = AuthUser.fromFirebase(FirebaseAuth.instance.currentUser!);

  final Completer<GoogleMapController> _mapController = Completer();

  void removeImage(int index) {
    setState(() {
      _selectedImages?.removeAt(index);
    });
  }

  Future<void> saveTripDetails({
    required AuthUser user,
    required TravelExperience experience,
    required List<String> imageUrls,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .collection('trips')
        .add({
      'latitude': experience.latitude,
      'longitude': experience.longitude,
      'dateTime': experience.dateTime.toIso8601String(),
      'placeName': experience.placeName,
      'pictureUrls': imageUrls,
      'description': experience.description,
      'isFavourite': false,
      // Add other fields as needed
    });
  }

  Future<void> _selectPictures() async {
    final List<XFile>? images = await ImagePicker().pickMultiImage();
    setState(() {
      _selectedImages = images;
    });
  }

  @override
  void initState() {
    _placeController = TextEditingController(text: widget.placeName ?? "");
    currentDate = DateTime.now().toLocal().toString().split(' ')[0];
    _dateController = TextEditingController(text: currentDate);
    currentTime =
        DateTime.now().toLocal().toString().split(' ')[1].substring(0, 5);
    _timeController = TextEditingController(text: currentTime);
    descriptionController = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    _placeController.dispose();

    _dateController.dispose();

    _timeController.dispose();

    descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 221, 220, 221),
        title: const Text(
          "Trip Details",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
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
      body: Container(
        color: Color.fromARGB(255, 238, 235, 238),
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isSaving
                    ? _buildProgressDialog()
                    : Column(
                        children: [
                          // ignore: sized_box_for_whitespace
                          Container(
                            height: 250, // 1/4 of the screen height
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),

                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(
                                      widget.latitude ?? 24.937022621795442,
                                      widget.longitude ?? 67.03132710941534),
                                  zoom: 14,
                                ),
                                onMapCreated: (GoogleMapController controller) {
                                  _mapController.complete(controller);
                                },
                                markers: {
                                  Marker(
                                    markerId:
                                        const MarkerId('selectedPlaceMarker'),
                                    position: LatLng(
                                        widget.latitude ?? 24.937022621795442,
                                        widget.longitude ?? 67.03132710941534),
                                  ),
                                },
                                myLocationButtonEnabled: false,
                                myLocationEnabled: false,
                                onTap: (LatLng position) {
                                  // ignore: avoid_print
                                  print("Map clicked");
                                  Navigator.of(context).pushNamed('/mapview/');
                                },
                                mapType:
                                    MapType.normal, // Adjust map type as needed
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          buildInputField(
                            label: "Place Name",
                            controller: _placeController,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: buildInputField(
                                  label: "Date",
                                  controller: _dateController,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: buildInputField(
                                  label: "Time",
                                  controller: _timeController,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          buildInputField(
                            label: "Description",
                            controller: descriptionController,
                            maxLines: 5,
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          // Button to add pictures
                          // Add Pictures Button with icon
                          ElevatedButton.icon(
                            onPressed: _selectPictures,
                            icon: Icon(Icons.add_a_photo),
                            label: Text('Add Pictures'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor:
                                  Color.fromARGB(255, 202, 138, 234),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Carousel Slider for selected images
                          if (_selectedImages != null &&
                              _selectedImages!.isNotEmpty)
                            CarouselSlider(
                              options: CarouselOptions(
                                aspectRatio: 16 / 9,
                                enableInfiniteScroll: false,
                                viewportFraction: 0.8,
                                enlargeCenterPage: true,
                                initialPage: 0,
                                autoPlay: false,
                                height: 200,
                              ),
                              items: _selectedImages!.map((image) {
                                return Stack(children: [
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(12.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 2,
                                          blurRadius: 6,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.file(
                                        File(image.path),
                                        fit: BoxFit.cover,
                                        height: double.infinity,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8.0,
                                    right: 8.0,
                                    child: IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.red),
                                      onPressed: () => removeImage(
                                          _selectedImages!.indexOf(image)),
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          setState(() {
            _isSaving = true; // Set to true before saving
          });
          List<String> imageUrls = await uploadImages(_selectedImages ?? []);
          TravelExperience experience = TravelExperience(
            latitude: widget.latitude ?? 0.0,
            longitude: widget.longitude ?? 0.0,
            dateTime: DateTime
                .now(), // You might want to use the date and time from the text fields
            placeName: _placeController.text,
            pictureUrls:
                imageUrls, // Assuming you want to save only one picture URL
            description: descriptionController.text,
          );
          saveTripDetails(
            user:
                user, // Replace with actual trip ID or generate one dynamically
            experience: experience,
            imageUrls: imageUrls,
          );
          Navigator.of(context).pushNamed('/tripsview/');
          setState(() {
            _isSaving = false; // Set to false after saving
          });
        },
        backgroundColor: Color.fromARGB(255, 202, 138, 234),
        label: Text('Save'),
        icon: Icon(Icons.save),
        // Customize background color
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        heroTag: 'saveFab',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<List<String>> uploadImages(List<XFile> images) async {
    List<String> imageUrls = [];

    for (var image in images) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('$storagePath$fileName');
      firebase_storage.UploadTask uploadTask = ref.putFile(File(image.path));
      firebase_storage.TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }

    return imageUrls;
  }
}

Widget _buildProgressDialog() {
  return Center(
    child: Container(
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.all(16.0), // Add padding for spacing
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color.fromARGB(255, 202, 138, 234),
            ),
          ),
          SizedBox(height: 16.0),
          Text(
            'Saving trip...',
            style: TextStyle(color: Color.fromRGBO(97, 97, 97, 1)),
          ),
        ],
      ),
    ),
  );
}

Widget buildInputField({
  required String label,
  required TextEditingController controller,
  int maxLines = 1,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Colors.grey[900],
        ),
      ),
      const SizedBox(height: 4),
      Container(
        height: 45, // Explicit height control
        child: TextFormField(
          controller: controller,
          maxLines: 1,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: const Color.fromARGB(255, 160, 155, 155)!),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Color.fromARGB(255, 202, 138, 234),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
