import 'package:flutter/material.dart';
import 'package:grtoco/services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.resetPassword)),
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              SizedBox(height: 20.0),
              TextFormField(
                decoration: InputDecoration(hintText: AppLocalizations.of(context)!.email),
                validator: (val) => val!.isEmpty ? AppLocalizations.of(context)!.enterAnEmail : null,
                onChanged: (val) {
                  setState(() => email = val);
                },
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                child: Text(AppLocalizations.of(context)!.sendResetEmail),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _auth.sendPasswordResetEmail(email);
                    setState(() => message = AppLocalizations.of(context)!.passwordResetEmailSent);
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
