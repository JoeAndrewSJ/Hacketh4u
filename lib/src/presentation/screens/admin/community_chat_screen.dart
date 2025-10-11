import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/community/community_bloc.dart';
import '../../../core/bloc/community/community_event.dart';
import '../../../core/bloc/community/community_state.dart';
import '../../../data/models/community_models.dart';
import '../../../core/di/service_locator.dart';
import 'workspace_screen.dart';

class CommunityChatScreen extends StatefulWidget {
  const CommunityChatScreen({super.key});

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  @override
  void initState() {
    super.initState();
    _loadWorkspaces();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload workspaces when screen becomes active again
    _loadWorkspaces();
  }

  void _loadWorkspaces() {
    context.read<CommunityBloc>().add(LoadWorkspaces());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hackethos4u Workspace'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateWorkspaceDialog(context, isDark),
            tooltip: 'Create Workspace',
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
          } else if (state is WorkspaceCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Workspace created successfully!'),
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
          } else if (state is WorkspacesLoaded) {
            if (state.workspaces.isEmpty) {
              return _buildEmptyState(context, isDark);
            }
            return _buildWorkspacesList(context, state.workspaces, isDark);
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
              Icons.workspaces_outlined,
              size: 80,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Workspaces Yet',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first workspace to start collaborating with your team.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showCreateWorkspaceDialog(context, isDark),
              icon: const Icon(Icons.add),
              label: const Text('Create Workspace'),
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
              onPressed: () => context.read<CommunityBloc>().add(LoadWorkspaces()),
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

  Widget _buildWorkspacesList(BuildContext context, List<Workspace> workspaces, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workspaces.length,
      itemBuilder: (context, index) {
        final workspace = workspaces[index];
        return _buildWorkspaceCard(context, workspace, isDark);
      },
    );
  }

  Widget _buildWorkspaceCard(BuildContext context, Workspace workspace, bool isDark) {
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
              builder: (context) => WorkspaceScreen(workspace: workspace),
            ),
          );
          // Reload workspaces when returning from workspace
          _loadWorkspaces();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: isDark 
                ? [Colors.blue[800]!, Colors.blue[700]!]
                : [Colors.blue[50]!, Colors.blue[100]!],
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
                    Icons.workspaces,
                    color: isDark ? Colors.blue[300] : Colors.blue[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      workspace.name,
                      style: AppTextStyles.h3.copyWith(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${workspace.groupIds.length} Groups',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                workspace.description,
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
                    '${workspace.memberIds.length} members',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(workspace.updatedAt),
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

  void _showCreateWorkspaceDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: AppTheme.primaryLight,
            ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
