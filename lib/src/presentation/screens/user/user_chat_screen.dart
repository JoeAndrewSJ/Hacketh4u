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
  late Future<List<Message>> _messagesFuture;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    if (!_hasLoaded) {
      // Load messages for this group
      context.read<CommunityBloc>().add(LoadMessages(groupId: widget.group.id));
      
      // Fetch messages once in initState
      _messagesFuture = _fetchMessages();
      _hasLoaded = true;
    }
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryLight,
                    AppTheme.primaryLight.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.group,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isDark ? AppTheme.textPrimaryDark : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${widget.group.memberIds.length} members',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark 
                          ? AppTheme.textPrimaryDark.withOpacity(0.7)
                          : Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.primaryLight,
        foregroundColor: isDark ? AppTheme.textPrimaryDark : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? AppTheme.textPrimaryDark : Colors.white,
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error),
                      backgroundColor: Colors.red,
                    ),
                  );
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All messages deleted'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              builder: (context, state) {
                return FutureBuilder<List<Message>>(
                  future: _messagesFuture,
                  builder: (context, snapshot) {
                    print('📱 FutureBuilder - ConnectionState: ${snapshot.connectionState}');
                    print('📱 FutureBuilder - HasData: ${snapshot.hasData}');
                    print('📱 FutureBuilder - HasError: ${snapshot.hasError}');
                    
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
                              const SizedBox(height: 8),
                              Text(
                                '${snapshot.error}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Handle loading state
                    if (snapshot.connectionState == ConnectionState.waiting) {
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

                    // Get messages from snapshot
                    final messages = snapshot.data ?? [];
                    print('📱 Displaying ${messages.length} messages');
                    
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
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            // Sender Avatar (only for others)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryLight,
                    AppTheme.primaryLight.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Message Container
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe 
                    ? (isDark ? AppTheme.primaryLight : AppTheme.primaryLight)
                    : (isDark ? AppTheme.surfaceDark : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && isFirst) ...[
                    // Sender Name
                    Text(
                      message.senderName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppTheme.primaryLight : AppTheme.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  // Message Content
                  Text(
                    message.content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isMe 
                          ? Colors.white
                          : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                    ),
                  ),
                  
                  if (isLast) ...[
                    const SizedBox(height: 4),
                    // Timestamp
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isMe 
                                ? Colors.white.withOpacity(0.7)
                                : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                            fontSize: 11,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all,
                            size: 16,
                            color: Colors.white.withOpacity(0.7),
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
            const SizedBox(width: 8),
            // My Avatar (only for my messages)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green,
                    Colors.green.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.inputBorderDark : Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          
          
          
          
          // Text Input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.backgroundDark : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Send Button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
              onPressed: _sendMessage,
            ),
          ),
        ],
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
                color: AppTheme.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Start the Conversation!',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to send a message in ${widget.group.name}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _messageController.clear();
                _messageController.text = '👋 Hello everyone!';
                _sendMessage();
              },
              icon: const Icon(Icons.send),
              label: const Text('Send Hello Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
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
      
      // Send message through BLoC only (not repository directly)
      try {
        context.read<CommunityBloc>().add(
          SendMessage(
            groupId: widget.group.id,
            content: content,
            type: MessageType.text,
          ),
        );
        
        // Refresh messages after sending
        if (mounted) {
          setState(() {
            _messagesFuture = _fetchMessages();
          });
        }
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
