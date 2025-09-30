import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'event_details_screen.dart';
import 'my_rsvps_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CollectionReference eventsRef = FirebaseFirestore.instance.collection('events');
  final CollectionReference rsvpRef = FirebaseFirestore.instance.collection('rsvps');

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void joinEvent(String eventId, String eventName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final alreadyJoined = await rsvpRef
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: user.uid)
        .get();

    if (alreadyJoined.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You already joined $eventName")),
      );
      return;
    }

    await rsvpRef.add({
      'eventId': eventId,
      'userId': user.uid,
      'joinedAt': Timestamp.now(),
    });

    await eventsRef.doc(eventId).update({
      'rsvps': FieldValue.increment(1),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Successfully joined $eventName")),
    );
  }

  void showEventDetails(Map<String, dynamic> event, String docId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(eventId: docId, eventData: event),
      ),
    );
  }

  void showMyRSVPs() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => MyRSVPScreen()));
  }

  void showProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upcoming Events"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(icon: const Icon(Icons.list_alt), onPressed: showMyRSVPs),
          IconButton(icon: const Icon(Icons.person), onPressed: showProfile),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: eventsRef.orderBy('date').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(child: Text("No events available."));

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final event = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return Card(
                margin: const EdgeInsets.all(12),
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => showEventDetails(event, docId),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event['name'],
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),

                        // Date and Time Row
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.teal),
                            const SizedBox(width: 6),
                            Text(event['date'], style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time, color: Colors.teal),
                            const SizedBox(width: 6),
                            Text(event['time'], style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Location
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.teal),
                            const SizedBox(width: 6),
                            Flexible(
                                child: Text(event['location'],
                                    style: const TextStyle(fontSize: 14))),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Booked Seats
                        Row(
                          children: [
                            const Icon(Icons.event_seat, color: Colors.teal),
                            const SizedBox(width: 6),
                            Text('Booked: ${event['rsvps'] ?? 0}',
                                style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Join Button
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () => joinEvent(docId, event['name']),
                            icon: const Icon(Icons.add),
                            label: const Text("Join Event"),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
