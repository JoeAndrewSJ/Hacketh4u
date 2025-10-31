import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/bloc/community/community_bloc.dart';
import '../../../core/bloc/community/community_event.dart';
import '../../../core/bloc/community/community_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/community_models.dart';
import '../../../data/repositories/community_repository.dart';
import 'user_workspace_screen.dart';
import 'user_chat_screen.dart';

class CommunityChatScreen extends StatefulWidget {
  const CommunityChatScreen({super.key});

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> with SingleTickerProviderStateMixin {
  bool _hasLoaded = false;
  late TabController _tabController;
  List<Workspace> _workspaces = [];
  List<Group> _allGroups = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWorkspaces();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadWorkspaces() {
    if (!_hasLoaded) {
      context.read<CommunityBloc>().add(LoadWorkspaces());
      _hasLoaded = true;
    }
  }

  Future<void> _loadAllGroups() async {
    // Load groups from all workspaces the user is a member of
    final communityRepository = sl<CommunityRepository>();
    List<Group> allGroups = [];

    for (var workspace in _workspaces) {
      if (communityRepository.isUserMemberOfWorkspace(workspace)) {
        try {
          final groups = await communityRepository.getWorkspaceGroups(workspace.id);
          allGroups.addAll(groups);
        } catch (e) {
          // Continue loading other groups even if one fails
          debugPrint('Error loading groups for workspace ${workspace.id}: $e');
        }
      }
    }

    setState(() {
      _allGroups = allGroups;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Community',
          style: AppTextStyles.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.grey[200],
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: AppTheme.primaryLight,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Workspace'),
                Tab(text: 'Groups'),
                Tab(text: 'Chats'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: BlocConsumer<CommunityBloc, CommunityState>(
              listener: (context, state) {
                if (state is CommunitySuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  // Reload workspaces after joining
                  if (state.message.contains('joined') || state.message.contains('Joined')) {
                    setState(() {
                      _hasLoaded = false;
                    });
                    _loadWorkspaces();
                  }
                } else if (state is CommunityError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }

                if (state is WorkspacesLoaded) {
                  setState(() {
                    _workspaces = state.workspaces;
                  });
                  _loadAllGroups();
                }
              },
              builder: (context, state) {
                if (state is CommunityLoading && _workspaces.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Workspace Tab
                    _buildWorkspaceTab(isDark),
                    // Groups Tab
                    _buildGroupsTab(isDark),
                    // Chats Tab
                    _buildChatsTab(isDark),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceTab(bool isDark) {
    if (_workspaces.isEmpty) {
      return _buildEmptyState(
        isDark,
        Icons.workspaces_outlined,
        'No Workspaces Yet',
        'Workspaces will appear here once they are created by admins.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<CommunityBloc>().add(LoadWorkspaces());
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _workspaces.length,
        itemBuilder: (context, index) {
          final workspace = _workspaces[index];
          return _buildWorkspaceCard(workspace, isDark);
        },
      ),
    );
  }

  Widget _buildGroupsTab(bool isDark) {
    if (_allGroups.isEmpty) {
      return _buildEmptyState(
        isDark,
        Icons.groups_outlined,
        'No Groups Yet',
        'Join workspaces to see available groups.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadAllGroups();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _allGroups.length,
        itemBuilder: (context, index) {
          final group = _allGroups[index];
          return _buildGroupCard(group, isDark);
        },
      ),
    );
  }

  Widget _buildChatsTab(bool isDark) {
    final communityRepository = sl<CommunityRepository>();
    final memberGroups = _allGroups.where((group) =>
      communityRepository.isUserMemberOfGroup(group)
    ).toList();

    if (memberGroups.isEmpty) {
      return _buildEmptyState(
        isDark,
        Icons.chat_bubble_outline,
        'No Active Chats',
        'Join groups to start chatting with the community.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadAllGroups();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: memberGroups.length,
        itemBuilder: (context, index) {
          final group = memberGroups[index];
          return _buildChatListItem(group, isDark);
        },
      ),
    );
  }

  Widget _buildWorkspaceCard(Workspace workspace, bool isDark) {
    final communityRepository = sl<CommunityRepository>();
    final isMember = communityRepository.isUserMemberOfWorkspace(workspace);
    final firstLetter = workspace.name.isNotEmpty ? workspace.name[0].toUpperCase() : 'W';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        elevation: 0.5,
        shadowColor: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
        child: InkWell(
          onTap: isMember ? () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserWorkspaceScreen(workspace: workspace),
              ),
            );
            setState(() {
              _hasLoaded = false;
            });
            _loadWorkspaces();
          } : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey.shade800.withOpacity(0.2) : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryLight,
                        AppTheme.primaryLight.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
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
                const SizedBox(width: 12),

                // Workspace Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workspace.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        workspace.description.isNotEmpty
                            ? workspace.description
                            : 'Join to collaborate with the community',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${workspace.memberIds.length} members',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Join button or arrow
                if (isMember)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  )
                else
                  GestureDetector(
                    onTap: () => _joinWorkspace(workspace),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Join',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
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

  Widget _buildGroupCard(Group group, bool isDark) {
    final communityRepository = sl<CommunityRepository>();
    final isMember = communityRepository.isUserMemberOfGroup(group);
    final firstLetter = group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        elevation: 0.5,
        shadowColor: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
        child: InkWell(
          onTap: isMember ? () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserChatScreen(group: group),
              ),
            );
            _loadAllGroups();
          } : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey.shade800.withOpacity(0.2) : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryLight,
                        AppTheme.primaryLight.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
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
                const SizedBox(width: 12),

                // Group Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        group.description.isNotEmpty
                            ? group.description
                            : 'Join the group to start chatting!',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${group.memberIds.length} members',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Join button or arrow
                if (isMember)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  )
                else
                  GestureDetector(
                    onTap: () => _joinGroup(group),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Join',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
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

  Widget _buildChatListItem(Group group, bool isDark) {
    final firstLetter = group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserChatScreen(group: group),
            ),
          );
          _loadAllGroups();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade200,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar (WhatsApp style - circular)
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryLight,
                      AppTheme.primaryLight.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Chat Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                : 'Tap to open chat',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Unread badge (optional - can be added later)
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _joinWorkspace(Workspace workspace) {
    context.read<CommunityBloc>().add(JoinWorkspace(workspaceId: workspace.id));
  }

  void _joinGroup(Group group) {
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

  Widget _buildEmptyState(bool isDark, IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                icon,
                size: 60,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
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
