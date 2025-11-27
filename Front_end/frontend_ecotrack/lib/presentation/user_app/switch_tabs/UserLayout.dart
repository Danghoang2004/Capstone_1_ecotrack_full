import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/presentation/user_app/Home/Home_screen.dart';
import 'package:frontend_ecotrack/presentation/user_app/Map/Map_page.dart';
import 'package:frontend_ecotrack/presentation/user_app/Setting/Setting_page.dart';
import 'package:frontend_ecotrack/presentation/user_app/profile/ProfileScreen.dart';

class Userlayout extends StatefulWidget {
  const Userlayout({super.key});

  @override
  State<Userlayout> createState() => _UserlayoutState();
}

class _UserlayoutState extends State<Userlayout> {
  int currentIndex = 0;

  final List<Widget> screens = [
    HomeScreen(),
    MapPage(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (value) {
            setState(() {
              currentIndex = value;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          elevation: 12,
          selectedItemColor: const Color.fromARGB(255, 1, 95, 1),
          unselectedItemColor: const Color.fromARGB(255, 0, 0, 0),
          selectedFontSize:12,
          unselectedFontSize: 11,
          iconSize: 18,
          items: [
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.home_rounded),
              ),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.map),
              ),
              label: 'Map',
            ),
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.person_rounded),
              ),
              label: 'Profile',
            ),
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.settings),
              ),
              label: 'Setting',
            ),
          ],
        ),
      ),
    );
  }
}
