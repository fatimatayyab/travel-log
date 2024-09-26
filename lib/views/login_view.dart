// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:travellog3/services/auth/auth_exceptions.dart';
import 'package:travellog3/services/auth/auth_service.dart';
import 'package:travellog3/utilities/show_error_dialog.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  bool _isLoggingIn = false;
  bool _passwordVisible = false;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: _isLoggingIn
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _email,
                              enableSuggestions: false,
                              autocorrect: false,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                  labelText: "Enter Your Email"),
                            ),
                            TextField(
                              controller: _password,
                              obscureText: !_passwordVisible,
                              enableSuggestions: false,
                              autocorrect: false,
                              decoration: InputDecoration(
                                labelText: "Enter Your Password",
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _passwordVisible = !_passwordVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 60,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              MaterialButton(
                                minWidth: double.infinity,
                                height: 60,
                                color: const Color.fromARGB(255, 202, 138, 234),
                                 highlightColor: Color.fromARGB(255, 160, 100, 190), // Darker color when pressed
                      splashColor: Color.fromARGB(255, 160, 100, 190),
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    color: Color.fromARGB(255, 202, 138, 234),
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                onPressed: () async {
                                  final email = _email.text;
                                  final password = _password.text;

                                  try {
                                    setState(() {
                                      _isLoggingIn = true;
                                    });

                                    await AuthService.firebase().logIn(
                                        email: email, password: password);

                                    final user =
                                        FirebaseAuth.instance.currentUser;

                                    if (user != null) {
                                      if (user.emailVerified) {
                                        Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                          '/tripsview/',
                                          (route) => false,
                                        );
                                      } else {
                                        Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                          '/verifyemail/',
                                          (route) => false,
                                        );
                                      }
                                    }
                                  } on UserNotFoundAuthException {
                                    showErrorDialog(context, 'User Not Found');
                                  } on WrongPasswordAuthException {
                                    showErrorDialog(context, 'Wrong Password');
                                  } on GenericAuthException {
                                    await showErrorDialog(
                                      context,
                                      'Failed To Log In',
                                    );
                                  } finally {
                                    setState(() {
                                      _isLoggingIn = false;
                                    });
                                  }
                                },
                                child: const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushNamed('/forgetpassword/');
                                },
                                child: const Text('Forgot Password'),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Row(
                                children: [
                                  const Text(
                                    "Don't have an account?",
                                    textAlign: TextAlign.center,
                                  ),
                                  TextButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                          '/register/',
                                          (route) => false,
                                        );
                                      },
                                      child: const Text('Signup here!'))
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('OR'),
                        SizedBox(
                          height: 50,
                          child: SignInButton(Buttons.google,
                              text: "Login With Google", onPressed: () async {
                      await AuthService.firebase().signInWithGoogle();
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              if (user.emailVerified) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/tripsview/', (route) => false);
                              } else {
                                await user.sendEmailVerification();
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/verifyemail/',
                                  (route) => false,
                                );
                              }
                            } else {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/registerview/',
                                (route) => false,
                              );
                            }
                          }),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                  //  SizedBox(
                  //         height: 50,
                  //         child: SignInButton(Buttons.facebook,
                  //             text: "Login With Facebook", onPressed: () async {
                  //           setState(() {
                  //             _isLoggingIn = true;
                  //           });
                  //           try {
                  //             await AuthService.firebase().signInWithFacebook();
                  //             final user = FirebaseAuth.instance.currentUser;
                  //             if (user != null) {
                  //               if (user.emailVerified) {
                  //                 Navigator.of(context)
                  //                     .pushNamedAndRemoveUntil(
                  //                         '/tripsview/', (route) => false);
                  //               } else {
                  //                 Navigator.of(context)
                  //                     .pushNamedAndRemoveUntil(
                  //                   '/verifyemail/',
                  //                   (route) => false,
                  //                 );
                  //               }
                  //             }
                  //           } catch (e) {
                  //             await showErrorDialog(context,
                  //                 'Facebook Login Error: ${e.toString()}');
                  //           } finally {
                  //             setState(() {
                  //               _isLoggingIn = false;
                  //             });
                  //           }
                  //         }),
                  //       ),
                     
                      ],
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
