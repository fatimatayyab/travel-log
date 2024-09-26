// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:travellog3/utilities/side_menu.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  UserProfileState createState() => UserProfileState();
}

class UserProfileState extends State<UserProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _profilePictureUrl;
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await fetchUserData(_userId);
      setState(() {
        _nameController.text = userData['name'];
        _ageController.text = userData['age'].toString();
        _emailController.text = userData['email'];
        _profilePictureUrl = userData['profilePictureUrl'] ?? '';
        print("Profile Picture URL: $_profilePictureUrl");
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile != null ? File(pickedFile.path) : null;
    });
  }

  Future<String> _uploadImageToStorage(File imageFile) async {
    try {
      // Create a unique file name using the user's ID and current timestamp
      String fileName =
          '${_userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Create a reference to the 'profilepictures' folder
      Reference ref =
          FirebaseStorage.instance.ref().child('profilepictures/$fileName');

      // Upload the file
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;

      // Get the download URL
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Failed to upload image: $e');
      throw e;
    }
  }

  Future<void> _removeProfilePicture() async {
    if (_profilePictureUrl != null) {
      try {
        Uri uri = Uri.parse(_profilePictureUrl!);
        String fullPath = Uri.decodeComponent(uri.path);
        String fileName = fullPath.split('/').last;
        Reference ref =
            FirebaseStorage.instance.ref().child('profilepictures/$fileName');
        print("$fileName from remove function");
        await ref.delete();
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(_userId);
        await userRef.update({
          'profilePictureUrl': null,
        });
        setState(() {
          _profilePictureUrl = null;
          _imageFile = null;
        });
      } catch (e) {
        print('Error deleting profile picture: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete profile picture: $e')),
        );

        // Handle the error if necessary, e.g., show a message to the user
      }
    }
  }

  Future<void> _removePreviousImage() async {
    if (_profilePictureUrl != null && _profilePictureUrl!.isNotEmpty) {
      try {
        // Extract the file name from the URL
        Uri uri = Uri.parse(_profilePictureUrl!);
        String fullPath = Uri.decodeComponent(uri.path);
        String fileName = fullPath.split('/').last;

        // Reference to the file in Firebase Storage
        Reference ref =
            FirebaseStorage.instance.ref().child('profilepictures/$fileName');

        // Delete the file from Firebase Storage
        await ref.delete();

        print('Previous profile picture deleted successfully.');
      } catch (e) {
        print('Failed to delete the previous image: $e');
        // Handle the error if necessary, e.g., show a message to the user
      }
    }
  }

  Future<void> _deleteAccount() async {
    try {
      // Step 1: Show confirmation dialog
      final confirmed = await _showDeletionConfirmationDialog();
      if (!confirmed)
        return; // If the user cancels the deletion, exit the function.

      // Step 2: Prompt the user to re-authenticate
      final result = await _showReauthenticateDialog();
      if (!result)
        return; // If the user cancels the re-authentication, exit the function.

      setState(() {
        _isLoading = true;
      });
      // Step 3: Fetch and delete all user trips
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await _deleteAllUserTrips(userId);

      // Step 4: Delete the user's profile picture from Firebase Storage
      await _removePreviousImage();

      // Step 5: Delete the user's document from Firestore
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(_userId);
      await userRef.delete();

      // Step 6: Delete the user from Firebase Auth
      await FirebaseAuth.instance.currentUser!.delete();

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully')),
      );

      // Step 7: Navigate to the login screen after deletion
      Navigator.of(context).pushReplacementNamed('/login/');
    } catch (e) {
      print('Failed to delete account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAllUserTrips(String userId) async {
    try {
      // Fetch all trips
      final trips = await fetchTripsFromFirestore(userId);

      // Delete each trip
      for (var trip in trips) {
        await deleteTrip(userId, trip['id']);
      }
    } catch (e) {
      print('Error deleting user trips: $e');
      throw e; // Re-throw the exception to handle it in the _deleteAccount method
    }
  }

  Future<void> deleteTrip(String userId, String tripId) async {
    try {
      DocumentReference tripDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('trips')
          .doc(tripId);

      DocumentSnapshot docSnapshot = await tripDoc.get();
      if (docSnapshot.exists) {
        List<String> imageUrls = List<String>.from(docSnapshot['pictureUrls']);
        for (String imageUrl in imageUrls) {
          try {
            Reference storageRef =
                FirebaseStorage.instance.refFromURL(imageUrl);
            await storageRef.delete();
          } catch (e) {
            print("Error deleting image from storage: $e");
          }
        }
        await tripDoc.delete();
      }
    } catch (e) {
      print("Error deleting trip: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchTripsFromFirestore(
      String userId) async {
    List<Map<String, dynamic>> userTrips = [];
    try {
      CollectionReference tripsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('trips');

      QuerySnapshot querySnapshot = await tripsCollection.get();
      for (var doc in querySnapshot.docs) {
        if (doc.exists) {
          Map<String, dynamic> tripData = {
            'id': doc.id,
            'dateTime': doc['dateTime'],
            'description': doc['description'],
            'latitude': doc['latitude'],
            'longitude': doc['longitude'],
            'placeName': doc['placeName'],
            'pictureUrls': List<String>.from(doc['pictureUrls'] ?? []),
          };
          userTrips.add(tripData);
        }
      }
    } catch (e) {
      // Log the error
      print("Error fetching trips: $e");
    }
    return userTrips;
  }

  Future<bool> _showDeletionConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: const Text(
                'This action will permanently delete your account and all associated data. Are you sure you want to proceed?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _showReauthenticateDialog() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false; // No user is signed in
    }

    // Check if the user signed in using Facebook
    // bool isFacebookUser =
    //     user.providerData.any((info) => info.providerId == 'facebook.com');
    bool isGoogleUser =
        user.providerData.any((info) => info.providerId == 'google.com');

    // if (isFacebookUser) {
    //   try {
    //     // Re-authenticate using Facebook
    //     final LoginResult loginResult = await FacebookAuth.instance.login();
    //     if (loginResult.status == LoginStatus.success) {
    //       final OAuthCredential credential =
    //           FacebookAuthProvider.credential(loginResult.accessToken!.token);

    //       await user.reauthenticateWithCredential(credential);
    //       return true;
    //     } else {
    //       // Handle login failure
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         SnackBar(
    //             content: Text('Facebook login failed: ${loginResult.status}')),
    //       );
    //       return false;
    //     }
    //   } catch (e) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Re-authentication failed: $e')),
    //     );
    //     return false;
    //   }
    // } else
     if (isGoogleUser) {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;

          final OAuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          await user.reauthenticateWithCredential(credential);

          return true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google sign-in failed')),
          );

          return false;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Re-authentication failed: $e')),
        );

        return false;
      }
    } else {
      // For email/password users, prompt for password re-authentication
      final TextEditingController passwordController = TextEditingController();
      return await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Re-authenticate'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                        'Please enter your password to proceed with account deletion:'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final password = passwordController.text;

                      // Re-authenticate the user with the provided password
                      try {
                        final credential = EmailAuthProvider.credential(
                          email: user.email!,
                          password: password,
                        );

                        await user.reauthenticateWithCredential(credential);
                        Navigator.of(context).pop(true);
                      } catch (e) {
                        Navigator.of(context).pop(false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Re-authentication failed: $e')),
                        );
                      }
                    },
                    child: const Text('Verify'),
                  ),
                ],
              );
            },
          ) ??
          false;
    }
  }

  Future<void> _updateUserData() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true; // Start saving
      });
      _formKey.currentState!.save();
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(_userId);

      // Upload the image only if a new image is selected
      String? newProfilePictureUrl;

      if (_imageFile != null) {
        newProfilePictureUrl = await _uploadImageToStorage(_imageFile!);
      }

      if (newProfilePictureUrl != null) {
        await _removePreviousImage();

        await userRef.update({
          'profilePictureUrl': newProfilePictureUrl,
        });
      }

      await userRef.update({
        'name': _nameController.text,
        'age': int.parse(_ageController.text) ?? 0,
      });
      setState(() {
        _isSaving = false; // End saving
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved your details')),
      );

      Navigator.pushReplacementNamed(context, '/tripsview/');
    }
  }

  // bool _isValidPassword(String password) {
  //   // Regular expression for password validation
  //   final passwordRegExp = RegExp(
  //     r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  //   );
  //   return passwordRegExp.hasMatch(password);
  // }

  // Future<void> _changePassword(String oldPassword, String newPassword) async {
  //   try {
  //     if (!_isValidPassword(newPassword)) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //             content: Text('New password does not meet requirements')),
  //       );
  //       return;
  //     }

  //     User user = FirebaseAuth.instance.currentUser!;
  //     AuthCredential credential = EmailAuthProvider.credential(
  //       email: user.email!,
  //       password: oldPassword,
  //     );
  //     await user.reauthenticateWithCredential(credential);
  //     await user.updatePassword(newPassword);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Password changed successfully')),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Password change failed: ${e.toString()}')),
  //     );
  //   }
  // }

  // void _showChangePasswordDialog() {
  //   final oldPasswordController = TextEditingController();
  //   final newPasswordController = TextEditingController();
  //   final confirmPasswordController = TextEditingController();
  //   bool _oldPasswordVisible = false;
  //   bool _newPasswordVisible = false;
  //   bool _confirmPasswordVisible = false;

  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           return AlertDialog(
  //             title: const Text('Change Password'),
  //             content: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 TextField(
  //                   controller: oldPasswordController,
  //                   decoration: InputDecoration(
  //                     labelText: 'Old Password',
  //                     suffixIcon: IconButton(
  //                       icon: Icon(
  //                         _oldPasswordVisible
  //                             ? Icons.visibility
  //                             : Icons.visibility_off,
  //                       ),
  //                       onPressed: () {
  //                         setState(() {
  //                           _oldPasswordVisible = !_oldPasswordVisible;
  //                         });
  //                       },
  //                     ),
  //                   ),
  //                   obscureText: !_oldPasswordVisible,
  //                 ),
  //                 TextField(
  //                   controller: newPasswordController,
  //                   decoration: InputDecoration(
  //                     labelText: 'New Password',
  //                     suffixIcon: IconButton(
  //                       icon: Icon(
  //                         _newPasswordVisible
  //                             ? Icons.visibility
  //                             : Icons.visibility_off,
  //                       ),
  //                       onPressed: () {
  //                         setState(() {
  //                           _newPasswordVisible = !_newPasswordVisible;
  //                         });
  //                       },
  //                     ),
  //                   ),
  //                   obscureText: !_newPasswordVisible,
  //                 ),
  //                 TextField(
  //                   controller: confirmPasswordController,
  //                   decoration: InputDecoration(
  //                     labelText: 'Confirm New Password',
  //                     suffixIcon: IconButton(
  //                       icon: Icon(
  //                         _confirmPasswordVisible
  //                             ? Icons.visibility
  //                             : Icons.visibility_off,
  //                       ),
  //                       onPressed: () {
  //                         setState(() {
  //                           _confirmPasswordVisible = !_confirmPasswordVisible;
  //                         });
  //                       },
  //                     ),
  //                   ),
  //                   obscureText: !_confirmPasswordVisible,
  //                 ),
  //               ],
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                 },
  //                 child: const Text('Cancel'),
  //               ),
  //               ElevatedButton(
  //                 onPressed: () {
  //                   final oldPassword = oldPasswordController.text;
  //                   final newPassword = newPasswordController.text;
  //                   final confirmPassword = confirmPasswordController.text;

  //                   if (newPassword != confirmPassword) {
  //                     ScaffoldMessenger.of(context).showSnackBar(
  //                       const SnackBar(
  //                           content: Text('New passwords do not match')),
  //                     );
  //                     return;
  //                   }

  //                   _changePassword(oldPassword, newPassword);
  //                   Navigator.of(context).pop();
  //                 },
  //                 child: const Text('Change'),
  //               ),
  //               TextButton(
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                   Navigator.of(context).pushNamed('/forgetpassword/');
  //                 },
  //                 child: const Text('Try another way to change your password'),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile'),
      leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),
            ),
            drawer: const MyDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 90,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_profilePictureUrl != null &&
                                        _profilePictureUrl!.isNotEmpty)
                                    ? NetworkImage(_profilePictureUrl!)
                                        as ImageProvider
                                    : const AssetImage(
                                        'assets/images/user.png'), // Fallback asset image
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickImage,
                              child: const CircleAvatar(
                                radius: 15,
                                backgroundColor:
                                    const Color.fromARGB(255, 202, 138, 234),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_profilePictureUrl != null &&
                        _profilePictureUrl!.isNotEmpty)
                      TextButton(
                        onPressed: _removeProfilePicture,
                        child: const Text('Remove Picture'),
                      ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                      onSaved: (value) => _nameController.text = value!,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your age';
                        }
                        return null;
                      },
                      onSaved: (value) => _ageController.text = value!,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 20),
                    // TextFormField(
                    //   decoration: InputDecoration(
                    //     labelText: 'Password',
                    //     border: const OutlineInputBorder(),
                    //     suffixIcon: IconButton(
                    //       icon: const Icon(Icons.edit),
                    //       onPressed: _showChangePasswordDialog,
                    //     ),
                    //   ),
                    //   obscureText: true,
                    //   readOnly: true,
                    //   initialValue: '******',
                    // ),
                    const SizedBox(height: 40),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            const Color.fromARGB(255, 202, 138, 234),
                          ), // Background color
                          foregroundColor: MaterialStateProperty.all<Color>(
                              Colors.white), // Text color
                          padding: MaterialStateProperty.all<EdgeInsets>(
                              const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12)), // Padding
                          elevation:
                              MaterialStateProperty.all<double>(8), // Elevation
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(25), // Border radius
                            ),
                          ),
                          side: MaterialStateProperty.all<BorderSide>(
                              const BorderSide(
                            color: Color.fromARGB(255, 202, 138, 234),
                          )), // Border
                        ),
                        onPressed: _updateUserData,
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(fontSize: 17),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 50,
                      decoration:
                          BoxDecoration(borderRadius: BorderRadius.circular(4)),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _deleteAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text(
                                'DELETE ACCOUNT',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

Future<Map<String, dynamic>> fetchUserData(String userId) async {
  final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
  final doc = await userRef.get();
  if (doc.exists) {
    return doc.data()!;
  } else {
    throw Exception("User not found");
  }
}
