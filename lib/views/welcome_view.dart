import 'package:flutter/material.dart';
import 'package:travellog3/views/login_view.dart';
import 'package:travellog3/views/register_view.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(80.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 30,
                    ),
                    Text(
                      'Welcome',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Text(
                      'Live Your Adventures Forever',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromARGB(255, 202, 138, 234),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
              const SizedBox(
                height: 80,
              ),
              Container(
                height: MediaQuery.of(context).size.height / 4,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/logo.jpeg'),
                  ),
                ),
              ),
              const SizedBox(
                height: 80,
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
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
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LoginView(),
                          ),
                        );
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
                      height: 20,
                    ),
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
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RegisterView(),
                          ),
                        );
                      },
                      child: const Text(
                        "SignUp",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
