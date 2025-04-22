import 'package:flutter/material.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    'As Tamela S.',
                    style: TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const CircleAvatar(radius: 18),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Name"),
              Text("Email"),
              Text("Phone"),
            ],
          ),
        ),
      ),
    );
  }
}
