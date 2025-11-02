import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/bloc/community/community_bloc.dart';
import '../../../core/bloc/community/community_event.dart';
import '../../../core/bloc/community/community_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/community_models.dart';
import '../../../data/repositories/community_repository.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'user_chat_screen.dart';

class UserWorkspaceScreen extends StatefulWidget {
  final Workspace workspace;

  const UserWorkspaceScreen({
    super.key,
    required this.workspace,
  });

  @override
  State<UserWorkspaceScreen> createState() => _UserWorkspaceScreenState();
}

class _UserWorkspaceScreenState extends State<UserWorkspaceScreen> {
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() {
    if (!_hasLoaded) {
      context.read<CommunityBloc>().add(LoadGroups(workspaceId: widget.workspace.id));
      _hasLoaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          widget.workspace.name,
          style: AppTextStyles.h3.copyWith(
            color: isDark ? AppTheme.textPrimaryDark : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.primaryLight,
        foregroundColor: isDark ? AppTheme.textPrimaryDark : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,  // Standard arrow instead of iOS style
            color: isDark ? AppTheme.textPrimaryDark : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: isDark ? AppTheme.textPrimaryDark : Colors.white,
            ),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Workspace Header - Clean professional design
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,  // Clean background
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey.shade800 : const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.1),  // Subtle orange background
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryLight.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.workspaces,
                        color: AppTheme.primaryLight,  // Orange icon
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.workspace.name,
                            style: AppTextStyles.h3.copyWith(
                              color: isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),  // Dark text
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.workspace.description,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),  // Secondary text
                              fontSize: 14,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatChip(
                      Icons.group,
                      '${widget.workspace.memberIds.length} Members',
                      isDark,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      Icons.chat_bubble_outline,
                      'Active Groups',
                      isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Groups List
          Expanded(
            child: BlocConsumer<CommunityBloc, CommunityState>(
              listener: (context, state) {
                if (state is CommunitySuccess) {
                  // Professional dark SnackBar instead of bright green
                  CustomSnackBar.showSuccess(context, state.message);
                  // Reload groups after joining (but only if it's a join operation)
                  if (state.message.contains('joined') || state.message.contains('Joined')) {
                    // Reset loading state and reload groups
                    setState(() {
                      _hasLoaded = false;
                    });
                    _loadGroups();
                  }
                } else if (state is CommunityError) {
                  // Professional dark SnackBar instead of bright red
                  CustomSnackBar.showError(context, state.error);
                }
              },
              builder: (context, state) {
                if (state is CommunityLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (state is GroupsLoaded) {
                  final groups = state.groups;
                  
                  if (groups.isEmpty) {
                    return _buildEmptyState(isDark);
                  }
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<CommunityBloc>().add(LoadGroups(workspaceId: widget.workspace.id));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return _buildGroupCard(group, isDark);
                      },
                    ),
                  );
                }
                
                if (state is CommunityError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading groups',
                          style: AppTextStyles.h3.copyWith(
                            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.error,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<CommunityBloc>().add(LoadGroups(workspaceId: widget.workspace.id));
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade800.withOpacity(0.3)
            : const Color(0xFFF5F5F5),  // Neutral background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),  // Secondary color
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),  // Secondary color
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Group group, bool isDark) {
    final communityRepository = sl<CommunityRepository>();
    final isMember = communityRepository.isUserMemberOfGroup(group);

    // Get first letter for avatar
    final firstLetter = group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
        child: InkWell(
          onTap: isMember ? () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserChatScreen(group: group),
              ),
            );
            // Reset loading state when returning
            setState(() {
              _hasLoaded = false;
            });
            _loadGroups();
          } : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Group Avatar - neutral design
                Hero(
                  tag: 'user_group_${group.id}',
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),  // Neutral gray
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade700 : const Color(0xFFE0E0E0),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        firstLetter,
                        style: TextStyle(
                          color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF4A4A4A),  // Dark gray
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Group Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.textSecondaryDark.withOpacity(0.1)
                                  : AppTheme.textSecondaryLight.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatTime(group.updatedAt),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        group.description.isNotEmpty
                            ? group.description
                            : 'Join the group to start chatting!',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          fontSize: 14,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 14,
                                  color: AppTheme.primaryLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${group.memberIds.length} members',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppTheme.primaryLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Join button or arrow indicator
                if (isMember)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.textSecondaryDark.withOpacity(0.1)
                          : AppTheme.textSecondaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryLight,
                          AppTheme.primaryLight.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.15),  // Neutral shadow
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _joinGroup(group),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Text(
                            'Join',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _joinGroup(Group group) {
    // Join the group through the BLoC
    context.read<CommunityBloc>().add(JoinGroup(groupId: group.id));
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Modern icon container with gradient
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryLight.withOpacity(0.1),
                    AppTheme.primaryLight.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppTheme.primaryLight.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.groups_rounded,
                size: 80,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Groups Available',
              style: AppTextStyles.h2.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                'Groups will appear here once they are created by workspace admins. Check back soon!',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
