import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:roadee_flutter/screens/login_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  String error = '';

  Future<UserCredential?> authenticate() async {
    setState(() {
      error = '';
    });

    try {
      final user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _formKey.currentState?.fields['email']?.value,
        password: _formKey.currentState?.fields['password']?.value,
      );

      return user;
    } on FirebaseAuthException {
      setState(() {
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
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    reverse: true,
                    padding: EdgeInsets.only(left: 24.0, right: 24.0),
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
                              const SizedBox(height: 100),
                              const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (error.isNotEmpty)
                                Text(
                                  error,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              const SizedBox(height: 30),
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
                                name: 'phone',
                                autovalidateMode: AutovalidateMode.onUnfocus,
                                keyboardType: TextInputType.phone,
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                  FormBuilderValidators.minLength(6),
                                  FormBuilderValidators.phoneNumber(),
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
                              const SizedBox(height: 16),
                              _buildTextField(
                                name: 'confirm_password',
                                obscureText: true,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator:
                                    (value) =>
                                        _formKey
                                                    .currentState
                                                    ?.fields['password']
                                                    ?.value !=
                                                value
                                            ? 'Passwords do not match.'
                                            : null,
                              ),
                              const SizedBox(height: 24),
                              _buildSignUpButton(),
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
    TextInputType? keyboardType,
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
          hintText:
              name == "confirm_password"
                  ? "Confirm Password"
                  : name.toCapitalize(),
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

  Widget _buildSignUpButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF0a6966), // Slightly darker green than background
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            // Process sign up logic
            final user = await authenticate();

            if (user != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(),
                ),
              );
            }
          }
        },
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Sign Up',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
