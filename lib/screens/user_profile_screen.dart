import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roadee_flutter/screens/home_screen.dart';
import 'package:roadee_flutter/screens/login_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final MenuController _menuController = MenuController();

  Future<void> _onSelected(String value) async {
    switch (value) {
      case 'Settings':
        break;
      case 'Log out':
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        break;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  Future<UserCredential?> updateUsername() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Update Firestore email
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'username': _formKey.currentState?.fields['username']?.value},
      );
    } on FirebaseAuthException {}
    return null;
  }

  Future<UserCredential?> updatePhone() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Update Firestore email
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'phone': _formKey.currentState?.fields['phone']?.value},
      );
    } on FirebaseAuthException {}
    return null;
  }

  Widget _buildButtons({required String name, required String func}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF0a6966), // Slightly darker green than background
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton(
        onPressed: () async {
          setState(() {
            if (func == "Username") {
              updateUsername();
            }
            if (func == "Phone") {
              updatePhone();
            }

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => HomeScreen(),
              ),
            );
          });
        },
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: getUserProfile(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data!;
        return Scaffold(
          // backgroundColor: const Color(0xFF128f8b),
          backgroundColor: Colors.white,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () {},
              ),
              title: Row(
                children: [
                  const Text(
                    'Roadie',
                    style: TextStyle(
                      fontFamily: 'Cursive',
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 24,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'You Are Logged In',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      Text(
                        "${user['username']}",
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  MenuAnchor(
                    controller: _menuController,
                    style: MenuStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.white),
                    ),
                    menuChildren: [
                      MenuItemButton(
                        onPressed: () => _onSelected('Settings'),
                        child: Text('Settings'),
                      ),
                      MenuItemButton(
                        onPressed: () => _onSelected('Log out'),
                        child: Text('Log out'),
                      ),
                    ],
                    builder: (
                      BuildContext context,
                      MenuController controller,
                      Widget? child,
                    ) {
                      return GestureDetector(
                        onTap: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },

                        child: CircleAvatar(
                          radius: 18,
                          backgroundImage: AssetImage("images/default_pfp.jpg"),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
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
                                  const SizedBox(height: 50),
                                  const Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          name: 'username',
                                          initialValue: "${user['username']}",
                                          autovalidateMode:
                                              AutovalidateMode.onUnfocus,
                                          validator:
                                              FormBuilderValidators.compose([
                                                FormBuilderValidators.required(),
                                                FormBuilderValidators.minLength(
                                                  5,
                                                ),
                                              ]),
                                        ),
                                      ),
                                      _buildButtons(
                                        name: "Update Username",
                                        func: "Username",
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          name: 'email',
                                          initialValue: "${user['email']}",
                                          autovalidateMode:
                                              AutovalidateMode.onUnfocus,
                                          validator:
                                              FormBuilderValidators.compose([
                                                FormBuilderValidators.required(),
                                                FormBuilderValidators.email(),
                                              ]),
                                        ),
                                      ),
                                      // _buildButtons(name: "Update Email"),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          name: 'phone',
                                          initialValue: "${user['phone']}",
                                          autovalidateMode:
                                              AutovalidateMode.onUnfocus,
                                          validator:
                                              FormBuilderValidators.compose([
                                                FormBuilderValidators.required(),
                                                FormBuilderValidators.email(),
                                              ]),
                                        ),
                                      ),

                                      _buildButtons(
                                        name: "Update Phone",
                                        func: "Phone",
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _buildTextField({
  required String name,
  initialValue,
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
      initialValue: initialValue,
      autovalidateMode: autovalidateMode,
      validator: validator,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: name.toCapitalize(),
        labelText: name.toCapitalize(),
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
