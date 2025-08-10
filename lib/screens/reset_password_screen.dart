import 'package:flutter/material.dart';
import 'package:grtoco/services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reset Password')),
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              SizedBox(height: 20.0),
              TextFormField(
                decoration: InputDecoration(hintText: 'Email'),
                validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                onChanged: (val) {
                  setState(() => email = val);
                },
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                child: Text('Send Reset Email'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _auth.sendPasswordResetEmail(email);
                    setState(() => message = 'Password reset email sent');
                  }
                },
              ),
              SizedBox(height: 12.0),
              Text(
                message,
                style: TextStyle(color: Colors.green, fontSize: 14.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
