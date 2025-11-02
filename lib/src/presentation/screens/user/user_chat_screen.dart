import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/bloc/community/community_bloc.dart';
import '../../../core/bloc/community/community_event.dart';
import '../../../core/bloc/community/community_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/community_models.dart';
import '../../../data/repositories/community_repository.dart';
import '../../widgets/common/custom_snackbar.dart';

class UserChatScreen extends StatefulWidget {
  final Group group;

  const UserChatScreen({
    super.key,
    required this.group,
  });

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Stream<List<Message>>? _messagesStream;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    // Set up the message stream for real-time updates
    final communityRepository = sl<CommunityRepository>();
    _messagesStream = communityRepository.getGroupMessagesStream(widget.group.id);
    
    // Load messages for this group
    context.read<CommunityBloc>().add(LoadMessages(groupId: widget.group.id));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : Colors.grey.shade100,
      appBar: AppBar(
        title: Row(
          children: [
            // Group avatar with cleaner design
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.group_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Group info with better hierarchy
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.group.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.people_rounded,
                        size: 12,
                        color: Colors.white.withOpacity(0.75),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.group.memberIds.length} members',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.75),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
         
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? AppTheme.textPrimaryDark : Colors.white,
            ),
            onSelected: (value) {
              switch (value) {
                case 'info':
                  _showGroupInfo(context);
                  break;
                case 'media':
                  _showMedia(context);
                  break;
                case 'search':
                  _showSearch(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('Group Info'),
                  ],
                ),
              ),
              
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<CommunityBloc, CommunityState>(
              listener: (context, state) {
                if (state is CommunityError) {
                  // Professional dark SnackBar instead of bright red
                  CustomSnackBar.showError(context, state.error);
                } else if (state is MessageSent) {
                  // Scroll to bottom when new message is sent
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                } else if (state is AllMessagesDeleted) {
                  // Professional dark SnackBar instead of bright orange
                  CustomSnackBar.showInfo(context, 'All messages deleted');
                }
              },
              builder: (context, state) {
                // Show loading if stream is not initialized yet
                if (_messagesStream == null) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading messages...'),
                      ],
                    ),
                  );
                }
                
                return StreamBuilder<List<Message>>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    // Handle loading state
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading messages...'),
                          ],
                        ),
                      );
                    }
                    
                    // Handle error state
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Error loading messages',
                                style: AppTextStyles.h3.copyWith(
                                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Please check your connection and try again',
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
                    
                    // Get messages from snapshot
                    final messages = snapshot.data ?? [];
                    
                    // Show empty state if no messages
                    if (messages.isEmpty) {
                      return _buildEmptyState(isDark);
                    }

                    // Auto-scroll to bottom when messages are loaded
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });

                    // Show messages
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return Container(
                          key: ValueKey('${message.id}_${message.timestamp.millisecondsSinceEpoch}'),
                          child: _buildMessageBubble(message, isDark),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(isDark),
        ],
      ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isDark) {
    final isMe = message.senderId == _getCurrentUserId();
    final isFirst = true; // For now, always show name
    final isLast = true; // For now, always show time

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            // Sender Avatar - neutral design
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),  // Neutral gray
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : const Color(0xFFE0E0E0),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.person,
                color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF4A4A4A),  // Dark gray
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Message Container
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: isMe
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryLight,
                          AppTheme.primaryLight.withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe ? null : (isDark ? AppTheme.surfaceDark : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.15),  // Neutral shadows
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: isMe
                    ? null
                    : Border.all(
                        color: isDark ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade300,
                        width: 1,
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && isFirst) ...[
                    // Sender Name with badge
                    Row(
                      children: [
                        Text(
                          message.senderName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.primaryLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Message Content
                  Text(
                    message.content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isMe
                          ? Colors.white
                          : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                      fontSize: 15,
                      height: 1.4,
                      letterSpacing: 0.2,
                    ),
                  ),

                  if (isLast) ...[
                    const SizedBox(height: 6),
                    // Timestamp with icon
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: isMe
                              ? Colors.white.withOpacity(0.8)
                              : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(message.timestamp),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isMe
                                ? Colors.white.withOpacity(0.8)
                                : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.done_all,
                              size: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (isMe) ...[
            const SizedBox(width: 10),
            // My Avatar - neutral design
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),  // Neutral gray
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : const Color(0xFFE0E0E0),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.person,
                color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF4A4A4A),  // Dark gray
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.grey.shade800 : const Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text Input - Clean design with border
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : const Color(0xFFE0E0E0),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white38 : const Color(0xFFAAAAAA),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                  maxLines: 5,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Send Button - Clean rounded design
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryLight,
                    AppTheme.primaryLight.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryLight.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _sendMessage,
                  child: const Center(
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
            // App Logo with modern design
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: AppTheme.primaryLight.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryLight.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 50,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No messages yet',
              style: AppTextStyles.h2.copyWith(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start the conversation! 🚀',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Be the first to send a message in this group.\nLet\'s get the discussion started!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      // Clear the input immediately for better UX
      _messageController.clear();
      
      // Send message through BLoC
      try {
        context.read<CommunityBloc>().add(
          SendMessage(
            groupId: widget.group.id,
            content: content,
            type: MessageType.text,
          ),
        );
        
        // No need to manually update UI - StreamBuilder will handle real-time updates
      } catch (e) {
        print('Error sending message: $e');
        // Restore message content if sending failed
        if (mounted) {
          _messageController.text = content;
        }
      }
    }
  }

  Future<List<Message>> _fetchMessages() async {
    // Get the repository directly from service locator
    final communityRepository = sl<CommunityRepository>();
    print('🎯 Fetching messages for group: ${widget.group.id}');
    
    return await communityRepository.getGroupMessages(widget.group.id);
  }

  String _getCurrentUserId() {
    final auth = FirebaseAuth.instance;
    return auth.currentUser?.uid ?? 'unknown_user';
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  void _showGroupInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.group.name,
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.group.description.isNotEmpty) ...[
              Text(
                'Description',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(widget.group.description),
              const SizedBox(height: 16),
            ],
            Text(
              'Members',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text('${widget.group.memberIds.length} members'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMedia(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Media feature coming soon!')),
    );
  }

  void _showSearch(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search feature coming soon!')),
    );
  }
}
