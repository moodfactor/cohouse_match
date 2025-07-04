import 'package:cohouse_match/screens/matches_screen.dart';
import 'package:cohouse_match/screens/messages_screen.dart';
import 'package:cohouse_match/screens/profile_screen.dart';
import 'package:cohouse_match/screens/swipe_screen.dart';
import 'package:cohouse_match/services/presence_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

// Add 'WidgetsBindingObserver' to listen to app lifecycle changes
class _HomeWrapperState extends State<HomeWrapper> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final PresenceService _presenceService = PresenceService();

  static final List<Widget> _widgetOptions = <Widget>[
    const SwipeScreen(),
    const MatchesScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Add the observer to listen for lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Set user online status when HomeWrapper is first built
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      _presenceService.setUserOnline(user.uid);
    }
  }

  @override
  void dispose() {
    // Set user offline when the app is fully closed
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      _presenceService.setUserOffline(user.uid);
    }
    // Remove the observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    // Update status based on app state
    if (state == AppLifecycleState.resumed) {
      _presenceService.setUserOnline(user.uid);
    } else {
      _presenceService.setUserOffline(user.uid);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}