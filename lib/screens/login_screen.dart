import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cohouse_match/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cohouse_match/screens/wrapper.dart';

class LoginScreen extends StatefulWidget {
  final Function toggleView;
  const LoginScreen({super.key, required this.toggleView});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
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
      appBar: AppBar(
        title: const Text('Login to CohouseMatch'),
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
                child: const Text('Sign In'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      error = ''; // Clear any previous errors
                    });
                    try {
                      User? result = await _auth.signInWithEmail(email, password);
                      if (result == null) {
                        setState(() {
                          error = 'Could not sign in with those credentials';
                        });
                      } else {
                        // Force a rebuild of the Wrapper to check profile status
                        // This ensures the user data stream is updated
                        Provider.of<User?>(context, listen: false);
                        
                        // Navigate to home wrapper which will handle onboarding if needed
                        // Using pushAndRemoveUntil to ensure clean navigation state
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const Wrapper()),
                          (route) => false, // Remove all previous routes
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      setState(() {
                        // Provide more specific error messages for common cases
                        if (e.code == 'user-not-found') {
                          error = 'No user found with this email.';
                        } else if (e.code == 'wrong-password') {
                          error = 'Wrong password provided.';
                        } else if (e.code == 'invalid-email') {
                          error = 'Invalid email address.';
                        } else {
                          error = e.message ?? 'An unknown error occurred';
                        }
                      });
                    } catch (e) {
                      setState(() {
                        error = 'An unexpected error occurred: $e';
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 12.0),
              Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 14.0),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                child: const Text('Sign In with Google'),
                onPressed: () async {
                  setState(() {
                    error = ''; // Clear any previous errors
                  });
                  try {
                    User? result = await _auth.signInWithGoogle();
                    if (result == null) {
                      setState(() {
                        error = 'Could not sign in with Google';
                      });
                    } else {
                      // Force a rebuild of the Wrapper to check profile status
                      // This ensures the user data stream is updated
                      Provider.of<User?>(context, listen: false);
                      
                      // Navigate to home wrapper which will handle onboarding if needed
                      // Using pushAndRemoveUntil to ensure clean navigation state
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const Wrapper()),
                        (route) => false, // Remove all previous routes
                      );
                    }
                  } catch (e) {
                    setState(() {
                      error = 'Google sign in failed: ${e.toString()}';
                    });
                  }
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.person),
                label: const Text('Register'),
                onPressed: () {
                  widget.toggleView();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}