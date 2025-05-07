import 'package:flutter/material.dart';

import 'package:roadee_flutter/screens/payment_checkout_screen.dart';
import 'package:roadee_flutter/screens/user_profile_screen.dart';
import 'package:roadee_flutter/screens/login_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class EnterInfoScreen extends StatefulWidget {
  final int serviceSelected;
  final String addressSelected;

  const EnterInfoScreen({
    super.key,
    required this.serviceSelected,
    required this.addressSelected,
  });

  @override
  State<EnterInfoScreen> createState() => _EnterInfoScreenState();
}

class _EnterInfoScreenState extends State<EnterInfoScreen> {
  final MenuController _menuController = MenuController();
  final _formKey = GlobalKey<FormBuilderState>();

  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Widget build(BuildContext context) {
    setState(() {});

    Future<void> onSelected(String value) async {
      switch (value) {
        case 'Your Profile':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserProfileScreen()),
          );
          break;
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
                  // const Text(
                  //   'Roadie',
                  //   style: TextStyle(
                  //     fontFamily: 'Cursive',
                  //     fontWeight: FontWeight.bold,
                  //     color: Colors.red,
                  //     fontSize: 24,
                  //   ),
                  // ),
                  Image(image: AssetImage("images/Logo_White.jpg"), height: 24),
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
                      backgroundColor: WidgetStateProperty.all(Colors.white),
                    ),
                    menuChildren: [
                      // MenuItemButton(
                      //   onPressed: () => onSelected('Your Profile'),
                      //   child: Text('Your Profile'),
                      // ),
                      MenuItemButton(
                        onPressed: () => onSelected('Log out'),
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
                                    "Enter Your Info.\nAnd We’ll Be On The Way!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    name: 'username',
                                    enabled: true,
                                    initialValue: "${user['username']}",
                                    autovalidateMode:
                                        AutovalidateMode.onUnfocus,
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(),
                                      FormBuilderValidators.minLength(5),
                                    ]),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    name: 'email',
                                    enabled: false,
                                    initialValue: "${user['email']}",
                                    autovalidateMode:
                                        AutovalidateMode.onUnfocus,
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(),
                                      FormBuilderValidators.email(),
                                    ]),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    name: 'phone',
                                    enabled: true,
                                    keyboardType: TextInputType.phone,
                                    initialValue: "${user['phone']}",
                                    autovalidateMode:
                                        AutovalidateMode.onUnfocus,
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
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (
                                                  context,
                                                ) => PaymentCheckoutScreen(
                                                  name: "${user['username']}",
                                                  email: "${user['email']}",
                                                  phone: "${user['phone']}",
                                                  serviceSelected:
                                                      widget.serviceSelected,
                                                  addressSelected:
                                                      widget.addressSelected,
                                                ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                      ),
                                      child: const Text(
                                        'Request Roadside Assistance',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
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
  String? initialValue,
  required AutovalidateMode autovalidateMode,
  required validator,
  bool obscureText = false,
  required bool enabled,
  TextInputType? keyboardType,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: FormBuilderTextField(
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      maxLines: null,
      enabled: enabled,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
    ),
  );
}
