import 'package:cloud_firestore/cloud_firestore.dart';

class Workspace {
  final String id;
  final String name;
  final String description;
  final String adminId;
  final List<String> memberIds;
  final List<String> groupIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Workspace({
    required this.id,
    required this.name,
    required this.description,
    required this.adminId,
    required this.memberIds,
    required this.groupIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Workspace.fromMap(Map<String, dynamic> data) {
    return Workspace(
      id: data['id'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      adminId: data['adminId'] as String,
      memberIds: List<String>.from(data['memberIds'] ?? []),
      groupIds: List<String>.from(data['groupIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'adminId': adminId,
      'memberIds': memberIds,
      'groupIds': groupIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Workspace copyWith({
    String? id,
    String? name,
    String? description,
    String? adminId,
    List<String>? memberIds,
    List<String>? groupIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      adminId: adminId ?? this.adminId,
      memberIds: memberIds ?? this.memberIds,
      groupIds: groupIds ?? this.groupIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Group {
  final String id;
  final String workspaceId;
  final String name;
  final String description;
  final String createdBy;
  final List<String> memberIds;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  const Group({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.memberIds,
    required this.isPrivate,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
  });

  factory Group.fromMap(Map<String, dynamic> data) {
    return Group(
      id: data['id'] as String,
      workspaceId: data['workspaceId'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      createdBy: data['createdBy'] as String,
      memberIds: List<String>.from(data['memberIds'] ?? []),
      isPrivate: data['isPrivate'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      messageCount: data['messageCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workspaceId': workspaceId,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'memberIds': memberIds,
      'isPrivate': isPrivate,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'messageCount': messageCount,
    };
  }

  Group copyWith({
    String? id,
    String? workspaceId,
    String? name,
    String? description,
    String? createdBy,
    List<String>? memberIds,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? messageCount,
  }) {
    return Group(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      memberIds: memberIds ?? this.memberIds,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
    );
  }
}

class Message {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final List<String>? attachmentUrls;
  final DateTime timestamp;
  final bool isEdited;
  final bool isDeleted;
  final String? replyToMessageId;
  final List<String> reactions;

  const Message({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    this.attachmentUrls,
    required this.timestamp,
    required this.isEdited,
    required this.isDeleted,
    this.replyToMessageId,
    required this.reactions,
  });

  factory Message.fromMap(Map<String, dynamic> data, [String? documentId]) {
    return Message(
      id: data['id'] as String? ?? documentId ?? '',
      groupId: data['groupId'] as String,
      senderId: data['senderId'] as String,
      senderName: data['senderName'] as String,
      content: data['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      attachmentUrls: data['attachmentUrls'] != null 
          ? List<String>.from(data['attachmentUrls'])
          : null,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isEdited: data['isEdited'] as bool? ?? false,
      isDeleted: data['isDeleted'] as bool? ?? false,
      replyToMessageId: data['replyToMessageId'] as String?,
      reactions: List<String>.from(data['reactions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.toString().split('.').last,
      'attachmentUrls': attachmentUrls,
      'timestamp': Timestamp.fromDate(timestamp),
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'replyToMessageId': replyToMessageId,
      'reactions': reactions,
    };
  }

  Message copyWith({
    String? id,
    String? groupId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    List<String>? attachmentUrls,
    DateTime? timestamp,
    bool? isEdited,
    bool? isDeleted,
    String? replyToMessageId,
    List<String>? reactions,
  }) {
    return Message(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      timestamp: timestamp ?? this.timestamp,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      reactions: reactions ?? this.reactions,
    );
  }
}

enum MessageType {
  text,
  image,
  file,
  system,
}

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? profileImageUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.isOnline,
    this.lastSeen,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      profileImageUrl: data['profileImageUrl'] as String?,
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: data['lastSeen'] != null 
          ? (data['lastSeen'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    };
  }
}
