import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

  Future<Map<String, dynamic>?> _getUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: data?["photoURL"] != null
                      ? NetworkImage(data!["photoURL"])
                      : const AssetImage("assets/default_avatar.png")
                            as ImageProvider,
                ),
                const SizedBox(height: 16),
                Text(
                  data?["name"] ?? "No name",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(data?["email"] ?? "No email"),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pop(); // back to home
                  },
                  child: const Text("Sign Out"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
