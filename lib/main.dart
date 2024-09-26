  import 'dart:async';
  import 'package:app_links/app_links.dart';
  import 'package:flutter/material.dart';
  import 'package:travellog3/services/auth/auth_service.dart';
  import 'package:travellog3/services/firestore_trip_details.dart';
  import 'package:travellog3/utilities/travel_experience.dart';
  import 'package:travellog3/views/add_trip_view.dart';
  import 'package:travellog3/views/edit_trip.dart';
  import 'package:travellog3/views/favourite_trips.dart';
  import 'package:travellog3/views/forget_password_view.dart';
  import 'package:travellog3/views/login_view.dart';
  import 'package:travellog3/views/mapview.dart';
  import 'package:travellog3/views/profile_view.dart';
  import 'package:travellog3/views/register_view.dart';
  import 'package:travellog3/views/searchplaces.dart';
  import 'package:travellog3/views/splashscreen.dart';
  import 'package:travellog3/views/summary_view.dart';
  import 'package:travellog3/views/trip_details.dart';
  import 'package:travellog3/views/trips_view.dart';
  import 'package:travellog3/views/verify_email_view.dart';
  import 'package:travellog3/views/welcome_view.dart';

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    runApp(MyApp());
  }

  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Travel Log',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomePage(),
        navigatorKey: GlobalKey<NavigatorState>(),
        initialRoute: "/",
        onGenerateRoute: (settings) {
      // Return WelcomeView for any generated route
      return MaterialPageRoute(builder: (context) => const WelcomeView());
    },
        routes: {
    
          '/login/': (context) => const LoginView(),
          '/register/': (context) => const RegisterView(),
          '/verifyemail/': (context) => const VerifyEmailView(),
          '/welcomeview/': (context) => const WelcomeView(),
          '/forgetpassword/': (context) => const ForgetPassword(),
          '/searchplaces/': (context) => SearchPlaces(
                fromEditTrip: ModalRoute.of(context)?.settings.arguments as bool,
              ),
          '/addtrip/': (context) => const AddTrip(),
          '/mapview/': (context) => const MapView(),
          '/tripsview/': (context) => const TripsView(),
          '/summaryview/': (context) => const SummaryView(),
          '/favouritetrip/': (context) => const FavoriteTripsView(),
          '/userprofile/': (context) => const UserProfile(),
          '/edittrip/': (context) => EditTrip(
                tripId: ModalRoute.of(context)?.settings.arguments as String,
                tripDetails: ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>,
              ),
          '/tripdetails/': (context) => TripDetailsScreen(
                tripId: ModalRoute.of(context)?.settings.arguments as String,
                tripDetails: ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>,
              ),
        },
      );
    }
  }

  class HomePage extends StatefulWidget {
    const HomePage({super.key});

    @override
    State<HomePage> createState() => _HomePageState();
  }

  class _HomePageState extends State<HomePage> {
    final _navigatorKey = GlobalKey<NavigatorState>();
    late AppLinks _appLinks;
    StreamSubscription<Uri>? _linkSubscription;

    @override
    void initState() {
      super.initState();
      initDeepLinks();
    }

    @override
    void dispose() {
      _linkSubscription?.cancel();
      super.dispose();
    }

    Future<void> initDeepLinks() async {
      _appLinks = AppLinks();
      _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
        openAppLink(uri);
      });
    }

    void openAppLink(Uri uri) {
  print('Received URI: $uri');
  
  // Always navigate to WelcomeView regardless of the path segments
  _navigatorKey.currentState?.pushNamed('/');
}
    @override
    Widget build(BuildContext context) {
      return FutureBuilder(
        future: AuthService.firebase().initialize(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final user = AuthService.firebase().currentUser;
            if (user != null) {
              if (user.isEmailVerified) {
                return const TripsView();
              } else {
                return const VerifyEmailView();
              }
            } else {
              return const WelcomeView();
            }
          } else {
            return const SplashScreen();
          }
        },
      );
    }
  }
