import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class OrganizerDashboard extends StatefulWidget {
  final User user; // Received from login

  OrganizerDashboard({required this.user});

  @override
  _OrganizerDashboardState createState() => _OrganizerDashboardState();
}

class _OrganizerDashboardState extends State<OrganizerDashboard> {
  final CollectionReference eventsRef = FirebaseFirestore.instance.collection('events');

  final TextEditingController nameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  late User user;

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  void pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
        dateController.text = "${date.year}-${date.month}-${date.day}";
      });
    }
  }

  void pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
        timeController.text =
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  void addEvent() async {
    if (nameController.text.isEmpty ||
        dateController.text.isEmpty ||
        timeController.text.isEmpty ||
        locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    await eventsRef.add({
      'name': nameController.text,
      'date': dateController.text,
      'time': timeController.text,
      'location': locationController.text,
      'description': descriptionController.text,
      'createdBy': user.uid,
      'createdAt': Timestamp.now(),
      'rsvps': 0,
    });

    // Clear form
    nameController.clear();
    dateController.clear();
    timeController.clear();
    locationController.clear();
    descriptionController.clear();
    selectedDate = null;
    selectedTime = null;

    Navigator.pop(context);
  }

  void showAddEventDialog({Map<String, dynamic>? event, String? docId}) {
    if (event != null) {
      // Prefill fields for edit
      nameController.text = event['name'] ?? '';
      dateController.text = event['date'] ?? '';
      timeController.text = event['time'] ?? '';
      locationController.text = event['location'] ?? '';
      descriptionController.text = event['description'] ?? '';
    } else {
      // Clear for new event
      nameController.clear();
      dateController.clear();
      timeController.clear();
      locationController.clear();
      descriptionController.clear();
      selectedDate = null;
      selectedTime = null;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event == null ? "Create Event" : "Edit Event"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Event Name")),
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: const InputDecoration(labelText: "Date"),
                onTap: pickDate,
              ),
              TextField(
                controller: timeController,
                readOnly: true,
                decoration: const InputDecoration(labelText: "Time"),
                onTap: pickTime,
              ),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: "Location")),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (docId == null) {
                addEvent();
              } else {
                await eventsRef.doc(docId).update({
                  'name': nameController.text,
                  'date': dateController.text,
                  'time': timeController.text,
                  'location': locationController.text,
                  'description': descriptionController.text,
                });
                Navigator.pop(context);
              }
            },
            child: Text(event == null ? "Add" : "Update"),
          ),
        ],
      ),
    );
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();

    // Navigate to LoginScreen and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Organizer Dashboard"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: eventsRef
            .where('createdBy', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(child: Text("No events created yet."));

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final event = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(event['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('${event['date'] ?? ''} • ${event['time'] ?? ''}'),
                      Text('Location: ${event['location'] ?? ''}'),
                      Text('Booked Seats: ${event['rsvps'] ?? 0}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => showAddEventDialog(event: event, docId: docId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async => await eventsRef.doc(docId).delete(),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddEventDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
