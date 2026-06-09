import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/models/job_model.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/utils/extensions.dart';
import '../../auth/provider/auth_provider.dart';

import '../provider/social_provider.dart';

import '../widgets/comments_sheet.dart';

import '../widgets/job_application_sheet.dart';

import '../widgets/job_detail_header.dart';

import '../widgets/like_button.dart';



class UserJobDetailScreen extends ConsumerStatefulWidget {

  const UserJobDetailScreen({super.key, required this.job});



  final JobModel job;



  @override

  ConsumerState<UserJobDetailScreen> createState() =>

      _UserJobDetailScreenState();

}



class _UserJobDetailScreenState extends ConsumerState<UserJobDetailScreen> {

  late JobModel _displayJob;

  bool? _optimisticLiked;

  int? _optimisticLikeCount;



  @override

  void initState() {

    super.initState();

    _displayJob = widget.job;

  }



  JobModel get _job {

    if (!isFirestoreJobId(widget.job.id)) return _displayJob;

    final streamed = ref.watch(jobDetailStreamProvider(widget.job.id)).value;

    return streamed ?? _displayJob;

  }



  bool get _isLiked {

    final user = ref.read(authNotifierProvider).value;

    if (user == null) return false;

    if (_optimisticLiked != null) return _optimisticLiked!;

    return _job.isLikedBy(user.uid);

  }



  int get _likeCount => _optimisticLikeCount ?? _job.likeCount;



  Future<void> _toggleLike() async {

    final user = ref.read(authNotifierProvider).value;

    if (user == null) return;



    if (!isFirestoreJobId(_job.id)) {

      ToastService.error(context, 'Likes available on premium Rozgar jobs only');

      return;

    }



    final wasLiked = _isLiked;

    setState(() {

      _optimisticLiked = !wasLiked;

      _optimisticLikeCount = _likeCount + (wasLiked ? -1 : 1);

    });



    try {

      await ref.read(socialRepositoryProvider).toggleLike(

            _job.id,

            user.uid,

            wasLiked,

          );

      if (mounted) {

        setState(() {

          _optimisticLiked = null;

          _optimisticLikeCount = null;

        });

      }

    } catch (e) {

      if (mounted) {

        setState(() {

          _optimisticLiked = null;

          _optimisticLikeCount = null;

        });

        ToastService.error(context, e.toString().replaceFirst('Exception: ', ''));

      }

    }

  }



  void _openComments() {
    if (!isFirestoreJobId(_job.id)) {
      ToastService.error(context, 'Comments available on premium Rozgar jobs only');
      return;
    }
    showCommentsSheet(context, _job.id);
  }

  Future<void> _messageRecruiter() async {
    final user = ref.read(authNotifierProvider).value;
    final job = _job;
    if (user == null || job.companyId == null) {
      ToastService.error(context, 'Cannot start chat for this job');
      return;
    }
    final chatId = await ref.read(chatServiceProvider).ensureChat(
          userId: user.uid,
          otherUserId: job.companyId!,
          title: job.company,
        );
    if (!mounted) return;
    context.push(RouteConstants.userChat.replaceAll(':chatId', chatId));
  }



  @override

  Widget build(BuildContext context) {

    final user = ref.watch(authNotifierProvider).value;

    final job = _job;



    return Scaffold(

      extendBodyBehindAppBar: true,

      appBar: AppBar(

        backgroundColor: Colors.transparent,

        elevation: 0,

        title: const Text('Job Details'),

      ),

      body: Hero(

        tag: 'job_${widget.job.id}',

        child: Material(

          color: Colors.transparent,

          child: SingleChildScrollView(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [

                if (job.bannerUrl != null)

                  CachedNetworkImage(

                    imageUrl: job.bannerUrl!,

                    height: 220,

                    width: double.infinity,

                    fit: BoxFit.cover,

                    placeholder: (_, _) => Container(

                      height: 220,

                      color: Colors.grey.shade200,

                    ),

                  )

                else

                  Container(

                    height: 120,

                    decoration: BoxDecoration(

                      gradient: LinearGradient(

                        colors: [

                          context.colorScheme.primary,

                          context.colorScheme.secondary,

                        ],

                      ),

                    ),

                    child: const Center(

                      child: Icon(Icons.work_outline, color: Colors.white, size: 48),

                    ),

                  ),

                Padding(

                  padding: const EdgeInsets.all(24),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [

                      JobDetailHeader(job: job),

                      const SizedBox(height: 16),

                      Row(

                        children: [

                          if (user != null && job.source == JobSource.firestore)

                            LikeButton(

                              isLiked: _isLiked,

                              count: _likeCount,

                              onTap: _toggleLike,

                            ),

                          const SizedBox(width: 16),

                          InkWell(

                            onTap: _openComments,

                            borderRadius: BorderRadius.circular(20),

                            child: Padding(

                              padding: const EdgeInsets.symmetric(

                                horizontal: 8,

                                vertical: 4,

                              ),

                              child: Row(

                                children: [

                                  const Icon(Icons.chat_bubble_outline, size: 20),

                                  const SizedBox(width: 4),

                                  Text('${job.commentCount}'),

                                ],

                              ),

                            ),

                          ),

                          const Spacer(),

                          if (job.isPremium)

                            Chip(

                              label: const Text('Premium'),

                              backgroundColor: context.colorScheme.tertiaryContainer,

                            ),

                        ],

                      ),

                      const SizedBox(height: 24),

                      Text(

                        'Description',

                        style: context.textTheme.titleMedium?.copyWith(

                          fontWeight: FontWeight.w600,

                        ),

                      ),

                      const SizedBox(height: 8),

                      Text(job.description, style: context.textTheme.bodyLarge),

                      if (job.tags.isNotEmpty) ...[

                        const SizedBox(height: 16),

                        Wrap(

                          spacing: 8,

                          children: job.tags

                              .map((t) => Chip(label: Text(t)))

                              .toList(),

                        ),

                      ],

                      const SizedBox(height: 32),

                      if (job.source == JobSource.firestore) ...[
                        ElevatedButton(
                          onPressed: () =>
                              showJobApplicationSheet(context, ref, job),
                          child: const Text('Apply Now'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _messageRecruiter,
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Message Recruiter'),
                        ),
                      ],

                    ],

                  ),

                ),

              ],

            ),

          ),

        ),

      ),

    );

  }

}


