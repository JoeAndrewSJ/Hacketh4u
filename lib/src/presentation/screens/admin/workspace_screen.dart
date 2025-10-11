import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/community/community_bloc.dart';
import '../../../core/bloc/community/community_event.dart';
import '../../../core/bloc/community/community_state.dart';
import '../../../data/models/community_models.dart';
import 'group_chat_screen.dart';

class WorkspaceScreen extends StatefulWidget {
  final Workspace workspace;

  const WorkspaceScreen({
    super.key,
    required this.workspace,
  });

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload groups when screen becomes active again
    _loadGroups();
  }

  void _loadGroups() {
    // Load groups for this workspace
    context.read<CommunityBloc>().add(LoadGroups(workspaceId: widget.workspace.id));
    // Check if current user is admin
    context.read<CommunityBloc>().add(CheckAdminStatus(workspaceId: widget.workspace.id));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workspace.name),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateGroupDialog(context, isDark),
            tooltip: 'Create Group',
          ),
        ],
      ),
      body: BlocConsumer<CommunityBloc, CommunityState>(
        listener: (context, state) {
          if (state is CommunityError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is GroupCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Group created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CommunityLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is GroupsLoaded) {
            if (state.groups.isEmpty) {
              return _buildEmptyState(context, isDark);
            }
            return _buildGroupsList(context, state.groups, isDark);
          } else if (state is CommunityError) {
            return _buildErrorState(context, state.error, isDark);
          }
          return _buildEmptyState(context, isDark);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 80,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Groups Yet',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first group to start chatting with your team.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showCreateGroupDialog(context, isDark),
              icon: const Icon(Icons.add),
              label: const Text('Create Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.read<CommunityBloc>().add(
                LoadGroups(workspaceId: widget.workspace.id),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsList(BuildContext context, List<Group> groups, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _buildGroupCard(context, group, isDark);
      },
    );
  }

  Widget _buildGroupCard(BuildContext context, Group group, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupChatScreen(group: group),
            ),
          );
          // Reload groups when returning from chat
          _loadGroups();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: isDark 
                ? [Colors.purple[800]!, Colors.purple[700]!]
                : [Colors.purple[50]!, Colors.purple[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    group.isPrivate ? Icons.lock : Icons.public,
                    color: isDark ? Colors.purple[300] : Colors.purple[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      group.name,
                      style: AppTextStyles.h3.copyWith(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${group.messageCount} messages',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                group.description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? Colors.grey[300] : Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${group.memberIds.length} members',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    group.isPrivate ? Icons.lock : Icons.public,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    group.isPrivate ? 'Private' : 'Public',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isPrivate = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: AppTheme.primaryLight,
              ),
              const SizedBox(width: 8),
              const Text('Create Group'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter group description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: isPrivate,
                    onChanged: (value) => setState(() => isPrivate = value ?? false),
                  ),
                  const Text('Make this group private'),
                ],
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
                    CreateGroup(
                      workspaceId: widget.workspace.id,
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      isPrivate: isPrivate,
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
      ),
    );
  }
}
