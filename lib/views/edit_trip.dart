import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:travellog3/constants/constants.dart';
import 'package:travellog3/services/auth/auth_user.dart';
import 'package:travellog3/utilities/side_menu.dart';
import 'package:travellog3/utilities/travel_experience.dart';
import 'package:travellog3/views/mapview.dart';

class EditTrip extends StatefulWidget {
  final String tripId; // Unique identifier for the trip
  final Map<String, dynamic> tripDetails;

  const EditTrip({super.key, required this.tripId, required this.tripDetails});

  @override
  State<EditTrip> createState() => _EditTripState();
}

class _EditTripState extends State<EditTrip> {
  bool _isSaving = false;
  late TextEditingController descriptionController;
  late TextEditingController _placeController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;

  List<XFile>? _selectedImages = [];
  List<String> imageUrls = [];
  AuthUser user = AuthUser.fromFirebase(FirebaseAuth.instance.currentUser!);

  final Completer<GoogleMapController> _mapController = Completer();

  void removeImage(int index) {
    deleteImageFromStorage(imageUrls[index]);
    setState(() {
      imageUrls.removeAt(index);
    });
  }

  Future<void> saveTripDetails({
    required AuthUser user,
    required TravelExperience experience,
    required List<String> imageUrls,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('trips')
          .doc(widget.tripId)
          .update({
        'latitude': experience.latitude,
        'longitude': experience.longitude,
        'dateTime': experience.dateTime.toIso8601String(),
        'placeName': experience.placeName,
        'pictureUrls': imageUrls,
        'description': experience.description,
      });
    } catch (e) {
      // Handle error

      print("Error updating trip details: $e");
    }
  }

  // ignore: unused_element
  Future<void> _selectPictures() async {
    final List<XFile>? images = await ImagePicker().pickMultiImage();
    setState(() {
      _selectedImages = images ?? [];
    });
  }

  Future<void> deleteImageFromStorage(String imageUrl) async {
    try {
      final Reference storageRef =
          FirebaseStorage.instance.refFromURL(imageUrl);

      await storageRef.delete();

      print("Image deleted from Firebase Storage: $imageUrl");
    } catch (e) {
      print("Error deleting image from Firebase Storage: $e");
    }
  }

  @override
  void initState() {
    String placeName = widget.tripDetails['placeName'];
    String description = widget.tripDetails['description'];
    imageUrls = List<String>.from(widget.tripDetails['pictureUrls']) ?? [];
    DateTime tripDateTime = DateTime.parse(widget.tripDetails['dateTime']);

    String formattedDate = DateFormat('yyyy-MM-dd').format(tripDateTime);
    String formattedTime = DateFormat('HH:mm').format(tripDateTime);

    // Initialize controllers with trip data
    _placeController = TextEditingController(text: placeName);
    _dateController = TextEditingController(text: formattedDate);
    _timeController = TextEditingController(text: formattedTime);
    descriptionController = TextEditingController(text: description);
    super.initState();

    // // Initialize selected images with trip data
    // if (imageUrls != null && imageUrls.isNotEmpty) {
    //   _selectedImages = imageUrls.map<XFile>((url) => XFile(url)).toList();
    // } else {
    //   // Handle the case where there are no pictures
    //   _selectedImages = [];
    // }
  }

  @override
  void dispose() {
    _placeController.dispose();

    _dateController.dispose();

    _timeController.dispose();

    descriptionController.dispose();

    super.dispose();
  }

  Widget createImageItem(dynamic imageData) {
    if (imageData is String) {
      // Existing image (URL)

      return Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromARGB(
                        255, 202, 138, 234), // Greyish border color

                    width: 0.5, // Border width
                  ),
                ),
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: CachedNetworkImage(
                    imageUrl: imageData,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 5.0,
            right: 5.0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                int index = imageUrls.indexOf(imageData);

                if (index != -1) {
                  removeImage(index);
                }
              },
            ),
          ),
        ],
      );
    } else {
      // Newly selected image (XFile)

      return Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.file(
                File(imageData.path),
                fit: BoxFit.cover,
                height: double.infinity,
              ),
            ),
          ),
          Positioned(
            top: 5.0,
            right: 5.0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                setState(() {
                  _selectedImages!.remove(imageData);
                });
              },
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Details"),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isSaving
              ? _buildProgressDialog()
              : Column(
                  children: [
                    // ignore: sized_box_for_whitespace
                    Container(
                      height: MediaQuery.of(context).size.height *
                          0.25, // 1/4 of the screen height
                      width: double.infinity,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            widget.tripDetails['latitude'] ??
                                24.937022621795442,
                            widget.tripDetails['longitude'] ??
                                67.03132710941534,
                          ),
                          zoom: 14,
                        ),
                        onMapCreated: (GoogleMapController controller) {
                          _mapController.complete(controller);
                        },
                        markers: {
                          Marker(
                            markerId: const MarkerId('selectedPlaceMarker'),
                            position: LatLng(
                              widget.tripDetails['latitude'] ??
                                  24.937022621795442,
                              widget.tripDetails['longitude'] ??
                                  67.03132710941534,
                            ),
                          ),
                        },
                        myLocationButtonEnabled: false,
                        myLocationEnabled: false,
                        onTap: (LatLng position) {
                          print("Map clicked");
                          // ignore: avoid_print
                          Navigator.of(context)
                              .push(
                            MaterialPageRoute(
                              builder: (context) => MapView(
                                initialPlace: _placeController.text,
                                latitude: position.latitude,
                                longitude: position.longitude,
                                fromEditTrip:
                                    true, // Indicate that we came from EditTripView
                              ),
                            ),
                          )
                              .then((result) {
                            if (result != null) {
                              setState(() {
                                // Update the trip details with the new values
                                _placeController.text = result['placeName'];
                               
                              });
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Row(
                      children: [
                        const Text(
                          "Place Name",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _placeController,
                            maxLines: null,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Row(
                      children: [
                        const Text(
                          "Date",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _dateController,
                            maxLines: null,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        const Text(
                          "Time",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _timeController,
                            maxLines: null,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        const Text(
                          "Description ",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: TextField(
                            controller: descriptionController,
                            maxLines: null,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    // Button to add pictures
                    ElevatedButton(
                      onPressed: _selectPictures,
                      child: const Text('Add Pictures'),
                    ),
                    const SizedBox(height: 20),
                    if (imageUrls.isNotEmpty || _selectedImages!.isNotEmpty)
                      CarouselSlider(
                        options: CarouselOptions(
                          aspectRatio: 16 / 9,
                          enableInfiniteScroll: false,
                          viewportFraction: 0.5,
                          enlargeCenterPage: true,
                          initialPage: 0,
                          autoPlay: false,
                          height: 200,
                        ),
                        items: [
                          ...imageUrls.map((url) => createImageItem(url)),
                          ..._selectedImages!
                              .map((image) => createImageItem(image)),
                        ],
                      ),

                    //  if (imageUrls.isNotEmpty || _selectedImages!.isNotEmpty)
                    //   CarouselSlider(
                    //     options: CarouselOptions(
                    //       aspectRatio: 16 / 9,
                    //       enableInfiniteScroll: false,
                    //       viewportFraction: 0.5,
                    //       enlargeCenterPage: true,
                    //       initialPage: 0,
                    //       autoPlay: false,
                    //       height: 200,
                    //     ),
                    //     items: imageUrls.map((url) {
                    //       return Stack(children: [
                    //         Container(
                    //           width: double.infinity,
                    //           decoration: BoxDecoration(
                    //             color: Colors.grey,
                    //             borderRadius: BorderRadius.circular(8.0),
                    //           ),
                    //           child: ClipRRect(
                    //             borderRadius: BorderRadius.circular(8.0),
                    //             child: Container(
                    //               decoration: BoxDecoration(
                    //                 border: Border.all(
                    //                   color: const Color.fromARGB(
                    //                       255, 202, 138, 234), // Greyish border color
                    //                   width: 0.5, // Border width
                    //                 ),
                    //               ),
                    //               child: AspectRatio(
                    //                 aspectRatio: 1.5,
                    //                 child: CachedNetworkImage(
                    //                   imageUrl: url,
                    //                   fit: BoxFit.cover,
                    //                 //  height: double.infinity,
                    //                   placeholder: (context, url) => const Center(
                    //                     child: SizedBox(
                    //                       width: 30,
                    //                       height: 30,
                    //                       child: CircularProgressIndicator(
                    //                         strokeWidth: 2.0,
                    //                       ),
                    //                     ),
                    //                   ),
                    //                   errorWidget: (context, url, error) =>
                    //                       const Icon(Icons.error),
                    //                 ),
                    //               ),
                    //             ),
                    //           ),
                    //         ),
                    //         Positioned(
                    //           top: 5.0,
                    //           right: 5.0,
                    //           child: IconButton(
                    //             icon: const Icon(Icons.close, color: Colors.red),
                    //             onPressed: () {
                    //               int index = imageUrls.indexOf(url);
                    //               if (index != -1) {
                    //                 removeImage(index);
                    //               }
                    //             },
                    //           ),
                    //         ),
                    //       ]);
                    //     }).toList(),
                    //   ),
                    // const SizedBox(height: 20),

                    // if (_selectedImages != null && _selectedImages!.isNotEmpty)
                    //   CarouselSlider(
                    //     options: CarouselOptions(
                    //       aspectRatio: 16 / 9,
                    //       enableInfiniteScroll: false,
                    //       viewportFraction: 0.5,
                    //       enlargeCenterPage: true,
                    //       initialPage: 0,
                    //       autoPlay: false,
                    //       height: 200,
                    //     ),
                    //     items: _selectedImages!.map((image) {
                    //       return Stack(children: [
                    //         Container(
                    //           width: double.infinity,
                    //           decoration: BoxDecoration(
                    //             color: Colors.grey,
                    //             borderRadius: BorderRadius.circular(8.0),
                    //           ),
                    //           child: ClipRRect(
                    //             borderRadius: BorderRadius.circular(8.0),
                    //             child: Image.file(
                    //               File(image.path),
                    //               fit: BoxFit.cover,
                    //               height: double.infinity,
                    //             ),
                    //           ),
                    //         ),
                    //         Positioned(
                    //           top: 5.0,
                    //           right: 5.0,
                    //           child: IconButton(
                    //             icon: const Icon(Icons.close, color: Colors.red),
                    //             onPressed: () {
                    //               setState(() {
                    //                 _selectedImages!.remove(image);
                    //               });
                    //             },
                    //           ),
                    //         ),
                    //       ]);
                    //     }).toList(),
                    //   ),

                    const SizedBox(height: 70),
                    const SizedBox(height: 10),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            setState(() {
              _isSaving = true; // Set to true before saving
            });
            if (_selectedImages != null && _selectedImages!.isNotEmpty) {
              List<String> newImageUrls = await uploadImages(_selectedImages!);

              imageUrls.addAll(newImageUrls);
            }

            TravelExperience updatedExperience = TravelExperience(
              latitude: widget.tripDetails['latitude'],
              longitude: widget.tripDetails['longitude'],
              dateTime: DateTime.parse(
                  "${_dateController.text} ${_timeController.text}"),
              placeName: _placeController.text,
              description: descriptionController.text,
              pictureUrls: imageUrls,
            );

            await saveTripDetails(
              user: user,
              experience: updatedExperience,
              imageUrls: imageUrls,
            );

            Navigator.pushReplacementNamed(context, '/tripsview/');
            setState(() {
              _isSaving = false; // Set to false after saving
            });
          },
          backgroundColor: const Color.fromARGB(255, 202, 138, 234),
          child: const Text("Save")),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

Future<List<String>> uploadImages(List<XFile> selectedImages) async {
  List<String> downloadUrls = [];
  for (XFile image in selectedImages) {
    try {
      final String fileName = image.name;

      final Reference storageRef =
          FirebaseStorage.instance.ref().child('$storagePath$fileName');

      UploadTask uploadTask = storageRef.putFile(File(image.path));

      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();

      downloadUrls.add(downloadUrl);
    } catch (e) {
      // Handle upload error

      print("Error uploading image: $e");
    }
  }

  return downloadUrls;
}

Widget _buildProgressDialog() {
  return Center(
    child: Container(
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.all(16.0), // Add padding for spacing
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
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
