import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddEditEventScreen extends StatefulWidget {
final User user;
final Map<String, dynamic>? event;
final String? docId;

AddEditEventScreen({required this.user, this.event, this.docId});

@override
_AddEditEventScreenState createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
final CollectionReference eventsRef = FirebaseFirestore.instance.collection('events');

final TextEditingController nameController = TextEditingController();
final TextEditingController dateController = TextEditingController();
final TextEditingController timeController = TextEditingController();
final TextEditingController locationController = TextEditingController();
final TextEditingController descriptionController = TextEditingController();

DateTime? selectedDate;
TimeOfDay? selectedTime;

@override
void initState() {
super.initState();
if (widget.event != null) {
nameController.text = widget.event!['name'] ?? '';
dateController.text = widget.event!['date'] ?? '';
timeController.text = widget.event!['time'] ?? '';
locationController.text = widget.event!['location'] ?? '';
descriptionController.text = widget.event!['description'] ?? '';
}
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

void saveEvent() async {
if (widget.docId == null) {
await eventsRef.add({
'name': nameController.text,
'date': dateController.text,
'time': timeController.text,
'location': locationController.text,
'description': descriptionController.text,
'createdBy': widget.user.uid,
'createdAt': Timestamp.now(),
'rsvps': 0,
});
} else {
await eventsRef.doc(widget.docId).update({
'name': nameController.text,
'date': dateController.text,
'time': timeController.text,
'location': locationController.text,
'description': descriptionController.text,
});
}
Navigator.pop(context);
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: Text(widget.docId == null ? "Add Event" : "Edit Event"), backgroundColor: Colors.teal),
body: Padding(
padding: const EdgeInsets.all(16.0),
child: SingleChildScrollView(
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
const SizedBox(height: 20),
ElevatedButton(onPressed: saveEvent, child: Text(widget.docId == null ? "Add Event" : "Update Event"))
],
),
),
),
);
}
}
