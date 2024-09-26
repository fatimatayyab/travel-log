import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:travellog3/services/auth/auth_service.dart';
import 'package:travellog3/utilities/delete_dialog.dart';
import 'package:travellog3/utilities/share_button.dart';

import 'package:travellog3/views/edit_trip.dart';
import 'package:travellog3/views/summary_view.dart';
import 'package:travellog3/views/trip_details.dart';
import 'package:travellog3/utilities/side_menu.dart';

class TripsView extends StatefulWidget {
  const TripsView({super.key});

  @override
  State<TripsView> createState() => _TripsViewState();
}

class _TripsViewState extends State<TripsView> {
  bool isDeleting = false;
  static const double backgroundOpacity = 0.9;
  List<Map<String, dynamic>> trips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserTrips();
  }

  Future<void> fetchUserTrips() async {
    final user = AuthService.firebase().currentUser;
    if (user != null) {
      String userId = user.id!;
      List<Map<String, dynamic>> userTrips =
          await fetchTripsFromFirestore(userId);
      setState(() {
        trips = userTrips;
        isLoading = false;
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

      QuerySnapshot querySnapshot = await tripsCollection.orderBy('dateTime', descending: true).get();
      for (var doc in querySnapshot.docs) {
        if (doc.exists) {
          Map<String, dynamic> tripData = {
            'id': doc.id,
            'dateTime': doc['dateTime'],
            'description': doc['description'],
            'latitude': doc['latitude'],
            'longitude': doc['longitude'],
            'placeName': doc['placeName'],
            
            'pictureUrls': List<String>.from(doc['pictureUrls'] ?? []),
             'isFavourite': doc['isFavourite'],
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

  Future<void> deleteTrip(String userId, String tripId) async {
    setState(() {
      isDeleting = true;
    });
    try {
      DocumentReference tripDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('trips')
          .doc(tripId);

      DocumentSnapshot docSnapshot = await tripDoc.get();
      if (docSnapshot.exists) {
        List<String> imageUrls = List<String>.from(docSnapshot['pictureUrls']);
        for (String imageUrl in imageUrls) {
          try {
            Reference storageRef =
                FirebaseStorage.instance.refFromURL(imageUrl);
            await storageRef.delete();
          } catch (e) {
            print("Error deleting image from storage: $e");
          }
        }
        await tripDoc.delete();
        await fetchUserTrips();
      }
    } catch (e) {
      print("Error deleting trip: $e");
    } finally {
      setState(() {
        isDeleting = false;
      });
    }
  }

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  fetchUserTrips(); // This will refresh the trips list when the screen is revisited
}

  Widget buildTripCard(Map<String, dynamic> trip) {
    String placeName = trip['placeName'];
    String description = trip['description'];
    List<String> imageUrls = trip['pictureUrls'];
    String tripId = trip['id'];
    bool isFavourite = trip['isFavourite'] ?? false; // Get the favorite status
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
  

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TripDetailsScreen(
              tripId: tripId,
              tripDetails: trip,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: const Color.fromARGB(255, 221, 220, 221),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.9),
                spreadRadius: 0.5,
                blurRadius: 2.0,
                offset: const Offset(1.0, 2.0),
              ),
            ],
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text(
                          placeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 53, 52, 52),
                            shadows: [
                              Shadow(
                                blurRadius: 3.0,
                                color: Colors.grey.withOpacity(0.8),
                                offset: const Offset(0.0, 1.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isFavourite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavourite
                                ? Colors.red // Change color when favorite
                                : const Color.fromARGB(255, 202, 138, 234),
                          ),
                          onPressed: () async {
                            final user = AuthService.firebase().currentUser;

                            String? userId = user?.id;

                            if (userId != null) {
                              // Toggle favorite status

                              await toggleFavoriteStatus(
                                  userId, tripId, !isFavourite);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          color: const Color.fromARGB(255, 202, 138, 234),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditTrip(
                                  tripId: tripId,
                                  tripDetails: trip,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          color: const Color.fromARGB(255, 202, 138, 234),
                          onPressed: () async {
                            bool shouldDelete = await showDeleteDialog(context);
                            if (shouldDelete) {
                              final user = AuthService.firebase().currentUser;
                              String? userId = user?.id;
                              if (userId != null) {
                                await deleteTrip(userId, tripId);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 30.0, right: 20),
                child: Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, color: Color.fromARGB(255, 53, 52, 52)),
                ),
              ),
              const SizedBox(height: 8.0),
              Padding(
                padding: const EdgeInsets.only(left: 30.0, right: 20),
                child: Text(
                  "Visited at: $formattedDate $formattedTime ",
                  style: const TextStyle(
                      fontSize: 15, color: Color.fromARGB(255, 53, 52, 52)),
                ),
              ),
              const SizedBox(height: 8.0),
              imageUrls.isEmpty
                  ? const SizedBox()
                  : buildImageCarousel(imageUrls),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ShareButton(tripId: tripId, tripDetails: trip),
                  ],
                ),
              ),
              const SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> toggleFavoriteStatus(
      String userId, String tripId, bool isFavorite) async {
    try {
      DocumentReference tripDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('trips')
          .doc(tripId);

      await tripDoc.update({'isFavourite': isFavorite});

      // Optionally, you can refresh the list of trips if needed

      setState(() {
        trips = trips.map((trip) {
          if (trip['id'] == tripId) {
            trip['isFavourite'] = isFavorite;
          }
          return trip;
        }).toList();
      });
    } catch (e) {
      print("Error updating favorite status: $e");
    }
  }

  Widget buildImageCarousel(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return const SizedBox();
    }
    if (imageUrls.length == 1) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              height: 200,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: imageUrls[0],
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) =>
                    const Center(child: Icon(Icons.error)),
              ),
            ),
          ),
        ),
      );
    } else {
      return CarouselSlider(
        options: CarouselOptions(
          height: 150.0,
          enlargeCenterPage: false,
          viewportFraction: 0.5,
          enableInfiniteScroll: false,
          pageSnapping: true,
          padEnds: false,
        ),
        items: imageUrls.map((imageUrl) => _buildImageItem(imageUrl)).toList(),
      );
    }
  }

  Widget _buildImageItem(String imageUrl) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color.fromARGB(255, 202, 138, 234),
              width: 0.5,
            ),
          ),
          child: AspectRatio(
            aspectRatio: 2.4,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
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
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color.fromARGB(255, 207, 205, 205),
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 207, 205, 205),
            title: const Text(
              "Your Trips",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            bottom: const TabBar(
              tabs: [
                Tab(text: "Trips"),
                Tab(text: "On Map"),
              ],
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
          drawer: MyDrawer(),
          body: TabBarView(
            children: [
              buildTripsTab(),
              const SummaryView(),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 202, 138, 234),
                focusColor: Color.fromARGB(255, 160, 100, 190),
                      splashColor: Color.fromARGB(255, 160, 100, 190),
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/mapview/');
              },
              elevation: 6.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ));
  }

  Widget buildTripsTab() {
    return Stack(
      children: [
        if (isDeleting)
          _buildProgressDialog()
        else if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (trips.isEmpty)
          Center(
            child: Text(
              "You Don't Have Any Trips",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.withOpacity(backgroundOpacity),
              ),
            ),
          )
        else
          ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              return buildTripCard(trips[index]);
            },
          ),
      ],
    );
  }
}

Widget _buildProgressDialog() {
  return Center(
    child: Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                Color.fromARGB(255, 202, 138, 234)),
          ),
          SizedBox(height: 16.0),
          Text(
            'Deleting trip...',
            style: TextStyle(color: Color.fromRGBO(97, 97, 97, 1)),
          ),
        ],
      ),
    ),
  );
}
