import 'package:flutter/material.dart';
import 'package:travellog3/services/auth/auth_service.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                  "We've sent you an email verification. Please open it to verify your account. If you haven't received a verification email yet, press the button below!"),
              TextButton(
                onPressed: () async {
                  await AuthService.firebase().sendEmailVerification();
                },
                child: const Text('Send email verification'),
              ),
              TextButton(
                onPressed: () async {
                  await AuthService.firebase().logOut();
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/welcomeview/',
                    (route) => false,
                  );
                },
                child: const Text('Restart'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
