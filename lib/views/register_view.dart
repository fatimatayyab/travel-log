// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import 'package:sign_in_button/sign_in_button.dart';
import 'package:travellog3/services/auth/auth_exceptions.dart';
import 'package:travellog3/services/auth/auth_service.dart';
import 'package:travellog3/services/auth/auth_user.dart';

import 'package:travellog3/utilities/show_error_dialog.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _confirmPassword;
  bool _passwordVisible = false;
  bool _isSigningUp = false;

  bool _confirmPasswordVisible = false;
  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    _confirmPassword = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  bool isValidPassword(String password) {
    // Regular expression for password validation
    final passwordRegExp = RegExp(
      r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
    );
    return passwordRegExp.hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up"),
      ),
      body: _isSigningUp
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Text(
                      'Sign Up to Start Creating Your Memories',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromARGB(255, 202, 138, 234),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 60,
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
                        TextField(
                          controller: _confirmPassword,
                          obscureText: !_confirmPasswordVisible,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: "Confirm Your Password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                _confirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _confirmPasswordVisible =
                                      !_confirmPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 0,
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
                              final confirmPassword = _confirmPassword.text;

                              if (!isValidPassword(password)) {
                                showErrorDialog(context,
                                    'Password must be at least 8 characters long, include letters, numbers, and at least one special character.');
                                return;
                              }

                              if (password != confirmPassword) {
                                showErrorDialog(
                                    context, 'Passwords Do Not Match');
                                return;
                              }
                              try {
                                setState(() {
                                  _isSigningUp = true;
                                });
                                await AuthService.firebase().createUser(
                                    email: email, password: password);

                                await AuthService.firebase()
                                    .sendEmailVerification();
                                Navigator.of(context)
                                    .pushNamed('/verifyemail/');
                              } on WeakPasswordAuthException {
                                showErrorDialog(context, 'Weak Password');
                              } on EmailAlreadyInUseAuthException {
                                showErrorDialog(
                                    context, 'Email Already In Use');
                              } on InvalidEmailAuthException {
                                showErrorDialog(
                                    context, 'Invalid Email Entered');
                              } on GenericAuthException {
                                await showErrorDialog(
                                  context,
                                  'Failed To Register ',
                                );
                              } finally {
                                setState(() {
                                  _isSigningUp = false;
                                });
                              }
                            },
                            child: const Text(
                              "SignUp",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Text(
                                "Already have an account?",
                                textAlign: TextAlign.center,
                              ),
                              TextButton(
                                  onPressed: () async {
                                    Navigator.of(context)
                                        .pushNamedAndRemoveUntil(
                                      '/login/',
                                      (route) => false,
                                    );
                                  },
                                  child: const Text('Login here!'))
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('OR'),
                        SizedBox(
                          height: 50,
                          child: SignInButton(
                            Buttons.google,
                            text: "SignUp With Google",
                            onPressed: () async {
                              setState(() {
                                _isSigningUp = true;
                              });
                              try {
                                final AuthUser user =
                                    await AuthService.firebase()
                                        .signInWithGoogle();
                                if (user.isEmailVerified) {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/tripsview/',
                                    (route) => false,
                                  );
                                } else {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/verifyemail/',
                                    (route) => false,
                                  );
                                }
                              } catch (e) {
                                await showErrorDialog(context,
                                    'Google Sign-In Error: ${e.toString()}');
                              } finally {
                                setState(() {
                                  _isSigningUp = false;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        // SizedBox(
                        //   height: 50,
                        //   child: SignInButton(
                        //     Buttons.facebook,
                        //     text: "SignUp With Facebook",
                        //     onPressed: () async {
                        //       setState(() {
                        //         _isSigningUp = true;
                        //       });
                        //       try {
                        //         final AuthUser user =
                        //             await AuthService.firebase()
                        //                 .signInWithFacebook();
                        //         if (user.isEmailVerified) {
                        //           Navigator.of(context).pushNamedAndRemoveUntil(
                        //             '/tripsview/',
                        //             (route) => false,
                        //           );
                        //         } else {
                        //           Navigator.of(context).pushNamedAndRemoveUntil(
                        //             '/verifyemail/',
                        //             (route) => false,
                        //           );
                        //         }
                        //       } catch (e) {
                        //         await showErrorDialog(context,
                        //             'Facebook Sign-In Error: ${e.toString()}');
                        //       } finally {
                        //         setState(() {
                        //           _isSigningUp = false;
                        //         });
                        //       }
                        //     },
                        //   ),
                        // ),
                      ],
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
