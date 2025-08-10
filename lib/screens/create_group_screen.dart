import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:grtoco/models/group.dart';
import 'package:grtoco/services/group_service.dart';

class CreateGroupScreen extends StatefulWidget {
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  // Step 1: Basic Details
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  GroupType _groupType = GroupType.public;
  File? _profileImage;
  List<String> _tags = [];

  // Step 2: Posting Permissions
  String _postingPermissions = 'allMembers';

  // Step 3: Group Rules
  final List<TextEditingController> _ruleControllers = [TextEditingController()];

  bool _isLoading = false;
  final GroupService _groupService = GroupService();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _ruleControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _nextPage() {
    if (_pageController.page == 0) {
      if (_formKey.currentState!.validate()) {
        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    } else {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _updateTags(String text) {
    setState(() {
      _tags = text
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
          .split(' ')
          .where((word) => word.length > 2)
          .toSet()
          .toList();
    });
  }

  void _addRuleField() {
    setState(() {
      _ruleControllers.add(TextEditingController());
    });
  }

  void _removeRuleField(int index) {
    setState(() {
      _ruleControllers[index].dispose();
      _ruleControllers.removeAt(index);
    });
  }

  void _showPreview() {
    // Navigate to a new screen to show the preview
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupPreviewScreen(
          groupName: _nameController.text,
          description: _descriptionController.text,
          groupType: _groupType,
          profileImage: _profileImage,
          postingPermissions: _postingPermissions,
          rules: _ruleControllers.map((c) => c.text).where((r) => r.isNotEmpty).toList(),
          tags: _tags,
          onSave: _createGroup,
        ),
      ),
    );
  }

  void _createGroup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<String> rules = _ruleControllers
          .map((controller) => controller.text.trim())
          .where((rule) => rule.isNotEmpty)
          .toList();

      await _groupService.createGroup(
        groupName: _nameController.text,
        description: _descriptionController.text,
        groupType: _groupType,
        tags: _tags,
        postingPermissions: _postingPermissions,
        rules: rules,
        profileImage: _profileImage,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group created successfully!')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Group'),
      ),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          _buildBasicDetailsPage(),
          _buildPostingPermissionsPage(),
          _buildGroupRulesPage(),
        ],
      ),
      bottomNavigationBar: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_pageController.hasClients && _pageController.page != 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: Text('Back'),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      if (_pageController.page == 2) {
                        _showPreview();
                      } else {
                        _nextPage();
                      }
                    },
                    child: Text(_pageController.hasClients && _pageController.page == 2
                        ? 'Preview'
                        : 'Next'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBasicDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null ? Icon(Icons.group, size: 50) : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.camera_alt),
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Group Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a group name';
                }
                return null;
              },
              onChanged: _updateTags,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
              onChanged: _updateTags,
            ),
            SizedBox(height: 16),
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8.0,
                children: _tags.map((tag) => Chip(label: Text(tag))).toList(),
              ),
            SizedBox(height: 16),
            Text('Group Type'),
            RadioListTile<GroupType>(
              title: const Text('Public'),
              subtitle: Text('Anyone can find and join this group.'),
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
              subtitle: Text('Only invited members can find and join this group.'),
              value: GroupType.secret,
              groupValue: _groupType,
              onChanged: (GroupType? value) {
                setState(() {
                  _groupType = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostingPermissionsPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who can post in this group?',
            style: Theme.of(context).textTheme.headline6,
          ),
          SizedBox(height: 16),
          RadioListTile<String>(
            title: const Text('All Members'),
            subtitle: Text('Any member of the group can create a new post.'),
            value: 'allMembers',
            groupValue: _postingPermissions,
            onChanged: (String? value) {
              setState(() {
                _postingPermissions = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Admins Only'),
            subtitle: Text('Only group admins can create new posts.'),
            value: 'adminsOnly',
            groupValue: _postingPermissions,
            onChanged: (String? value) {
              setState(() {
                _postingPermissions = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupRulesPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set the rules for your group',
            style: Theme.of(context).textTheme.headline6,
          ),
          SizedBox(height: 8),
          Text(
            'Create a positive and constructive environment by setting clear rules.',
            style: Theme.of(context).textTheme.caption,
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _ruleControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ruleControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Rule ${index + 1}',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      if (index > 0)
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline),
                          onPressed: () => _removeRuleField(index),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
          TextButton.icon(
            onPressed: _addRuleField,
            icon: Icon(Icons.add),
            label: Text('Add another rule'),
          ),
        ],
      ),
    );
  }
}

class GroupPreviewScreen extends StatelessWidget {
  final String groupName;
  final String? description;
  final GroupType groupType;
  final File? profileImage;
  final String postingPermissions;
  final List<String> rules;
  final List<String> tags;
  final VoidCallback onSave;

  const GroupPreviewScreen({
    Key? key,
    required this.groupName,
    this.description,
    required this.groupType,
    this.profileImage,
    required this.postingPermissions,
    required this.rules,
    required this.tags,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview Group'),
        actions: [
          TextButton(
            onPressed: onSave,
            child: Text('Create', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: profileImage != null ? FileImage(profileImage!) : null,
                  child: profileImage == null ? Icon(Icons.group, size: 40) : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: Theme.of(context).textTheme.headline5,
                      ),
                      SizedBox(height: 4),
                      Text(
                        groupType.toString().split('.').last,
                        style: Theme.of(context).textTheme.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (tags.isNotEmpty) ...[
              SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                children: tags.map((tag) => Chip(label: Text(tag))).toList(),
              ),
            ],
            SizedBox(height: 24),
            if (description != null && description!.isNotEmpty) ...[
              Text(
                'Description',
                style: Theme.of(context).textTheme.headline6,
              ),
              SizedBox(height: 8),
              Text(description!),
              SizedBox(height: 24),
            ],
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.post_add),
              title: Text('Posting Permissions'),
              subtitle: Text(postingPermissions == 'allMembers'
                  ? 'All members can post'
                  : 'Only admins can post'),
            ),
            SizedBox(height: 24),
            if (rules.isNotEmpty) ...[
              Text(
                'Group Rules',
                style: Theme.of(context).textTheme.headline6,
              ),
              SizedBox(height: 8),
              for (int i = 0; i < rules.length; i++)
                ListTile(
                  leading: Text('${i + 1}.'),
                  title: Text(rules[i]),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
