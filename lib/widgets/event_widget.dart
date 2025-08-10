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
  String? _userRsvpStatus;

  @override
  void initState() {
    super.initState();
    _groupService = GroupService();
    _determineUserRsvpStatus();
  }

  void _determineUserRsvpStatus() {
    final userId = context.read<User?>()?.uid;
    if (userId == null) return;

    setState(() {
      if (widget.event.rsvpStatus?['going']?.contains(userId) ?? false) {
        _userRsvpStatus = 'going';
      } else if (widget.event.rsvpStatus?['interested']?.contains(userId) ?? false) {
        _userRsvpStatus = 'interested';
      } else if (widget.event.rsvpStatus?['notGoing']?.contains(userId) ?? false) {
        _userRsvpStatus = 'notGoing';
      } else {
        _userRsvpStatus = null;
      }
    });
  }

  Future<void> _updateRsvpStatus(String newStatus) async {
    final userId = context.read<User?>()?.uid;
    if (userId == null) return;

    final currentStatus = _userRsvpStatus;
    if (currentStatus == newStatus) {
      // User is tapping the same button again, do nothing or allow to un-select
      return;
    }

    // Optimistically update the UI
    setState(() {
      // Remove from the old list
      if (currentStatus != null) {
        widget.event.rsvpStatus?[currentStatus]?.remove(userId);
      }
      // Add to the new list
      widget.event.rsvpStatus?[newStatus]?.add(userId);
      _userRsvpStatus = newStatus;
    });

    try {
      await _groupService.updateRsvpStatus(widget.event.postId, newStatus);
    } catch (e) {
      // Revert the UI changes if the backend call fails
      setState(() {
        widget.event.rsvpStatus?[newStatus]?.remove(userId);
        if (currentStatus != null) {
          widget.event.rsvpStatus?[currentStatus]?.add(userId);
        }
        _userRsvpStatus = currentStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update RSVP status: $e')),
      );
    }
  }

import 'package:grtoco/screens/event_details_screen.dart';
...
  @override
  Widget build(BuildContext context) {
    final formattedDate = widget.event.eventDate != null
        ? DateFormat.yMMMd().add_jm().format(widget.event.eventDate!)
        : 'Date not set';

    final rsvpCounts = {
      'going': widget.event.rsvpStatus?['going']?.length ?? 0,
      'interested': widget.event.rsvpStatus?['interested']?.length ?? 0,
      'notGoing': widget.event.rsvpStatus?['notGoing']?.length ?? 0,
    };

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(event: widget.event),
          ),
        );
      },
      child: Card(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRsvpButton(context, 'going', 'Participă'),
                  _buildRsvpButton(context, 'interested', 'Interesat/ă'),
                  _buildRsvpButton(context, 'notGoing', 'Nu pot'),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('${rsvpCounts['going']} Participă'),
                  Text('${rsvpCounts['interested']} Interesați'),
                  Text('${rsvpCounts['notGoing']} Nu pot'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRsvpButton(BuildContext context, String status, String label) {
    final bool isSelected = _userRsvpStatus == status;
    return ElevatedButton(
      onPressed: () => _updateRsvpStatus(status),
      child: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Theme.of(context).primaryColor,
      ),
    );
  }
}
