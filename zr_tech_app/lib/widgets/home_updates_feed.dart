import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/responsive_wrapper.dart';
import '../services/site_updates_service.dart';
import '../services/auth_service.dart';

class HomeUpdatesFeed extends StatefulWidget {
  const HomeUpdatesFeed({super.key});

  @override
  State<HomeUpdatesFeed> createState() => _HomeUpdatesFeedState();
}

class _HomeUpdatesFeedState extends State<HomeUpdatesFeed> {
  final Set<String> _likedIds = {};

  Widget _buildImageWidget(String imageStr) {
    if (imageStr.startsWith('data:image')) {
      try {
        final base64Str = imageStr.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackImage(),
        );
      } catch (_) {
        return _buildFallbackImage();
      }
    }
    return Image.network(
      imageStr,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _buildFallbackImage(),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      height: 220,
      width: double.infinity,
      color: AppColors.surfaceDarkAlt,
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.textSlate400, size: 48),
      ),
    );
  }

  void _openFullScreenImage(BuildContext context, SiteUpdateModel item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.92),
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: _buildImageWidget(item.image),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
                icon: const Icon(Icons.close, color: Colors.white, size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCommentsSheet(BuildContext context, SiteUpdateModel item) {
    final commentCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    // Pre-fill author name if logged in
    AuthService().getCurrentUserData().then((user) {
      if (user != null && user.name.isNotEmpty) {
        nameCtrl.text = user.name;
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.72,
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'التعليقات - ${item.title}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: AppColors.textSlate400, size: 20),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.borderDark),
                  Expanded(
                    child: StreamBuilder<List<SiteUpdateModel>>(
                      stream: SiteUpdatesService().listenToUpdates(),
                      builder: (context, snapshot) {
                        final updates = snapshot.data ?? [];
                        final current = updates.where((u) => u.id == item.id).firstOrNull ?? item;
                        final comments = current.comments;

                        if (comments.isEmpty) {
                          return const Center(
                            child: Text(
                              'لا توجد تعليقات بعد. كن أول من يعلق!',
                              style: TextStyle(color: AppColors.textSlate400, fontSize: 14),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: comments.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, index) {
                            final c = comments[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDarkAlt,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.borderDark),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 15, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        c.authorName,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c.text,
                                    style: const TextStyle(
                                      color: AppColors.textSlate300,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentCtrl,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'أضف تعليقك هنا...',
                            hintStyle: const TextStyle(color: AppColors.textSlate400, fontSize: 13),
                            filled: true,
                            fillColor: AppColors.surfaceDarkAlt,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.borderDark),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.borderDark),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          final text = commentCtrl.text.trim();
                          if (text.isEmpty) return;
                          commentCtrl.clear();
                          await SiteUpdatesService().addComment(
                            updateId: item.id,
                            authorName: nameCtrl.text.trim().isEmpty ? 'زبون ZR Tech' : nameCtrl.text.trim(),
                            text: text,
                          );
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SiteUpdateModel>>(
      stream: SiteUpdatesService().listenToUpdates(),
      builder: (context, snapshot) {
        final updates = snapshot.data ?? [];
        if (updates.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: Responsive.sp(24)),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'آخر المستجدات والعروض',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: Responsive.fp(18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${updates.length} جديد',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.sp(14)),
            ...updates.map((item) => _buildUpdateCard(context, item)),
          ],
        );
      },
    );
  }

  Widget _buildUpdateCard(BuildContext context, SiteUpdateModel item) {
    final isLiked = _likedIds.contains(item.id);

    return Container(
      margin: EdgeInsets.only(bottom: Responsive.sp(18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── HEADER BAR (Title centered + Date on the right, matching client reference) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF006837), Color(0xFF058247)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 75),
                  child: Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Text(
                    item.date,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 11.5,
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── FULL-WIDTH BANNER IMAGE + LEFT FLOATING LIKE & COMMENT BUTTONS ──
          Stack(
            children: [
              GestureDetector(
                onTap: () => _openFullScreenImage(context, item),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 190,
                    maxHeight: 380,
                  ),
                  child: _buildImageWidget(item.image),
                ),
              ),

              // Floating Like (Heart) & Comment buttons on the left side of the banner
              Positioned(
                left: 10,
                top: 12,
                child: Column(
                  children: [
                    // Heart / Like Button
                    GestureDetector(
                      onTap: () {
                        final willIncrement = !isLiked;
                        setState(() {
                          if (willIncrement) {
                            _likedIds.add(item.id);
                          } else {
                            _likedIds.remove(item.id);
                          }
                        });
                        SiteUpdatesService().toggleLike(item.id, willIncrement);
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.85),
                          border: Border.all(
                            color: isLiked ? Colors.red.withValues(alpha: 0.5) : Colors.black12,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: isLiked ? const Color(0xFFE53935) : const Color(0xFFEF5350),
                          size: 21,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.likesCount}',
                        style: const TextStyle(
                          color: Color(0xFFD32F2F),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Space Grotesk',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Comment Button
                    GestureDetector(
                      onTap: () => _openCommentsSheet(context, item),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.85),
                          border: Border.all(color: Colors.black12, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mode_comment_rounded,
                          color: Color(0xFF546E7A),
                          size: 19,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.comments.length}',
                        style: const TextStyle(
                          color: Color(0xFF006837),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Space Grotesk',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

