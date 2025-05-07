import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roadee_flutter/services/chat_service.dart';
import 'package:roadee_flutter/screens/login_screen.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverEmail;
  final user;

  const ChatScreen({super.key, required this.receiverId, required this.receiverEmail, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(user: widget.user);
  }

  void sendMessageToDB() async {
    await _chatService.sendMessage(widget.receiverId, widget.receiverEmail, widget.user["email"], "AAA");
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [Expanded(child: _buildMessageList())]);
  }

  Widget _buildMessageList() {
    String senderId = widget.user["id"];
    return StreamBuilder(
      stream: _chatService.getMessages(widget.receiverId, senderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          return Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: snapshot.data!.docs.map((doc) => _buildMessageItemList(doc)).toList(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    sendMessageToDB();
                  },
                  child: Text("ENTER"),
                ),
              ],
            ),
          ); // User is signed in
        } else {
          return const LoginScreen();
        }
      },
    );
  }
  
  Widget _buildMessageItemList(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    bool isCurrentUser = data?["senderId"] == widget.user["id"];
    // Own messages at right:
    var alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
    return Container(alignment: alignment, child: Text(data["message"]));
  }
}
