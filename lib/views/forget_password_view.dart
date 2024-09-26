// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travellog3/services/auth/auth_service.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();

      try {
        // Check if the email exists in Firestore
        bool emailExists = await _checkIfEmailExists(email);

        if (emailExists) {
          await AuthService.firebase().sendPasswordResetEmail(
            email: email,
            context: context,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Password Reset Link Sent. Check your Email')),
          );
          await Future.delayed(const Duration(seconds: 2));
          await AuthService.firebase().logOut();
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login/', (route) => false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Login with your new password to continue')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('The email address is not registered.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error sending password reset email')),
        );
      }
    }
  }

  Future<bool> _checkIfEmailExists(String email) async {
    final userRef = FirebaseFirestore.instance.collection('users');
    final querySnapshot = await userRef.where('email', isEqualTo: email).get();
    return querySnapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.0),
                child: Text(
                  'Enter your Email and we will send you a Password Reset Link',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                enableSuggestions: false,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(labelText: "Enter your Email"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  // Simple email validation regex
                  const emailRegex = r'^.+@.+\..+$';
                  if (!RegExp(emailRegex).hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              MaterialButton(
                minWidth: double.infinity,
                height: 40,
                color: const Color.fromARGB(255, 202, 138, 234),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    color: Color.fromARGB(255, 202, 138, 234),
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                onPressed: _sendPasswordResetEmail,
                child: const Text(
                  "Reset Password",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.white,
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
