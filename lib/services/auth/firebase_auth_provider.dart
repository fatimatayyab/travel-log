import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'
    show
        FacebookAuthProvider,
        FirebaseAuth,
        FirebaseAuthException,
        GoogleAuthProvider,
        OAuthCredential,
        User,
        UserCredential;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'; // Use the appropriate package for Facebook Auth
import 'package:travellog3/firebase_options.dart';
import 'package:travellog3/services/auth/auth_exceptions.dart';
import 'package:travellog3/services/auth/auth_provider.dart';
import 'package:travellog3/services/auth/auth_user.dart';

class FirebaseAuthProvider implements AuthProvider {

    @override
  Stream<AuthUser?> get authStateChanges {
    return FirebaseAuth.instance.authStateChanges().map((user) {
      if (user != null) {
        return AuthUser.fromFirebase(user);
      } else {
        return null;
      }
    });
  }
  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
    String? name,
    int? age,
    String? profilePictureUrl,
  }) async {
    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user!;
      await _createOrUpdateUserDocument(
          user, email, name, age, profilePictureUrl);
      return AuthUser(
        id: user.uid,
        email: user.email,
        isEmailVerified: user.emailVerified,
        name: name,
        age: age,
        profilePictureUrl: profilePictureUrl,
      );
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      rethrow; // Ensure that the exception is propagated
    }
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user!;
      return AuthUser(
        id: user.uid,
        email: user.email,
        isEmailVerified: user.emailVerified,
      );
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      rethrow;
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      // Sign out from Google to prompt account selection on next sign-in

      await googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user!;
      await _createOrUpdateUserDocument(user, user.email);
      return AuthUser(
        id: user.uid,
        email: user.email,
        isEmailVerified: user.emailVerified,
      );
    } catch (e) {
      throw GenericAuthException();
    }
  }

  // @override
  // Future<AuthUser> signInWithFacebook() async {
  //   try {
  //     final LoginResult loginResult = await FacebookAuth.instance.login();

  //     if (loginResult.status == LoginStatus.success) {
  //       final AccessToken? accessToken = loginResult.accessToken;
  //       if (accessToken != null) {
  //         try {
  //           final OAuthCredential credential =
  //               FacebookAuthProvider.credential(accessToken.token);
  //           final UserCredential userCredential =
  //               await FirebaseAuth.instance.signInWithCredential(credential);
  //           final User? user = userCredential.user;

  //           if (user != null) {
  //             await _createOrUpdateUserDocument(user, user.email);
  //             return AuthUser(
  //               id: user.uid,
  //               email: user.email!,
  //               isEmailVerified: user.emailVerified,
  //             );
  //           } else {
  //             throw GenericAuthException(); // Handle case where user is null
  //           }
  //         } catch (e) {
  //           // Check for specific error related to token invalidation
  //           if (e.toString().contains('Error validating access token')) {
  //             // Prompt the user to log in again
  //             await FacebookAuth.instance.logOut();
  //             return signInWithFacebook(); // Retry the sign-in process
  //           } else {
  //             throw GenericAuthException(); // Handle other errors
  //           }
  //         }
  //       } else {
  //         throw GenericAuthException(); // Handle case where accessToken is null
  //       }
  //     } else if (loginResult.status == LoginStatus.cancelled) {
  //       throw GenericAuthException(); // User cancelled the login
  //     } else {
  //       throw GenericAuthException(); // Login failed for some reason
  //     }
  //   } catch (e) {
  //     // Log the error or handle it appropriately
  //     print('Error during Facebook Sign-In: $e');
  //     throw GenericAuthException();
  //   }
  // }

  // @override
  // Future<AuthUser> signInWithFacebook() async {
  //   try {
  //     final AccessToken result = (await FacebookAuth.instance.login()) as AccessToken;
  //     final credential = FacebookAuthProvider.credential(result.token);
  //     final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
  //     final user = userCredential.user!;
  //     await _createOrUpdateUserDocument(user, user.email);
  //     return AuthUser(
  //       id: user.uid,
  //       email: user.email,
  //       isEmailVerified: user.emailVerified,
  //     );
  //   } catch (e) {
  //     throw GenericAuthException();
  //   }
  // }

  @override
  AuthUser? get currentUser {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return AuthUser(
        id: user.uid,
        email: user.email,
        isEmailVerified: user.emailVerified,
      );
    } else {
      return null;
    }
  }

  @override
  Future<void> logOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    } else {
      throw UserNotLoggedInAuthException();
    }
  }

  @override
  Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Future<void> sendPasswordResetEmail(
      {required String email, required BuildContext context}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
    }
  }

  Future<void> _createOrUpdateUserDocument(User user, String? email,
      [String? name, int? age, String? profilePictureUrl]) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    await userRef.set({
      'email': email ?? '',
      'name': name ?? '',
      'age': age ?? '',
      'profilePictureUrl': profilePictureUrl ?? '',
    }, SetOptions(merge: true));
  }

  void _handleAuthException(FirebaseAuthException e) {
    if (e.code == 'weak-password') {
      throw WeakPasswordAuthException();
    } else if (e.code == 'email-already-in-use') {
      throw EmailAlreadyInUseAuthException();
    } else if (e.code == 'invalid-email') {
      throw InvalidEmailAuthException();
    } else if (e.code == 'user-not-found') {
      throw UserNotFoundAuthException();
    } else if (e.code == 'wrong-password') {
      throw WrongPasswordAuthException();
    } else {
      throw GenericAuthException();
    }
  }
}
