import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

@immutable
class AuthUser {
  final String id;
  final String? email;
  final bool isEmailVerified;
  final String? name;
  final int? age;
  final String? profilePictureUrl;

  const AuthUser({
    required this.id,
    required this.email,
    required this.isEmailVerified,
    this.name,
    this.age,
    this.profilePictureUrl,
  });

  factory AuthUser.fromFirebase(User user) =>
      AuthUser(email: user.email, isEmailVerified: user.emailVerified, id: user.uid);
}
