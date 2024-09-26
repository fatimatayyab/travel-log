import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:travellog3/services/auth/auth_service.dart';
import 'package:travellog3/utilities/share_button.dart';
import 'package:travellog3/utilities/side_menu.dart';
import 'package:travellog3/views/trip_details.dart';

class FavoriteTripsView extends StatefulWidget {
  const FavoriteTripsView({super.key});

  @override
  State<FavoriteTripsView> createState() => _FavoriteTripsViewState();
}

class _FavoriteTripsViewState extends State<FavoriteTripsView> {
  List<Map<String, dynamic>> favoriteTrips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFavoriteTrips();
  }

  Future<void> fetchFavoriteTrips() async {
    final user = AuthService.firebase().currentUser;
    if (user != null) {
      String userId = user.id!;
      List<Map<String, dynamic>> fetchedTrips =
          await fetchTripsFromFirestore(userId);
      setState(() {
        favoriteTrips = fetchedTrips;
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

      QuerySnapshot querySnapshot =
          await tripsCollection.where('isFavourite', isEqualTo: true).get();
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
            'isFavourite': doc['isFavourite'] ?? false,
          };
          userTrips.add(tripData);
        }
      }
    } catch (e) {
      print("Error fetching favorite trips: $e");
    }
    return userTrips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 207, 205, 205),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 207, 205, 205),
        title: const Text(
          'Favorite Trips',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteTrips.isEmpty
              ? const Center(child: Text("No favorite trips found."))
              : ListView.builder(
                  itemCount: favoriteTrips.length,
                  itemBuilder: (context, index) {
                    return buildTripCard(favoriteTrips[index]);
                  },
                ),
    );
  }

  Widget buildTripCard(Map<String, dynamic> trip) {
    String placeName = trip['placeName'];
    String description = trip['description'];
    List<String> imageUrls = trip['pictureUrls'];
    String tripId = trip['id'];
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
}
