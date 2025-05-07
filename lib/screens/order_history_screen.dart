import 'package:flutter/material.dart';

import 'package:roadee_flutter/screens/login_screen.dart';
import 'package:roadee_flutter/screens/user_profile_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class OrderHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const OrderHistoryScreen({super.key, required this.userData});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final MenuController _menuController = MenuController();

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
        case 'Log out':
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
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
          backgroundColor: Colors.white,
          appBar: PreferredSize(preferredSize: const Size.fromHeight(60), child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {},
            ),

            title: Row(
              children: [
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
          )),
          body: SafeArea(
            child: Container(),
          ),
        );
      },
    );
  }
}
