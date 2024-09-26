import 'package:cloud_firestore/cloud_firestore.dart';

class TravelExperience {
  double latitude;
  double longitude;
  DateTime dateTime;
  String placeName;
  List<String> pictureUrls; // Changed to List<String>
  String description;
  bool isFavourite;
  

  TravelExperience({
    required this.latitude,
    required this.longitude,
    required this.dateTime,
    required this.placeName,
    required this.pictureUrls, // Changed to List<String>
    required this.description,
      this.isFavourite = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'dateTime': dateTime.toIso8601String(),
      'placeName': placeName,
      'pictureUrls': pictureUrls, // Changed to List<String>
      'description': description,
      'isFavourite' : isFavourite,
    };
  }

  factory TravelExperience.fromJson(Map<String, dynamic> json) {
    return TravelExperience(
      latitude: json['latitude'],
      longitude: json['longitude'],
      dateTime: DateTime.parse(json['dateTime']),
      placeName: json['placeName'],
      pictureUrls: List<String>.from(json['pictureUrls'] ?? []),
      description: json['description'],
      isFavourite : json['isFavourite'] ?? false ,
      
    );
  }
}

void saveTravelExperience(TravelExperience experience) {
  FirebaseFirestore.instance
      .collection('travel_experiences')
      .add(experience.toJson());
}
