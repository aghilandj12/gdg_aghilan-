import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'event_details_screen.dart';

class MyRSVPScreen extends StatelessWidget {
  final CollectionReference rsvpRef = FirebaseFirestore.instance.collection('rsvps');
  final CollectionReference eventsRef = FirebaseFirestore.instance.collection('events');

  void showEventDetails(BuildContext context, Map<String, dynamic> event, String docId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(eventId: docId, eventData: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("My RSVPs"), backgroundColor: Colors.teal),
      body: StreamBuilder<QuerySnapshot>(
        stream: rsvpRef.where('userId', isEqualTo: user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("You haven't joined any events."));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final rsvp = docs[index].data() as Map<String, dynamic>;
              return FutureBuilder<DocumentSnapshot>(
                future: eventsRef.doc(rsvp['eventId']).get(),
                builder: (context, eventSnap) {
                  if (!eventSnap.hasData) return const SizedBox();
                  final event = eventSnap.data!.data() as Map<String, dynamic>;
                  final docId = eventSnap.data!.id;

                  return Card(
                    margin: const EdgeInsets.all(12),
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => showEventDetails(context, event, docId),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event['name'],
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),

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

                            Row(
                              children: [
                                const Icon(Icons.event_seat, color: Colors.teal),
                                const SizedBox(width: 6),
                                Text('Booked: ${event['rsvps'] ?? 0}',
                                    style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
