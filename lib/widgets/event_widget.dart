import 'package:flutter/material.dart';
import 'package:grtoco/models/interactive_post.dart';
import 'package:grtoco/services/group_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EventWidget extends StatefulWidget {
  final InteractivePost event;

  const EventWidget({Key? key, required this.event}) : super(key: key);

  @override
  _EventWidgetState createState() => _EventWidgetState();
}

class _EventWidgetState extends State<EventWidget> {
  late GroupService _groupService;
  bool _isAttending = false;

  @override
  void initState() {
    super.initState();
    _groupService = GroupService();
    _checkIfAttending();
  }

  void _checkIfAttending() {
    final userId = context.read<User?>()?.uid;
    if (userId == null) return;
    setState(() {
      _isAttending = widget.event.attendees?.contains(userId) ?? false;
    });
  }

  Future<void> _toggleAttendance() async {
    final userId = context.read<User?>()?.uid;
    if (userId == null) return;

    try {
      if (_isAttending) {
        // For simplicity, we are not implementing leaving an event.
        // In a real app, you would add a `leaveEvent` method to the service.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You are already attending this event.")),
        );
        return;
      }

      await _groupService.joinEvent(widget.event.postId);
      setState(() {
        _isAttending = true;
        // Optimistically update the UI
        widget.event.attendees?.add(userId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update attendance: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = widget.event.eventDate != null
        ? DateFormat.yMMMd().add_jm().format(widget.event.eventDate!)
        : 'Date not set';

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event.eventName ?? 'Event',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 8),
            Text(
              widget.event.eventDescription ?? '',
              style: Theme.of(context).textTheme.bodyText2,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16),
                SizedBox(width: 8),
                Text(formattedDate),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16),
                SizedBox(width: 8),
                Text(widget.event.eventLocation ?? 'Location not set'),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _toggleAttendance,
              child: Text(_isAttending ? 'Attending' : 'Participă'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAttending ? Colors.green : Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
