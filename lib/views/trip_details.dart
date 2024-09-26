import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:travellog3/utilities/side_menu.dart';

class TripDetailsScreen extends StatelessWidget {
  final String tripId;
  final Map<String, dynamic> tripDetails;

  const TripDetailsScreen(
      {Key? key, required this.tripId, required this.tripDetails})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String placeName = tripDetails['placeName'];
    String description = tripDetails['description'];
    List<String> imageUrls = tripDetails['pictureUrls'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        backgroundColor: const Color.fromARGB(255, 202, 138, 234),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: Text(
                placeName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Serif',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0, left: 12.0),
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(), // Disable scrolling
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    // Top line (only for the first image)
                    if (index == 0)
                      Container(
                        height: 8,
                        color: Colors.grey[700], // Adjust grey color as needed
                      ),
                    Container(
                      height: 400,
                      width: double.infinity,
                      // margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: imageUrls[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
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
                    // Bottom line (except for the last image)
                    if (index < imageUrls.length)
                      Container(
                        height: 8,
                        color: Colors.grey[700], // Adjust grey color as needed
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
