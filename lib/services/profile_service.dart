import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> createUserDocument(User user) async {
  final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

  // Create a new user document in Firestore if it doesn't exist
  await userRef.set({
    'email': user.email,
    'name': user.displayName ?? '',
    'age': '', // Initialize age as needed
    'profilePictureUrl': '',
  }, SetOptions(merge: true));
}
