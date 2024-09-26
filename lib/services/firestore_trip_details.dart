import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travellog3/utilities/travel_experience.dart';

Future<TravelExperience?> fetchTripDetails(String tripId) async {
  try {
    print("Fetching trip data for ID: $tripId");
    
    // Fetch the document by its ID
    final docSnapshot = await FirebaseFirestore.instance
        .collection('travel_experiences')
        .doc(tripId)
        .get();

    if (docSnapshot.exists) {
      print("Document found. Accessing data...");
      
      // Safely retrieve the data as a Map<String, dynamic>
      final tripData = docSnapshot.data();
      
      if (tripData != null) {
        print("Data accessed successfully");
        return TravelExperience.fromJson(tripData);
      } else {
        print("Document exists, but no data found");
        return null;
      }
    } else {
      print("No document found with ID: $tripId");
      return null;
    }
  } catch (e) {
    // Catch any errors and print them for debugging
    print("Error fetching trip details: $e");
    return null;
  }
}
