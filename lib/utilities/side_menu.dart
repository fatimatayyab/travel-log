import 'package:flutter/material.dart';
import 'package:travellog3/services/auth/auth_service.dart';
import 'package:travellog3/utilities/show_logout_dialog.dart';


class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.6,
      // Decrease the width to 80% of the screen width
      child: Drawer(
        child: SizedBox(
          height: MediaQuery.of(context).size.height *
              0.4, // Set the height to 60% of screen height
          child: Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.15,
                padding: const EdgeInsets.all(8.0), // Reduce padding
                color: const Color.fromARGB(255, 202, 138, 234),
                child: const Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20, // Reduce the font size
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.home),
                      title: const Text('My Trips'),
                      onTap: () {
                        Navigator.pushNamed(context, '/tripsview/');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.add_circle),
                      title: const Text('Add New Trip'),
                      onTap: () {
                        Navigator.pushNamed(context, '/mapview/');
                      },
                    ),
                    const Divider(),
                    ListTile(
                        leading: const Icon(Icons.account_circle),
                        title: const Text('Profile'),
                        onTap: () async {
                          Navigator.pushNamed(context, '/userprofile/');
                          
                        }),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.favorite),
                      title: const Text('Favorites'),
                      onTap: () {
                        Navigator.pushNamed(context, '/favouritetrip/');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Logout'),
                      onTap: () async {
                        final shouldLogout = await showLogoutDialog(context);
                        if (shouldLogout) {
                          await AuthService.firebase().logOut();
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login/', (route) => false);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
