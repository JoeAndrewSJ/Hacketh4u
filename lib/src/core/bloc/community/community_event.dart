import '../../../data/models/community_models.dart';

abstract class CommunityEvent {}

// Workspace Events
class CreateWorkspace extends CommunityEvent {
  final String name;
  final String description;

  CreateWorkspace({
    required this.name,
    required this.description,
  });
}

class LoadWorkspaces extends CommunityEvent {}

class LoadWorkspace extends CommunityEvent {
  final String workspaceId;

  LoadWorkspace({required this.workspaceId});
}

class UpdateWorkspace extends CommunityEvent {
  final Workspace workspace;

  UpdateWorkspace({required this.workspace});
}

// Group Events
class CreateGroup extends CommunityEvent {
  final String workspaceId;
  final String name;
  final String description;
  final bool isPrivate;
  final List<String>? memberIds;

  CreateGroup({
    required this.workspaceId,
    required this.name,
    required this.description,
    required this.isPrivate,
    this.memberIds,
  });
}

class LoadGroups extends CommunityEvent {
  final String workspaceId;

  LoadGroups({required this.workspaceId});
}

class LoadGroup extends CommunityEvent {
  final String groupId;

  LoadGroup({required this.groupId});
}

class UpdateGroup extends CommunityEvent {
  final Group group;

  UpdateGroup({required this.group});
}

class DeleteGroup extends CommunityEvent {
  final String groupId;

  DeleteGroup({required this.groupId});
}

class DeleteWorkspace extends CommunityEvent {
  final String workspaceId;

  DeleteWorkspace({required this.workspaceId});
}

// Message Events
class SendMessage extends CommunityEvent {
  final String groupId;
  final String content;
  final MessageType type;
  final List<String>? attachmentUrls;
  final String? replyToMessageId;

  SendMessage({
    required this.groupId,
    required this.content,
    required this.type,
    this.attachmentUrls,
    this.replyToMessageId,
  });
}

class LoadMessages extends CommunityEvent {
  final String groupId;
  final int limit;

  LoadMessages({
    required this.groupId,
    this.limit = 50,
  });
}

class EditMessage extends CommunityEvent {
  final String messageId;
  final String newContent;

  EditMessage({
    required this.messageId,
    required this.newContent,
  });
}

class DeleteMessage extends CommunityEvent {
  final String messageId;
  final bool isAdmin;

  DeleteMessage({
    required this.messageId,
    required this.isAdmin,
  });
}

class DeleteAllMessages extends CommunityEvent {
  final String groupId;

  DeleteAllMessages({required this.groupId});
}

class AddReaction extends CommunityEvent {
  final String messageId;
  final String emoji;

  AddReaction({
    required this.messageId,
    required this.emoji,
  });
}

class RemoveReaction extends CommunityEvent {
  final String messageId;
  final String emoji;

  RemoveReaction({
    required this.messageId,
    required this.emoji,
  });
}

// User Events
class LoadUserProfile extends CommunityEvent {
  final String uid;

  LoadUserProfile({required this.uid});
}

class UpdateUserProfile extends CommunityEvent {
  final UserProfile profile;

  UpdateUserProfile({required this.profile});
}

class SetUserOnlineStatus extends CommunityEvent {
  final bool isOnline;

  SetUserOnlineStatus({required this.isOnline});
}

// Admin Events
class CheckAdminStatus extends CommunityEvent {
  final String workspaceId;

  CheckAdminStatus({required this.workspaceId});
}

class RemoveUserFromWorkspace extends CommunityEvent {
  final String workspaceId;
  final String userId;

  RemoveUserFromWorkspace({
    required this.workspaceId,
    required this.userId,
  });
}

class RemoveUserFromGroup extends CommunityEvent {
  final String groupId;
  final String userId;

  RemoveUserFromGroup({
    required this.groupId,
    required this.userId,
  });
}

// Join/Leave Events
class JoinWorkspace extends CommunityEvent {
  final String workspaceId;

  JoinWorkspace({required this.workspaceId});
}

class LeaveWorkspace extends CommunityEvent {
  final String workspaceId;

  LeaveWorkspace({required this.workspaceId});
}

class JoinGroup extends CommunityEvent {
  final String groupId;

  JoinGroup({required this.groupId});
}

class LeaveGroup extends CommunityEvent {
  final String groupId;

  LeaveGroup({required this.groupId});
}

// Utility Events
class ClearError extends CommunityEvent {}

class ResetState extends CommunityEvent {}
