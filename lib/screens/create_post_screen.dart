import 'package:flutter/material.dart';
import 'package:grtoco/models/group.dart';
import 'package:grtoco/services/group_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum CreatePostType { post, poll, event, qa }

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final GroupService _groupService = GroupService();

  CreatePostType _selectedPostType = CreatePostType.post;
  Group? _selectedGroup;
  List<Group> _userGroups = [];
  bool _isLoading = false;
  String? _error;

  // Text Post
  final _textController = TextEditingController();

  // Poll
  final _pollQuestionController = TextEditingController();
  List<TextEditingController> _pollOptionControllers = [TextEditingController(), TextEditingController()];

  // Event
  final _eventNameController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  final _eventLocationController = TextEditingController();
  DateTime? _eventDate;

  // Q&A
  final _qaQuestionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserGroups();
  }

  Future<void> _loadUserGroups() async {
    final currentUser = context.read<User?>();
    if (currentUser == null) {
      setState(() => _error = "You must be logged in.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final groups = await _groupService.getUserGroups(currentUser.uid);
      setState(() {
        _userGroups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load groups: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create a Post')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildGroupSelector(),
                        SizedBox(height: 20),
                        _buildPostTypeSelector(),
                        SizedBox(height: 20),
                        _buildPostTypeFields(),
                        SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _submitPost,
                          child: Text('Submit'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildGroupSelector() {
    return DropdownButtonFormField<Group>(
      value: _selectedGroup,
      hint: Text('Select a Group'),
      items: _userGroups.map((group) {
        return DropdownMenuItem<Group>(
          value: group,
          child: Text(group.groupName),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedGroup = value),
      validator: (value) => value == null ? 'Please select a group' : null,
    );
  }

  Widget _buildPostTypeSelector() {
    return DropdownButtonFormField<CreatePostType>(
      value: _selectedPostType,
      items: CreatePostType.values.map((type) {
        return DropdownMenuItem<CreatePostType>(
          value: type,
          child: Text(type.toString().split('.').last.toUpperCase()),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedPostType = value!),
    );
  }

  Widget _buildPostTypeFields() {
    switch (_selectedPostType) {
      case CreatePostType.post:
        return _buildTextPostFields();
      case CreatePostType.poll:
        return _buildPollFields();
      case CreatePostType.event:
        return _buildEventFields();
      case CreatePostType.qa:
        return _buildQaFields();
    }
  }

  Widget _buildTextPostFields() {
    return TextFormField(
      controller: _textController,
      decoration: InputDecoration(labelText: 'What\'s on your mind?'),
      maxLines: 5,
      validator: (value) => value!.isEmpty ? 'Please enter some text' : null,
    );
  }

  Widget _buildPollFields() {
    return Column(
      children: [
        TextFormField(
          controller: _pollQuestionController,
          decoration: InputDecoration(labelText: 'Poll Question'),
          validator: (value) => value!.isEmpty ? 'Please enter a question' : null,
        ),
        SizedBox(height: 10),
        ..._pollOptionControllers.map((controller) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(labelText: 'Option'),
            ),
          );
        }).toList(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.remove_circle_outline),
              onPressed: () {
                if (_pollOptionControllers.length > 2) {
                  setState(() => _pollOptionControllers.removeLast());
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline),
              onPressed: () => setState(() => _pollOptionControllers.add(TextEditingController())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventFields() {
    return Column(
      children: [
        TextFormField(
          controller: _eventNameController,
          decoration: InputDecoration(labelText: 'Event Name'),
          validator: (value) => value!.isEmpty ? 'Please enter an event name' : null,
        ),
        TextFormField(
          controller: _eventDescriptionController,
          decoration: InputDecoration(labelText: 'Event Description'),
          maxLines: 3,
        ),
        TextFormField(
          controller: _eventLocationController,
          decoration: InputDecoration(labelText: 'Event Location'),
        ),
        SizedBox(height: 10),
        ListTile(
          title: Text(_eventDate == null ? 'Select Event Date' : 'Event Date: ${_eventDate!.toLocal()}'),
          trailing: Icon(Icons.calendar_today),
          onTap: _pickEventDate,
        ),
      ],
    );
  }

  Future<void> _pickEventDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          _eventDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Widget _buildQaFields() {
    return TextFormField(
      controller: _qaQuestionController,
      decoration: InputDecoration(labelText: 'Your Question'),
      validator: (value) => value!.isEmpty ? 'Please enter a question' : null,
    );
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate() || _selectedGroup == null) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      switch (_selectedPostType) {
        case CreatePostType.post:
          // This will be handled by a new method in GroupService
          // await _groupService.createPost(...);
          break;
        case CreatePostType.poll:
          await _groupService.createInteractivePost(
            groupId: _selectedGroup!.groupId,
            postType: 'poll',
            question: _pollQuestionController.text,
            options: _pollOptionControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList(),
          );
          break;
        case CreatePostType.event:
          await _groupService.createInteractivePost(
            groupId: _selectedGroup!.groupId,
            postType: 'event',
            eventName: _eventNameController.text,
            eventDescription: _eventDescriptionController.text,
            eventLocation: _eventLocationController.text,
            eventDate: _eventDate,
          );
          break;
        case CreatePostType.qa:
          await _groupService.createInteractivePost(
            groupId: _selectedGroup!.groupId,
            postType: 'qa',
            question: _qaQuestionController.text,
          );
          break;
      }
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = "Failed to create post: $e";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _pollQuestionController.dispose();
    _pollOptionControllers.forEach((c) => c.dispose());
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    _eventLocationController.dispose();
    _qaQuestionController.dispose();
    super.dispose();
  }
}
