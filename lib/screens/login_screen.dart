import 'package:flutter/material.dart';
import 'package:grtoco/services/auth_service.dart';
import 'package:grtoco/screens/register_screen.dart';
import 'package:grtoco/screens/reset_password_screen.dart';
import 'package:grtoco/screens/home_screen.dart'; // Placeholder for home screen
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.login)),
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
                child: Text(AppLocalizations.of(context)!.signIn),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    dynamic result = await _auth.signInWithEmailAndPassword(email, password);
                    if (result == null) {
                      setState(() => error = AppLocalizations.of(context)!.signInFailed);
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
              TextButton(
                child: Text(AppLocalizations.of(context)!.dontHaveAnAccount),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
              ),
              TextButton(
                child: Text(AppLocalizations.of(context)!.forgotPassword),
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ResetPasswordScreen()),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
