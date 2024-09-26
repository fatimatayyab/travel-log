import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:travellog3/services/auth/auth_provider.dart';
import 'package:travellog3/services/auth/auth_user.dart';
import 'package:travellog3/services/auth/firebase_auth_provider.dart';

class AuthService implements AuthProvider {
  final AuthProvider provider;
  const AuthService(this.provider);

  factory AuthService.firebase() => AuthService(FirebaseAuthProvider());

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) =>
      provider.createUser(
        email: email,
        password: password,
      );

  @override
  AuthUser? get currentUser => provider.currentUser;

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) =>
      provider.logIn(
        email: email,
        password: password,
      );

  @override
  Future<void> logOut() => provider.logOut();

  @override
  Future<void> sendEmailVerification() => provider.sendEmailVerification();

  @override
  Future<void> initialize() async {
    await provider.initialize();
     await FirebaseAppCheck.instance.getToken();
    await FirebaseAppCheck.instance
        .activate(androidProvider: AndroidProvider.debug);
   
  }
 @override
  Stream<AuthUser?> get authStateChanges => provider.authStateChanges;
  @override
  Future<void> sendPasswordResetEmail(
          {required String email, required BuildContext context}) =>
      provider.sendPasswordResetEmail(email: email, context: context);
        
        
         Future<AuthUser> signInWithGoogle() => provider.signInWithGoogle();
// Future<AuthUser> signInWithFacebook() => provider.signInWithFacebook();
}
