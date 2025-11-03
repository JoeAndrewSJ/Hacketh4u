import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/community/community_bloc.dart';
import '../../../core/bloc/community/community_event.dart';
import '../../../core/bloc/community/community_state.dart';
import '../../../data/models/community_models.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/repositories/community_repository.dart';
import 'workspace_screen.dart';
import 'group_chat_screen.dart';
import '../../widgets/navigation/admin_bottom_nav_bar.dart';
import '../home/admin_home_screen.dart';

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
  bool _isSelectionMode = false;
  Set<String> _selectedWorkspaces = {};
  Set<String> _selectedGroups = {};

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
    final communityRepository = sl<CommunityRepository>();
    List<Group> allGroups = [];

    for (var workspace in _workspaces) {
      try {
        final groups = await communityRepository.getWorkspaceGroups(workspace.id);
        allGroups.addAll(groups);
      } catch (e) {
        debugPrint('Error loading groups for workspace ${workspace.id}: $e');
      }
    }

    setState(() {
      _allGroups = allGroups;
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedWorkspaces.clear();
      _selectedGroups.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Community Admin',
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
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _showBulkDeleteDialog,
              tooltip: 'Delete Selected',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _exitSelectionMode,
            ),
          ] else ...[
            if (_tabController.index == 0)
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _showCreateWorkspaceDialog(context, isDark),
                tooltip: 'Create Workspace',
              ),
          ],
        ],
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
              onTap: (index) {
                _exitSelectionMode();
                setState(() {});
              },
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
                  setState(() {
                    _hasLoaded = false;
                  });
                  _loadWorkspaces();
                } else if (state is CommunityError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                } else if (state is WorkspaceCreated || state is WorkspaceDeleted ||
                           state is GroupCreated || state is GroupDeleted) {
                  setState(() {
                    _hasLoaded = false;
                  });
                  _loadWorkspaces();
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
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          // Navigate back to main screen with the selected tab
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminHomeScreen(initialIndex: index)),
          );
        },
      ),
    );
  }

  Widget _buildWorkspaceTab(bool isDark) {
    if (_workspaces.isEmpty) {
      return _buildEmptyState(
        isDark,
        Icons.workspaces_outlined,
        'No Workspaces Yet',
        'Create your first workspace to start managing teams.',
        onCreatePressed: () => _showCreateWorkspaceDialog(context, isDark),
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
        'Create workspaces and groups to manage your teams.',
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
    if (_allGroups.isEmpty) {
      return _buildEmptyState(
        isDark,
        Icons.chat_bubble_outline,
        'No Active Chats',
        'Create groups to start managing conversations.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadAllGroups();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: _allGroups.length,
        itemBuilder: (context, index) {
          final group = _allGroups[index];
          return _buildChatListItem(group, isDark);
        },
      ),
    );
  }

  Widget _buildWorkspaceCard(Workspace workspace, bool isDark) {
    final firstLetter = workspace.name.isNotEmpty ? workspace.name[0].toUpperCase() : 'W';
    final isSelected = _selectedWorkspaces.contains(workspace.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        elevation: isSelected ? 0 : 0.5,
        shadowColor: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
        child: InkWell(
          onTap: () {
            if (_isSelectionMode) {
              _toggleWorkspaceSelection(workspace.id);
            } else {
              _navigateToWorkspace(workspace);
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
              });
              _toggleWorkspaceSelection(workspace.id);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppTheme.primaryLight.withOpacity(0.15),
                        AppTheme.primaryLight.withOpacity(0.05),
                      ],
                    )
                  : null,
              color: isSelected ? null : (isDark ? AppTheme.surfaceDark : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryLight.withOpacity(0.5)
                    : (isDark ? Colors.grey.shade800.withOpacity(0.2) : Colors.grey.shade200),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Selection checkbox or Avatar
                if (_isSelectionMode)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryLight.withOpacity(0.1)
                          : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) => _toggleWorkspaceSelection(workspace.id),
                      activeColor: AppTheme.primaryLight,
                    ),
                  )
                else
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
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            firstLetter,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
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
                            : 'Manage workspace and groups',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${workspace.groupIds.length} groups',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppTheme.primaryLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${workspace.memberIds.length} members',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Arrow or Edit/Delete icons
                if (!_isSelectionMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppTheme.primaryLight,
                        ),
                        onPressed: () => _showEditWorkspaceDialog(context, workspace, isDark),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: () => _showDeleteWorkspaceDialog(workspace),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(Group group, bool isDark) {
    final firstLetter = group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G';
    final isSelected = _selectedGroups.contains(group.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        elevation: isSelected ? 0 : 0.5,
        shadowColor: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
        child: InkWell(
          onTap: () {
            if (_isSelectionMode) {
              _toggleGroupSelection(group.id);
            } else {
              _navigateToGroup(group);
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
              });
              _toggleGroupSelection(group.id);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppTheme.primaryLight.withOpacity(0.15),
                        AppTheme.primaryLight.withOpacity(0.05),
                      ],
                    )
                  : null,
              color: isSelected ? null : (isDark ? AppTheme.surfaceDark : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryLight.withOpacity(0.5)
                    : (isDark ? Colors.grey.shade800.withOpacity(0.2) : Colors.grey.shade200),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Selection checkbox or Avatar
                if (_isSelectionMode)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryLight.withOpacity(0.1)
                          : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) => _toggleGroupSelection(group.id),
                      activeColor: AppTheme.primaryLight,
                    ),
                  )
                else
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
                            : 'Admin group management',
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

                // Edit/Delete icons
                if (!_isSelectionMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppTheme.primaryLight,
                        ),
                        onPressed: () => _showEditGroupDialog(context, group, isDark),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: () => _showDeleteGroupDialog(group),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
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
        onTap: () => _navigateToGroup(group),
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
                          child: Row(
                            children: [
                              Flexible(
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
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ADMIN',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
                                : 'Tap to manage chat',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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

  void _toggleWorkspaceSelection(String workspaceId) {
    setState(() {
      if (_selectedWorkspaces.contains(workspaceId)) {
        _selectedWorkspaces.remove(workspaceId);
      } else {
        _selectedWorkspaces.add(workspaceId);
      }
    });
  }

  void _toggleGroupSelection(String groupId) {
    setState(() {
      if (_selectedGroups.contains(groupId)) {
        _selectedGroups.remove(groupId);
      } else {
        _selectedGroups.add(groupId);
      }
    });
  }

  void _navigateToWorkspace(Workspace workspace) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkspaceScreen(workspace: workspace),
      ),
    );
    setState(() {
      _hasLoaded = false;
    });
    _loadWorkspaces();
  }

  void _navigateToGroup(Group group) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatScreen(group: group),
      ),
    );
    _loadAllGroups();
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

  Widget _buildEmptyState(bool isDark, IconData icon, String title, String message, {VoidCallback? onCreatePressed}) {
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
            if (onCreatePressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onCreatePressed,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Create Workspace'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Create, Edit, Delete Dialogs...
  void _showCreateWorkspaceDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_circle_outline, color: AppTheme.primaryLight),
            const SizedBox(width: 8),
            const Text('Create Workspace'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Workspace Name',
                hintText: 'Enter workspace name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter workspace description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                context.read<CommunityBloc>().add(
                  CreateWorkspace(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditWorkspaceDialog(BuildContext context, Workspace workspace, bool isDark) {
    final nameController = TextEditingController(text: workspace.name);
    final descriptionController = TextEditingController(text: workspace.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: AppTheme.primaryLight),
            const SizedBox(width: 8),
            const Text('Edit Workspace'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Workspace Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final updatedWorkspace = workspace.copyWith(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                );
                final repository = sl<CommunityRepository>();
                repository.updateWorkspace(updatedWorkspace).then((_) {
                  Navigator.pop(context);
                  setState(() {
                    _hasLoaded = false;
                  });
                  _loadWorkspaces();
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog(BuildContext context, Group group, bool isDark) {
    final nameController = TextEditingController(text: group.name);
    final descriptionController = TextEditingController(text: group.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: AppTheme.primaryLight),
            const SizedBox(width: 8),
            const Text('Edit Group'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final updatedGroup = group.copyWith(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                );
                final repository = sl<CommunityRepository>();
                repository.updateGroup(updatedGroup).then((_) {
                  Navigator.pop(context);
                  _loadAllGroups();
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteWorkspaceDialog(Workspace workspace) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Workspace'),
          ],
        ),
        content: Text('Are you sure you want to delete "${workspace.name}"? This will delete all groups and messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CommunityBloc>().add(DeleteWorkspace(workspaceId: workspace.id));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteGroupDialog(Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Group'),
          ],
        ),
        content: Text('Are you sure you want to delete "${group.name}"? This will delete all messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CommunityBloc>().add(DeleteGroup(groupId: group.id));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showBulkDeleteDialog() {
    final workspaceCount = _selectedWorkspaces.length;
    final groupCount = _selectedGroups.length;

    if (workspaceCount == 0 && groupCount == 0) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Selected Items'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (workspaceCount > 0)
              Text('• $workspaceCount workspace(s)'),
            if (groupCount > 0)
              Text('• $groupCount group(s)'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Text(
                'This action cannot be undone!',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedItems();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _deleteSelectedItems() {
    for (final workspaceId in _selectedWorkspaces) {
      context.read<CommunityBloc>().add(DeleteWorkspace(workspaceId: workspaceId));
    }
    for (final groupId in _selectedGroups) {
      context.read<CommunityBloc>().add(DeleteGroup(groupId: groupId));
    }
    _exitSelectionMode();
  }
}
