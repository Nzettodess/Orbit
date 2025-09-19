import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'login.dart';
import 'profile.dart';

class HomeWithLogin extends StatefulWidget {
  const HomeWithLogin({super.key});

  @override
  State<HomeWithLogin> createState() => _HomeWithLoginState();
}

class _HomeWithLoginState extends State<HomeWithLogin> {
  User? _user = FirebaseAuth.instance.currentUser;
  String? _photoUrl; // ✅ Avatar URL from Firestore

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _handleLoginSuccess() async {
    setState(() {
      _user = FirebaseAuth.instance.currentUser;
    });
    await _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (_user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(_user!.uid)
        .get();

    if (doc.exists) {
      setState(() {
        _photoUrl = doc.data()?['photoURL'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = _user != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        // ✅ Header changes depending on login state
        title: loggedIn
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset("assets/logo.png", height: 40),
                  GestureDetector(
                    onTap: () {
                      if (_user != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfilePage(user: _user!), // ✅ Pass user
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: _photoUrl != null
                          ? NetworkImage(_photoUrl!)
                          : const AssetImage("assets/default_avatar.png")
                                as ImageProvider,
                    ),
                  ),
                ],
              )
            : Center(child: Image.asset("assets/logo.png", height: 40)),
      ),
      body: Stack(
        children: [
          // ✅ Calendar is always there
          SfCalendar(view: CalendarView.month),

          // ✅ Login overlay
          if (!loggedIn) ...[
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withOpacity(0.2)),
              ),
            ),
            LoginOverlay(onSignedIn: _handleLoginSuccess),
          ],
        ],
      ),
    );
  }
}
