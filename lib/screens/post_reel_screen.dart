import 'dart:io';
import 'package:flutter/material.dart';
import 'package:grtoco/models/group.dart';
import 'package:grtoco/services/group_service.dart';
import 'package:grtoco/services/reel_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostReelScreen extends StatefulWidget {
  @override
  _PostReelScreenState createState() => _PostReelScreenState();
}

class _PostReelScreenState extends State<PostReelScreen> {
  final GroupService _groupService = GroupService();
  final ReelService _reelService = ReelService();
  final _captionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Group> _userGroups = [];
  Group? _selectedGroup;
  XFile? _videoFile;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserGroups();
  }

  Future<void> _loadUserGroups() async {
    final currentUser = context.read<User?>();
    if (currentUser == null) {
      setState(() {
        _error = "You must be logged in to post a reel.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

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

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    setState(() {
      _videoFile = pickedFile;
    });
  }

  Future<void> _submitReel() async {
    if (_formKey.currentState!.validate() && _videoFile != null && _selectedGroup != null) {
      final currentUser = context.read<User?>();
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You must be logged in.")),
        );
        return;
      }

      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        await _reelService.createReel(
          videoPath: _videoFile!.path,
          groupId: _selectedGroup!.groupId,
          authorId: currentUser.uid,
          caption: _captionController.text,
        );
        Navigator.of(context).pop();
      } catch (e) {
        setState(() {
          _error = "Failed to post reel: $e";
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a group, a video, and add a caption.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post a Reel'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Group Selector
                          DropdownButtonFormField<Group>(
                            value: _selectedGroup,
                            hint: Text('Select a Group'),
                            items: _userGroups.map((group) {
                              return DropdownMenuItem<Group>(
                                value: group,
                                child: Text(group.groupName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedGroup = value;
                              });
                            },
                            validator: (value) => value == null ? 'Please select a group' : null,
                          ),
                          SizedBox(height: 20),

                          // Caption
                          TextFormField(
                            controller: _captionController,
                            decoration: InputDecoration(
                              labelText: 'Caption',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            validator: (value) => value == null || value.isEmpty ? 'Please enter a caption' : null,
                          ),
                          SizedBox(height: 20),

                          // Video Picker
                          ElevatedButton.icon(
                            onPressed: _pickVideo,
                            icon: Icon(Icons.video_library),
                            label: Text('Pick a Video'),
                          ),
                          if (_videoFile != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Video selected: ${_videoFile!.name}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          SizedBox(height: 40),

                          // Submit Button
                          ElevatedButton(
                            onPressed: _submitReel,
                            child: Text('Post Reel'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
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
