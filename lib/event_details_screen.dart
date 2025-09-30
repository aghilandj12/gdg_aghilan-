import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EventDetailsScreen extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  EventDetailsScreen({required this.eventId, required this.eventData});

  final CollectionReference rsvpRef = FirebaseFirestore.instance.collection('rsvps');
  final CollectionReference eventsRef = FirebaseFirestore.instance.collection('events');

  void joinEvent(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if user already joined
    final alreadyJoined = await rsvpRef
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: user.uid)
        .get();

    if (alreadyJoined.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You already joined ${eventData['name']}")));
      return;
    }

    await rsvpRef.add({
      'eventId': eventId,
      'userId': user.uid,
      'joinedAt': Timestamp.now(),
    });

    await eventsRef.doc(eventId).update({'rsvps': FieldValue.increment(1)});

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Successfully joined ${eventData['name']}")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(eventData['name']),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Name
                Center(
                  child: Text(
                    eventData['name'],
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),

                // Date
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text('Date: ${eventData['date']}', style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 10),

                // Time
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text('Time: ${eventData['time']}', style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 10),

                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.teal),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('Location: ${eventData['location']}', style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Description
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 6),
                Text(eventData['description'] ?? "No description", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),

                // Booked Seats
                Row(
                  children: [
                    const Icon(Icons.event_seat, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text('Booked Seats: ${eventData['rsvps'] ?? 0}', style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 30),

                // Join Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => joinEvent(context),
                    icon: const Icon(Icons.add),
                    label: const Text("Join Event", style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
