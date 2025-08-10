import 'package:flutter/material.dart';
import 'package:grtoco/services/auth_service.dart';
import 'package:grtoco/screens/home_screen.dart'; // Placeholder for home screen
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String displayName = '';
  String error = '';
  String? languageCode;

  @override
  void initState() {
    super.initState();
    _getLanguageCode();
  }

  Future<void> _getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      languageCode = prefs.getString('languageCode');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.register)),
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              SizedBox(height: 20.0),
              TextFormField(
                decoration: InputDecoration(hintText: AppLocalizations.of(context)!.displayName),
                validator: (val) => val!.isEmpty ? AppLocalizations.of(context)!.enterADisplayName : null,
                onChanged: (val) {
                  setState(() => displayName = val);
                },
              ),
              SizedBox(height: 20.0),
              TextFormField(
                decoration: InputDecoration(hintText: AppLocalizations.of(context)!.email),
                validator: (val) => val!.isEmpty ? AppLocalizations.of(context)!.enterAnEmail : null,
                onChanged: (val) {
                  setState(() => email = val);
                },
              ),
              SizedBox(height: 20.0),
              TextFormField(
                decoration: InputDecoration(hintText: AppLocalizations.of(context)!.password),
                obscureText: true,
                validator: (val) => val!.length < 6 ? AppLocalizations.of(context)!.enterAPassword : null,
                onChanged: (val) {
                  setState(() => password = val);
                },
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                child: Text(AppLocalizations.of(context)!.register),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    dynamic result = await _auth.signUpWithEmailAndPassword(email, password, displayName, languageCode ?? 'en');
                    if (result == null) {
                      setState(() => error = AppLocalizations.of(context)!.pleaseSupplyAValidEmail);
                    } else {
                       Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen()),
                      );
                    }
                  }
                },
              ),
              SizedBox(height: 12.0),
              Text(
                error,
                style: TextStyle(color: Colors.red, fontSize: 14.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
