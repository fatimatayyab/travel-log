import 'package:flutter/material.dart';

class ConvertLatLngToAddress extends StatefulWidget {
  const ConvertLatLngToAddress({super.key});

  @override
  State<ConvertLatLngToAddress> createState() => _ConvertLatLngToAddressState();
}

class _ConvertLatLngToAddressState extends State<ConvertLatLngToAddress> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps'),
        centerTitle: true,
      ),
      body: const Column(
        children: [
          
        ],
      ),
    );
  }
}
