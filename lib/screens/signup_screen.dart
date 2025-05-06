import 'package:flutter/material.dart';
import 'package:roadee_flutter/screens/login_screen.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roadee_flutter/screens/payment_checkout_screen.dart';

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

      await FirebaseFirestore.instance.collection("users").doc(user.user!.uid).set({
        "id": user.user!.uid,
        "username": _formKey.currentState?.fields['username']?.value,
        "is_admin": false,
        "email": user.user!.email,
        "phone": _formKey.currentState?.fields['phone']?.value,
        "address": "",
        "profileImage": "default_pfp.jpg",
        "createdAt": FieldValue.serverTimestamp(),
        "order_index": 0,
        "orders": FieldValue.arrayUnion([
          {"orderCreatedAt": DateTime.now(), "status": OrderStatus.Empty.name},
        ]),
        "order_assigned_index": 0,
        "orders_assigned": FieldValue.arrayUnion([
          {
            "orderAssignedAt": DateTime.now(),
            "orderAssignedFrom": "",
          },
        ]),
      });

      // await FirebaseFirestore.instance
      //     .collection("users")
      //     .doc(user.user!.uid)
      //     .collection('orders')
      //     .doc()
      //     .set({
      //       "orderCreatedAt": DateTime.now(),
      //       "status": OrderStatus.Empty.name,
      //     });

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
      backgroundColor: Colors.white,
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
                      child: FormBuilder(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.max,
                          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // const SizedBox(height: 100),
                            const SizedBox(height: 40),
                            Center(
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 30),
                            _buildTextField(
                              name: 'username',
                              labelText: "Your User Name",
                              prefixIcon: Icon(Icons.account_box_rounded),
                              autovalidateMode: AutovalidateMode.onUnfocus,
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.minLength(
                                  4,
                                  errorText:
                                      "Length should be greater "
                                      "than 3",
                                ),
                              ]),
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              name: 'email',
                              labelText: "Your Email",
                              prefixIcon: Icon(Icons.person_outline),
                              autovalidateMode: AutovalidateMode.onUnfocus,
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.email(),
                              ]),
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              name: 'phone',
                              labelText: "Your Phone",
                              prefixIcon: Icon(Icons.phone),
                              autovalidateMode: AutovalidateMode.onUnfocus,
                              keyboardType: TextInputType.phone,
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.minLength(
                                  6,
                                  errorText:
                                      "Length should be greater "
                                      "than 5",
                                ),
                                FormBuilderValidators.phoneNumber(),
                              ]),
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              name: 'password',
                              labelText: "Password",
                              prefixIcon: Icon(Icons.lock_outline),
                              obscureText: true,
                              autovalidateMode: AutovalidateMode.onUnfocus,
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.minLength(
                                  6,
                                  errorText:
                                      "Length should be greater "
                                      "than 5",
                                ),
                              ]),
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              name: 'confirm_password',
                              labelText: "Confirm Password",
                              prefixIcon: Icon(Icons.lock_outline),
                              obscureText: true,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator:
                                  (value) =>
                                      _formKey.currentState?.fields['password']?.value != value
                                          ? 'Passwords do not match.'
                                          : null,
                            ),
                            const SizedBox(height: 24),
                            _buildSignUpButton(),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already a User?",
                                  style: TextStyle(color: Colors.black, fontSize: 16),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => SignUpScreen()),
                                    );
                                  },
                                  child: Text(" Login", style: TextStyle(color: Colors.blue, fontSize: 16)),
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
    TextInputType? keyboardType,
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
          hintText: name == "confirm_password" ? "Confirm Password" : name.toCapitalize(),
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

  Widget _buildSignUpButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF098232), // Slightly darker green than background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            // Process sign up logic
            final user = await authenticate();

            if (user != null) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
            }
          }
        },
        style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: const Text(
          'Sign Up',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
