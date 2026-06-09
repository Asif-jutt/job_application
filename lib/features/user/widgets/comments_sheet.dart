import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/toast_service.dart';
import '../../auth/provider/auth_provider.dart';
import '../model/job_comment.dart';
import '../provider/social_provider.dart';

Future<void> showCommentsSheet(BuildContext context, String jobId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CommentsSheet(jobId: jobId),
  );
}

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.jobId});
  final String jobId;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController();
  String? _replyToId;
  String? _replyToName;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authNotifierProvider).value;
    if (user == null) return;

    try {
      await ref.read(socialRepositoryProvider).addComment(
            jobId: widget.jobId,
            authorId: user.uid,
            authorName: user.displayName ?? user.email,
            text: text,
            parentId: _replyToId,
            taggedUser: _replyToName,
          );

      _controller.clear();
      if (mounted) {
        setState(() {
          _replyToId = null;
          _replyToName = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastService.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(jobCommentsProvider(widget.jobId));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Comments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Expanded(
                child: commentsAsync.when(
                  loading: () => const Center(child: Text('Loading comments...')),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (comments) {
                    if (comments.isEmpty) {
                      return const Center(child: Text('No comments yet'));
                    }
                    return AnimationLimiter(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: AppConstants.animationDuration,
                            child: SlideAnimation(
                              verticalOffset: 30,
                              child: FadeInAnimation(
                                child: _CommentTile(
                                  comment: comments[index],
                                  onReply: () {
                                    setState(() {
                                      _replyToId = comments[index].id;
                                      _replyToName = comments[index].authorName;
                                    });
                                    _controller.text = '@${comments[index].authorName} ';
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              if (_replyToName != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('Replying to $_replyToName',
                          style: const TextStyle(fontSize: 12)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => setState(() {
                          _replyToId = null;
                          _replyToName = null;
                          _controller.clear();
                        }),
                      ),
                    ],
                  ),
                ),
              _CommentInput(controller: _controller, onSubmit: _submit),
            ],
          ),
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.onReply});

  final JobComment comment;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: comment.isReply ? 24 : 0, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            child: Text(comment.authorName[0].toUpperCase()),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.authorName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(comment.text, style: const TextStyle(fontSize: 14)),
                TextButton(
                  onPressed: onReply,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Reply', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInput extends StatelessWidget {
  const _CommentInput({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 8, 16, MediaQuery.paddingOf(context).bottom + 8,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          IconButton(
            onPressed: onSubmit,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
