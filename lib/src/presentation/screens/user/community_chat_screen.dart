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

class CommunityChatScreen extends StatefulWidget {
  const CommunityChatScreen({super.key});

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CommunityBloc>().add(LoadWorkspaces());
  }

  // Remove didChangeDependencies to prevent infinite loading

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          '',
          style: AppTextStyles.h3.copyWith(
            color: isDark ? AppTheme.textPrimaryDark : Colors.white,
            fontWeight: FontWeight.bold,
          ),
          
        ),
        backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.primaryLight,
        foregroundColor: isDark ? AppTheme.textPrimaryDark : Colors.white,
        elevation: 0,
        
      ),
      body: Column(
        children: [
          
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
                            'Hackethos4u Community',
                            style: AppTextStyles.h3.copyWith(
                              color: isDark ? AppTheme.textPrimaryDark : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Connect with fellow learners and experts',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark 
                                  ? AppTheme.textPrimaryDark.withOpacity(0.8)
                                  : Colors.white.withOpacity(0.9),
                            ),
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
                      Icons.workspaces,
                      'Workspaces',
                      isDark,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      Icons.chat_bubble_outline,
                      'Active Chats',
                      isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Workspaces List
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
                  // Reload workspaces after joining
                  context.read<CommunityBloc>().add(LoadWorkspaces());
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
                
                if (state is WorkspacesLoaded) {
                  final workspaces = state.workspaces;
                  
                  if (workspaces.isEmpty) {
                    return _buildEmptyState(isDark);
                  }
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<CommunityBloc>().add(LoadWorkspaces());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: workspaces.length,
                      itemBuilder: (context, index) {
                        final workspace = workspaces[index];
                        return _buildWorkspaceCard(workspace, isDark);
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
                          'Error loading workspaces',
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
                            context.read<CommunityBloc>().add(LoadWorkspaces());
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

  Widget _buildWorkspaceCard(Workspace workspace, bool isDark) {
    final communityRepository = sl<CommunityRepository>();
    final isMember = communityRepository.isUserMemberOfWorkspace(workspace);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isMember ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserWorkspaceScreen(workspace: workspace),
              ),
            );
          } : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.inputBorderDark : Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Workspace Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryLight,
                        AppTheme.primaryLight.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    Icons.workspaces,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Workspace Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workspace.name,
                        style: AppTextStyles.h3.copyWith(
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        workspace.description.isNotEmpty 
                            ? workspace.description 
                            : 'Join the community workspace',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${workspace.memberIds.length} members',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            ),
                          ),
                          if (isMember) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'JOINED',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Join Button or Arrow
                if (isMember)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      context.read<CommunityBloc>().add(JoinWorkspace(workspaceId: workspace.id));
                    },
                    style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Join',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
                Icons.workspaces_outlined,
                size: 64,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Workspaces Yet',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Workspaces will appear here once they are created by admins.',
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
