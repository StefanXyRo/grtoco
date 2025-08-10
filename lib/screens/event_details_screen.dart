import 'package:flutter/material.dart';
import 'package:grtoco/models/interactive_post.dart';

class EventDetailsScreen extends StatefulWidget {
  final InteractivePost event;

  const EventDetailsScreen({Key? key, required this.event}) : super(key: key);

  @override
  _EventDetailsScreenState createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.eventName ?? 'Event Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.event.eventDescription ?? '',
                style: Theme.of(context).textTheme.bodyText1,
              ),
              SizedBox(height: 20),
              // Map widget will go here
              Container(
                height: 200,
                color: Colors.grey[300],
                child: Center(child: Text('Map Placeholder')),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement "Add to Calendar" functionality
                },
                icon: Icon(Icons.calendar_today),
                label: Text('Adaugă în calendar'),
              ),
              SizedBox(height: 20),
              Text(
                'Discuții despre eveniment',
                style: Theme.of(context).textTheme.headline6,
              ),
              // Chat section will go here
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text('Chat Placeholder')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
