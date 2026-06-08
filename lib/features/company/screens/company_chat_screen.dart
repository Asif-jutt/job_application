import 'package:flutter/material.dart';

import '../../user/screens/user_chat_screen.dart';

/// Reuses the shared chat UI for company recruiters.
class CompanyChatScreen extends StatelessWidget {
  const CompanyChatScreen({super.key, required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context) {
    return UserChatScreen(chatId: chatId);
  }
}
