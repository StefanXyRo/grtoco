import 'dart:io';
import 'package:flutter/material.dart';
import 'package:grtoco/models/user.dart';
import 'package:grtoco/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  EditProfileScreen({required this.user});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  late String _displayName;
  late String _bio;
  XFile? _image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _displayName = widget.user.displayName ?? '';
    _bio = widget.user.bio ?? '';
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      await _authService.updateUserProfile(
        uid: widget.user.uid,
        displayName: _displayName,
        bio: _bio,
        image: _image,
      );

      setState(() {
        _isLoading = false;
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _image != null
                            ? FileImage(File(_image!.path))
                            : (widget.user.photoURL != null && widget.user.photoURL!.isNotEmpty
                                ? NetworkImage(widget.user.photoURL!)
                                : null) as ImageProvider?,
                        child: _image == null && (widget.user.photoURL == null || widget.user.photoURL!.isEmpty)
                            ? Icon(Icons.camera_alt, size: 50)
                            : null,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      initialValue: _displayName,
                      decoration: InputDecoration(labelText: 'Display Name'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a display name' : null,
                      onSaved: (value) => _displayName = value!,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      initialValue: _bio,
                      decoration: InputDecoration(labelText: 'Bio'),
                      onSaved: (value) => _bio = value!,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
