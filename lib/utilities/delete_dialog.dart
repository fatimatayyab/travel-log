import 'package:flutter/material.dart';

Future<bool> showDeleteDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this trip?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // User pressed No
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // User pressed Yes
            },
            child: const Text('Yes'),
          ),
        ],
      );
    },
  ).then((value) => value ?? false);
}
