import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/bloc/community/community_bloc.dart';
import '../../../core/bloc/community/community_event.dart';
import '../../../core/bloc/community/community_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/community_models.dart';
import '../../../data/repositories/community_repository.dart';
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
            Icons.arrow_back_ios,
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
          // Workspace Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppTheme.surfaceDark, AppTheme.surfaceDark.withOpacity(0.8)]
                    : [AppTheme.primaryLight, AppTheme.primaryLight.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.workspaces,
                        color: isDark ? AppTheme.textPrimaryDark : Colors.white,
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
                              color: isDark ? AppTheme.textPrimaryDark : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.workspace.description,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark 
                                  ? AppTheme.textPrimaryDark.withOpacity(0.8)
                                  : Colors.white.withOpacity(0.9),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Reload groups after joining
                  context.read<CommunityBloc>().add(LoadGroups(workspaceId: widget.workspace.id));
                } else if (state is CommunityError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error),
                      backgroundColor: Colors.red,
                    ),
                  );
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
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? AppTheme.textPrimaryDark : Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : Colors.white,
              fontWeight: FontWeight.w500,
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
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // WhatsApp-style Avatar with first letter
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryLight,
                        AppTheme.primaryLight.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Group Info (WhatsApp-style)
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
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(group.updatedAt),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.description.isNotEmpty 
                                  ? group.description 
                                  : 'No description available',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 14,
                                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${group.memberIds.length}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow indicator (WhatsApp-style)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.group_outlined,
                size: 64,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Groups Yet',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Groups will appear here once they are created by admins.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
