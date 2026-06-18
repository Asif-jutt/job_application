import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/constants/l10n/locale_provider.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/rozgar_shell_body.dart';
import '../provider/user_chat_provider.dart';

class UserChatListScreen extends ConsumerWidget {
  const UserChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(userChatsProvider);
    final s = ref.watch(stringsProvider);

    return RozgarShellBody(
      child: chatsAsync.when(
        loading: () => Center(child: Text(s.loading)),
        error: (e, _) => AsyncErrorView(
          message: s.unableLoadChats,
          onRetry: () => ref.invalidate(userChatsProvider),
        ),
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  s.noConversations,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return AnimationLimiter(
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final data = chat.data() as Map<String, dynamic>;
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: AppConstants.animationDuration,
                  child: SlideAnimation(
                    verticalOffset: 30,
                    child: FadeInAnimation(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            (data['title'] as String? ?? 'C')[0].toUpperCase(),
                          ),
                        ),
                        title: Text(
                          data['title'] as String? ?? 'Chat',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          data['lastMessage'] as String? ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () =>
                            context.push(RouteConstants.userChatPath(chat.id)),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
