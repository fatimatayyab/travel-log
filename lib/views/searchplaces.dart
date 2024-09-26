// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:travellog3/api_key.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';

import 'mapview.dart';

class SearchPlaces extends StatefulWidget {
  final bool fromEditTrip; // Add this parameter to handle navigation

  const SearchPlaces({super.key, required this.fromEditTrip});

  @override
  State<SearchPlaces> createState() => _SearchPlacesState();
}

class _SearchPlacesState extends State<SearchPlaces> {
  late final TextEditingController _controller;
  var uuid;
  String _sessionToken = '1223344';
  List<dynamic> _placesList = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    uuid = const Uuid();
    _controller.addListener(() {
      onChange();
    });
  }

  void onChange() {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }
    getSuggestion(_controller.text);
  }

  void getSuggestion(String input) async {
    String kPLACES_API_KEY = apiKey;
    String baseURL =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    String request =
        "$baseURL?input=$input&key=$kPLACES_API_KEY&sessiontoken=$_sessionToken";

    var response = await http.get(Uri.parse(request));

    if (response.statusCode == 200) {
      setState(() {
        _placesList = jsonDecode(response.body.toString())['predictions'];
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(
              height: 30,
            ),
            TextFormField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'Search Places'),
            ),
            Expanded(
              child: ListView.builder(
                  itemCount: _placesList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () async {
                        List<Location> locations = await locationFromAddress(
                            _placesList[index]['description']);
                        print(_placesList);
                        Location location = locations.first;
                        double latitude = location.latitude;
                        double longitude = location.longitude;
                        // Get the selected place description
                        String selectedPlace =
                            _placesList[index]['description'];

                        // Set the selected place description to the text field
                        _controller.text = selectedPlace;

                        // Clear the suggestion list
                        setState(() {
                          _placesList = [];
                        });
                        if (widget.fromEditTrip) {
                          Navigator.of(context).pop({
                            'place': selectedPlace,
                            'latitude': latitude,
                            'longitude': longitude,
                          });
                        } else {
                          // Push MapView as usual (new trip creation flow)
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => MapView(
                                initialPlace: selectedPlace,
                                latitude: latitude,
                                longitude: longitude,
                                fromEditTrip: widget.fromEditTrip,
                              ),
                            ),
                          );
                        }
                      },
                      title: Text(_placesList[index]['description']),
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }
}
