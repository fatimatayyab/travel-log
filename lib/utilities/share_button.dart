
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:travellog3/utilities/app_links.dart';

class ShareButton extends StatelessWidget {
  final String tripId;
  final Map<String, dynamic> tripDetails;

  const ShareButton({Key? key, required this.tripId, required this.tripDetails})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: TextButton.icon(
          
       onPressed: () async {
  print("in share button");

  String link = AppLinkProvider().createTripLink(tripId);
  print("Sharing Link: $link");

  Share.share(
    ' $link',
    
  );
},
          icon: const Icon(
            Icons.share,
            color: Color.fromARGB(255, 238, 237, 237),
            size: 20.0,
          ),
          label: const Text(
            "Share",
            style: TextStyle(
              color: Color.fromARGB(255, 238, 237, 237),
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 202, 138, 234),
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
        ),
      ),
    );
  }
}
