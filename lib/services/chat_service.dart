import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final user;

  ChatService({required this.user});

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();

        return user;
      }).toList();
    });
  }

  Future<void> sendMessage(String receiverId, String receiverEmail, String senderEmail, var message) async {
    final String currentUserId = uid!;
    final String currentUserEmail = user["email"];
    final Timestamp timestamp = Timestamp.now();

    var newMessage = {
      "senderId": currentUserId,
      "senderEmail": senderEmail,
      "receiverEmail": receiverEmail,
      "receiverId": receiverId,
      "message": message,
      "timestamp": timestamp,
    };

    List<String> ids = [currentUserId, receiverId];
    ids.sort();

    String chatRoomId = ids.join('_');
    print(chatRoomId);

    await _firestore.collection("chat_rooms").doc(chatRoomId).collection("messages").add(newMessage);
  }

  Stream<QuerySnapshot> getMessages(String userId, otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();

    String chatRoomId = ids.join('_');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }
}
