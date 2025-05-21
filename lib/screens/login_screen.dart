import 'package:flutter/material.dart';

import 'package:roadee_flutter/screens/signup_screen.dart';
import 'package:roadee_flutter/screens/forgot_password_screen.dart';
import 'package:roadee_flutter/screens/home_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

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
    if (context.mounted) {
      setState(() {
        error = '';
      });
    }

    try {
      final user = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _formKey.currentState?.fields['email']?.value,
        password: _formKey.currentState?.fields['password']?.value,
      );

      print(user);

      return user;
    } on FirebaseAuthException catch (e) {
      print("MESSAGE FROM LOGIN");
      debugPrint("MESSAGE FROM LOGIN");
      debugPrint(e.message);
      print(e.message);
      setState(() {
        // error = e.message ?? 'Authentication error';
        // error = "Authentication error";
        error = e.message.toString();
      });
    } catch (e) {
      print("MESSAGE FROM LOGIN!!");
      debugPrint("MESSAGE FROM LOGIN");
      debugPrint(e.toString());
      print(e);
      setState(() {
        error = 'Unexpected error occurred';
      });
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFF128f8b),
      backgroundColor: Colors.white,
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
                      child: FormBuilder(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            SizedBox(height: 70),
                            Center(
                              child: Text(
                                "Welcome Back",
                                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 60),
                            const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 32),
                            _buildTextField(
                              name: 'email',
                              autovalidateMode: AutovalidateMode.onUnfocus,
                              labelText: "Your Email/User Name",
                              prefixIcon: Icon(Icons.person_outline),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.email(),
                              ]),
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              name: 'password',
                              obscureText: true,
                              autovalidateMode: AutovalidateMode.onUnfocus,
                              labelText: "Password",
                              // suffixIcon: Icon(Icons.visibility_off),
                              prefixIcon: Icon(Icons.lock_outline),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.minLength(6),
                              ]),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 12, bottom: 12),
                              child: Align(
                                alignment: Alignment.center,
                                child: TextButton(
                                  onPressed: () {
                                    // Handle forgot password
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                                    );
                                  },
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(color: Colors.green, fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildButtonRow(),
                            // const Spacer(flex: 2),
                            SizedBox(height: 70),
                            // _buildButton(
                            //   text: 'Sign Up',
                            //   onPressed: () {
                            //     // Navigate to sign up screen
                            //     Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpScreen()));
                            //   },
                            // ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Are you a new "
                                  "User?",
                                  style: TextStyle(color: Colors.black, fontSize: 16),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => SignUpScreen()),
                                    );
                                  },
                                  child: Text(" Sign Up", style: TextStyle(color: Colors.blue, fontSize: 16)),
                                ),
                              ],
                            ),
                          ],
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
                        // color: Colors.white.withValues(alpha: 0.5),
                        color: Colors.grey,
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
    required Widget prefixIcon,
    required String labelText,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: FormBuilderTextField(
        name: name,
        autovalidateMode: autovalidateMode,
        validator: validator,
        obscureText: obscureText,
        decoration: InputDecoration(
          // suffix:
          //     obscureText == true
          //         ? IconButton(
          //           padding: const EdgeInsetsDirectional.only(end: 12),
          //           onPressed: () {
          //             setState(() {
          //               obscureText = false;
          //             });
          //           },
          //           icon: Icon(Icons.visibility),
          //         )
          //         : null,
          hintText: name.toCapitalize(),
          hintStyle: TextStyle(color: Color(0xFF799ac2), fontSize: 18),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          prefixIcon: prefixIcon,
          labelText: labelText,
          suffix: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildButtonRow() {
    return Row(
      children: [
        Expanded(
          child: _buildButton(
            text: 'Login',
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                // Process login logic
                final user = await authenticate();

                if (!mounted) return; // Add mounted check after await
                if (user != null) {
                  if (context.mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
                  }
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
        // color: const Color(0xFF0a6966), // Slightly darker green than background
        color: const Color(0xFF098232), // Slightly darker green than background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
