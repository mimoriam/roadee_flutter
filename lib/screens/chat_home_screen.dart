import 'package:flutter/material.dart';

import 'package:roadee_flutter/screens/chat_screen.dart';
import 'package:roadee_flutter/services/chat_service.dart';

import 'package:roadee_flutter/screens/login_screen.dart';

class ChatHomeScreen extends StatefulWidget {
  final user;

  const ChatHomeScreen({super.key, required this.user});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  late final ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(user: widget.user);
  }

  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          return ListView(
            children:
                snapshot.data!.map<Widget>((userData) => _buildUserItemList(userData, context)).toList(),
          ); // User is signed in
        } else {
          return const LoginScreen();
        }
      },
    );
  }

  Widget _buildUserItemList(Map<String, dynamic> userData, BuildContext context) {
    // Return all users except current user
    if (userData["email"] != widget.user["email"]) {
      print(userData);
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => ChatScreen(
                    receiverId: userData["id"],
                    receiverEmail: userData['email'],
                    user: widget.user,
                  ),
            ),
          );
        },
        child: Center(child: Text(userData['email'])),
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildUserList());
  }
}
