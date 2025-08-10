import 'package:flutter/material.dart';
import 'package:grtoco/models/group.dart';
import 'package:grtoco/services/group_service.dart';

class CreateGroupScreen extends StatefulWidget {
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  GroupType _groupType = GroupType.public;
  bool _isLoading = false;

  final GroupService _groupService = GroupService();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _createGroup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        List<String> tags = _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();

        await _groupService.createGroup(
          groupName: _nameController.text,
          description: _descriptionController.text,
          groupType: _groupType,
          tags: tags,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group created successfully!')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Group'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Group Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 16),
              Text('Group Type'),
              RadioListTile<GroupType>(
                title: const Text('Public'),
                value: GroupType.public,
                groupValue: _groupType,
                onChanged: (GroupType? value) {
                  setState(() {
                    _groupType = value!;
                  });
                },
              ),
              RadioListTile<GroupType>(
                title: const Text('Secret'),
                value: GroupType.secret,
                groupValue: _groupType,
                onChanged: (GroupType? value) {
                  setState(() {
                    _groupType = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: 'Tags (comma-separated)',
                ),
              ),
              SizedBox(height: 24),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _createGroup,
                      child: Text('Create Group'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
