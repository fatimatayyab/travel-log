import 'package:flutter/material.dart';
import 'package:travellog3/services/auth/auth_user.dart';

abstract class AuthProvider {
  Future<void> initialize();
  AuthUser? get currentUser;

  // Email/Password
  Future<AuthUser> logIn({
    required String email,
    required String password,
  });

 Stream<AuthUser?> get authStateChanges;
  Future<AuthUser> createUser({
    required String email,
    required String password,
  });

  // Google
  Future<AuthUser> signInWithGoogle();

  // Facebook
  //Future<AuthUser> signInWithFacebook();

  Future<void> logOut();
  Future<void> sendEmailVerification();
  Future<void> sendPasswordResetEmail({required String email, required BuildContext context});
}
