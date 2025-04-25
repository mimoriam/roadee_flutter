import 'package:flutter/material.dart';

import 'package:roadee_flutter/screens/signup_screen.dart';
import 'package:roadee_flutter/screens/forgot_password_screen.dart';
import 'package:roadee_flutter/screens/home_screen.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:firebase_auth/firebase_auth.dart';

extension StringExtension on String {
  String toCapitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  String error = '';

  Future<UserCredential?> authenticate() async {
    setState(() {
      error = '';
    });

    try {
      final user = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _formKey.currentState?.fields['email']?.value,
        password: _formKey.currentState?.fields['password']?.value,
      );

      return user;
    } on FirebaseAuthException {
      setState(() {
        // error = e.message ?? 'Authentication error';
        error = "Authentication error";
      });
    } catch (e) {
      setState(() {
        error = 'Unexpected error occurred';
      });
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF128f8b),
      // resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    reverse: true,
                    padding: EdgeInsets.only(
                      left: 24.0,
                      right: 24.0,
                      // top: height * 0.1,
                      // bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: FormBuilder(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              const SizedBox(height: 200),
                              const Text(
                                'Log In',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (error.isNotEmpty)
                                Text(
                                  error,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              const SizedBox(height: 22),
                              _buildTextField(
                                name: 'email',
                                autovalidateMode: AutovalidateMode.onUnfocus,
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                  FormBuilderValidators.email(),
                                ]),
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                name: 'password',
                                obscureText: true,
                                autovalidateMode: AutovalidateMode.onUnfocus,
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                  FormBuilderValidators.minLength(6),
                                ]),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // Handle forgot password
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildButtonRow(),
                              // const Spacer(flex: 2),
                              SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            MediaQuery.of(context).viewInsets.bottom == 0.0
                ? Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      // margin: const EdgeInsets.only(bottom: 8.0),
                      width: 135,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                )
                : Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String name,
    required AutovalidateMode autovalidateMode,
    required validator,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: FormBuilderTextField(
        name: name,
        autovalidateMode: autovalidateMode,
        validator: validator,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: name.toCapitalize(),
          hintStyle: TextStyle(color: Color(0xFF799ac2), fontSize: 18),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildButtonRow() {
    return Row(
      children: [
        Expanded(
          child: _buildButton(
            text: 'Sign Up',
            onPressed: () {
              // Navigate to sign up screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SignUpScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildButton(
            text: 'Log In',
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                // Process login logic
                final user = await authenticate();
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildButton({required String text, required VoidCallback onPressed}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF0a6966), // Slightly darker green than background
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
