import 'package:cloud_firestore/cloud_firestore.dart';

enum InteractivePostType { poll, event, qa }

class InteractivePost {
  final String postId;
  final String groupId;
  final String authorId;
  final InteractivePostType postType;
  final DateTime timestamp;

  // Poll fields
  final String? question;
  final List<String>? options;
  final Map<String, List<String>>? votes;
  final bool? isClosed;

  // Event fields
  final String? eventName;
  final String? eventDescription;
  final DateTime? eventDate;
  final String? eventLocation;
  final GeoPoint? eventLocationCoordinates;
  final Map<String, List<String>>? rsvpStatus;

  // Q&A fields
  final List<Map<String, dynamic>>? answers;

  InteractivePost({
    required this.postId,
    required this.groupId,
    required this.authorId,
    required this.postType,
    required this.timestamp,
    this.question,
    this.options,
    this.votes,
    this.isClosed,
    this.eventName,
    this.eventDescription,
    this.eventDate,
    this.eventLocation,
    this.eventLocationCoordinates,
    this.rsvpStatus,
    this.answers,
  });

  factory InteractivePost.fromJson(Map<String, dynamic> json) {
    return InteractivePost(
      postId: json['postId'] as String,
      groupId: json['groupId'] as String,
      authorId: json['authorId'] as String,
      postType: InteractivePostType.values.firstWhere(
        (e) => e.toString() == 'InteractivePostType.${json['postType']}',
      ),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      question: json['question'] as String?,
      options: List<String>.from(json['options'] ?? []),
      votes: (json['votes'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ),
      isClosed: json['isClosed'] as bool?,
      eventName: json['eventName'] as String?,
      eventDescription: json['eventDescription'] as String?,
      eventDate: json['eventDate'] != null
          ? (json['eventDate'] as Timestamp).toDate()
          : null,
      eventLocation: json['eventLocation'] as String?,
      eventLocationCoordinates: json['eventLocationCoordinates'] as GeoPoint?,
      rsvpStatus: (json['rsvpStatus'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ),
      answers: (json['answers'] as List<dynamic>?)
          ?.map((answer) => {
                'authorId': answer['authorId'] as String,
                'answerContent': answer['answerContent'] as String,
                'timestamp': (answer['timestamp'] as Timestamp).toDate(),
              })
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'groupId': groupId,
      'authorId': authorId,
      'postType': postType.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'question': question,
      'options': options,
      'votes': votes,
      'isClosed': isClosed,
      'eventName': eventName,
      'eventDescription': eventDescription,
      'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
      'eventLocation': eventLocation,
      'eventLocationCoordinates': eventLocationCoordinates,
      'rsvpStatus': rsvpStatus,
      'answers': answers
          ?.map((answer) => {
                'authorId': answer['authorId'],
                'answerContent': answer['answerContent'],
                'timestamp': Timestamp.fromDate(answer['timestamp']),
              })
          .toList(),
    };
  }
}
