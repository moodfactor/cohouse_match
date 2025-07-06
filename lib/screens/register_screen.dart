import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cohouse_match/services/auth_service.dart';
import 'package:cohouse_match/screens/wrapper.dart';

class RegisterScreen extends StatefulWidget {
  final Function toggleView;
  const RegisterScreen({super.key, required this.toggleView});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register to CohouseMatch'),
        actions: <Widget>[
          TextButton.icon(
            icon: const Icon(Icons.person),
            label: const Text('Sign In'),
            onPressed: () {
              widget.toggleView();
            },
          )
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 20.0),
              TextFormField(
                decoration: const InputDecoration(hintText: 'Email'),
                validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                onChanged: (val) {
                  setState(() => email = val);
                },
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                decoration: const InputDecoration(hintText: 'Password'),
                obscureText: true,
                validator: (val) =>
                    val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                onChanged: (val) {
                  setState(() => password = val);
                },
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                child: const Text('Register'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      error = ''; // Clear any previous errors
                    });
                    try {
                      User? result = await _auth.registerWithEmail(email, password);
                      if (result == null) {
                        if (!mounted) return;
                        setState(() {
                          error = 'Registration failed. Please try again.';
                        });
                      } else {
                        // Force a rebuild of the Wrapper to check profile status
                        if (!mounted) return; // Add mounted check here
                        Provider.of<User?>(context, listen: false);
                        // Navigate to home wrapper which will handle onboarding if needed
                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const Wrapper()),
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      if (!mounted) return;
                      setState(() {
                        // Provide more specific error messages for common cases
                        if (e.code == 'weak-password') {
                          error = 'The password provided is too weak.';
                        } else if (e.code == 'email-already-in-use') {
                          error = 'An account already exists for that email.';
                        } else if (e.code == 'invalid-email') {
                          error = 'The email address is invalid.';
                        } else {
                          error = e.message ?? 'An unknown error occurred';
                        }
                      });
                    } catch (e) {
                      if (!mounted) return;
                      setState(() {
                        error = 'Registration failed: ${e.toString()}';
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 12.0),
              Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 14.0),
              )
            ],
          ),
        ),
      ),
    );
  }
}