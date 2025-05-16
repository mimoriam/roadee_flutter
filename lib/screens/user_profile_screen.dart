import 'package:flutter/material.dart';

import 'package:roadee_flutter/screens/home_screen.dart';
import 'package:roadee_flutter/screens/login_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final MenuController _menuController = MenuController();
  String userAddress = "";

  Future<String?> getUserAddress(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text("Location Services Disabled"),
              content: Text("Please enable location services in settings."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Geolocator.openLocationSettings();
                  },
                  child: Text("Open Settings"),
                ),
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text("Cancel")),
              ],
            ),
      );

      return null;
    }

    // Handle permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location permission denied")));
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text("Permission Denied"),
              content: Text("Enable location permissions from app settings."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Geolocator.openAppSettings();
                  },
                  child: Text("Open App Settings"),
                ),
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text("Cancel")),
              ],
            ),
      );
      return null;
    }

    // Get position and address
    Position position = await Geolocator.getCurrentPosition(
      forceAndroidLocationManager: true,
      // desiredAccuracy: LocationAccuracy.high,
      // locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      locationSettings: LocationSettings(accuracy: LocationAccuracy.low),
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];
    return '${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
  }

  Future<void> _onSelected(String value) async {
    switch (value) {
      case 'Settings':
        // String? address = await getUserAddress(context);
        break;
      case 'Log out':
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
        break;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  Future<UserCredential?> updateUsername() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Update Firestore email
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'username': _formKey.currentState?.fields['username']?.value,
      });
    } on FirebaseAuthException {}
    return null;
  }

  Future<UserCredential?> updatePhone() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Update Firestore email
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'phone': _formKey.currentState?.fields['phone']?.value,
      });
    } on FirebaseAuthException {}
    return null;
  }

  Future<UserCredential?> updateAddress() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Update Firestore email
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'address': userAddress});
    } on FirebaseAuthException {}
    return null;
  }

  Widget _buildButtons({required String name, required String func}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        // color: const Color(0xFF0a6966), // Slightly darker green than background
        color: const Color(0xFF098232),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            setState(() async {
              if (func == "Username") {
                updateUsername();
              }
              if (func == "Phone") {
                updatePhone();
              }

              if (func == "Address") {
                // Update Address
                String? userAddresss = await getUserAddress(context);

                if (userAddresss != null) {
                  setState(() {
                    userAddress = userAddresss;
                  });

                  await updateAddress();
                }
              }

              Navigator.of(context).popUntil((route) => route.isFirst);

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (BuildContext context) => HomeScreen()),
              );
            });
          }
        },
        style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: Text(name, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
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
              leading: IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: () {}),
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
                      const Text('You Are Logged In', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      Text("${user['username']}", style: TextStyle(fontSize: 12, color: Colors.black)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  MenuAnchor(
                    controller: _menuController,
                    style: MenuStyle(backgroundColor: WidgetStateProperty.all(Colors.white)),
                    menuChildren: [
                      MenuItemButton(onPressed: () => _onSelected('Settings'), child: Text('Settings')),
                      MenuItemButton(onPressed: () => _onSelected('Log out'), child: Text('Log out')),
                    ],
                    builder: (BuildContext context, MenuController controller, Widget? child) {
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
                                          enabled: true,
                                          initialValue: "${user['username']}",
                                          autovalidateMode: AutovalidateMode.onUnfocus,
                                          validator: FormBuilderValidators.compose([
                                            FormBuilderValidators.required(),
                                            FormBuilderValidators.minLength(
                                              4,
                                              errorText:
                                                  "Length should be greater "
                                                  "than 4",
                                            ),
                                          ]),
                                        ),
                                      ),
                                      _buildButtons(name: "Update Username", func: "Username"),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          name: 'email',
                                          enabled: false,
                                          initialValue: "${user['email']}",
                                          autovalidateMode: AutovalidateMode.onUnfocus,
                                          validator: null,
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
                                          enabled: true,
                                          initialValue: "${user['phone']}",
                                          autovalidateMode: AutovalidateMode.onUnfocus,
                                          validator: FormBuilderValidators.compose([
                                            FormBuilderValidators.required(),
                                            FormBuilderValidators.numeric(),
                                          ]),
                                        ),
                                      ),

                                      _buildButtons(name: "Update Phone", func: "Phone"),
                                    ],
                                  ),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          name: 'address',
                                          enabled: false,
                                          initialValue: "${user['address']}",
                                          autovalidateMode: AutovalidateMode.onUnfocus,
                                          validator: null,
                                        ),
                                      ),

                                      _buildButtons(name: "Update Address", func: "Address"),
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
  String? initialValue,
  required AutovalidateMode autovalidateMode,
  required validator,
  bool obscureText = false,
  required bool enabled,
}) {
  return Padding(
    padding: const EdgeInsets.all(12),
    child: Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: FormBuilderTextField(
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
          // contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    ),
  );
}
