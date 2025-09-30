import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrganizerProfileScreen extends StatelessWidget {
  final User user;

  OrganizerProfileScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [const Icon(Icons.person, color: Colors.teal), const SizedBox(width: 10), Text("Email: ${user.email}", style: const TextStyle(fontSize: 18))]),
                    const SizedBox(height: 12),
                    Row(children: [const Icon(Icons.admin_panel_settings, color: Colors.teal), const SizedBox(width: 10), const Text("Role: Organizer", style: TextStyle(fontSize: 18))]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
