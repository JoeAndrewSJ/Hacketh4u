import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_models.dart';

class CommunityRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CommunityRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore, _auth = auth;

  // Helper method to get all user IDs
  Future<List<String>> _getAllUserIds() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting all user IDs: $e');
      // Return current user as fallback
      final user = _auth.currentUser;
      return user != null ? [user.uid] : [];
    }
  }

  // Workspace Operations
  Future<Workspace> createWorkspace({
    required String name,
    required String description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final workspaceId = _firestore.collection('workspaces').doc().id;
    final workspace = Workspace(
      id: workspaceId,
      name: name,
      description: description,
      adminId: user.uid,
      memberIds: [user.uid], // Only admin is a member initially
      groupIds: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('workspaces').doc(workspaceId).set(workspace.toMap());
    print('📋 Created workspace - users can join manually');
    return workspace;
  }

  Future<Workspace?> getWorkspace(String workspaceId) async {
    try {
      final doc = await _firestore.collection('workspaces').doc(workspaceId).get();
      if (doc.exists) {
        return Workspace.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting workspace: $e');
      return null;
    }
  }

  Future<List<Workspace>> getUserWorkspaces() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get all workspaces (not filtered by membership) so users can see all workspaces created by admins
      final querySnapshot = await _firestore
          .collection('workspaces')
          .get();

      // Convert to list and sort client-side
      final workspaces = querySnapshot.docs
          .map((doc) => Workspace.fromMap(doc.data()))
          .toList();

      // Sort by updatedAt in descending order
      workspaces.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      print('📋 Found ${workspaces.length} workspaces for user');
      return workspaces;
    } catch (e) {
      print('Error getting user workspaces: $e');
      return [];
    }
  }

  Future<void> updateWorkspace(Workspace workspace) async {
    await _firestore.collection('workspaces').doc(workspace.id).update({
      ...workspace.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> joinWorkspace(String workspaceId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('workspaces').doc(workspaceId).update({
      'memberIds': FieldValue.arrayUnion([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('📋 User joined workspace: $workspaceId');
  }

  Future<void> leaveWorkspace(String workspaceId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('workspaces').doc(workspaceId).update({
      'memberIds': FieldValue.arrayRemove([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('📋 User left workspace: $workspaceId');
  }

  // Group Operations
  Future<Group> createGroup({
    required String workspaceId,
    required String name,
    required String description,
    required bool isPrivate,
    List<String>? memberIds,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final groupId = _firestore.collection('groups').doc().id;
    final group = Group(
      id: groupId,
      workspaceId: workspaceId,
      name: name,
      description: description,
      createdBy: user.uid,
      memberIds: memberIds ?? [user.uid], // Only creator is a member initially
      isPrivate: isPrivate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messageCount: 0,
    );

    // Create group
    await _firestore.collection('groups').doc(groupId).set(group.toMap());

    // Add group to workspace
    await _firestore.collection('workspaces').doc(workspaceId).update({
      'groupIds': FieldValue.arrayUnion([groupId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('📋 Created group - users can join manually');
    return group;
  }

  Future<List<Group>> getWorkspaceGroups(String workspaceId) async {
    try {
      // Get all groups by workspaceId (not filtered by membership) so users can see all groups created by admins
      final querySnapshot = await _firestore
          .collection('groups')
          .where('workspaceId', isEqualTo: workspaceId)
          .get();

      // Convert to list and sort client-side
      final groups = querySnapshot.docs
          .map((doc) => Group.fromMap(doc.data()))
          .toList();

      // Sort by updatedAt in descending order
      groups.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      print('📋 Found ${groups.length} groups in workspace $workspaceId');
      return groups;
    } catch (e) {
      print('Error getting workspace groups: $e');
      return [];
    }
  }

  Future<Group?> getGroup(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (doc.exists) {
        return Group.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting group: $e');
      return null;
    }
  }

  Future<void> updateGroup(Group group) async {
    await _firestore.collection('groups').doc(group.id).update({
      ...group.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> joinGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('📋 User joined group: $groupId');
  }

  Future<void> leaveGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('📋 User left group: $groupId');
  }

  // Helper methods to check membership
  bool isUserMemberOfWorkspace(Workspace workspace) {
    final user = _auth.currentUser;
    if (user == null) return false;
    return workspace.memberIds.contains(user.uid);
  }

  bool isUserMemberOfGroup(Group group) {
    final user = _auth.currentUser;
    if (user == null) return false;
    return group.memberIds.contains(user.uid);
  }

  Future<void> deleteGroup(String groupId) async {
    // Get the group to find its workspace
    final group = await getGroup(groupId);
    if (group == null) throw Exception('Group not found');

    // Delete all messages in the group
    final messagesSnapshot = await _firestore
        .collection('messages')
        .where('groupId', isEqualTo: groupId)
        .get();
    
    final batch = _firestore.batch();
    for (final doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete the group
    batch.delete(_firestore.collection('groups').doc(groupId));

    // Remove group from workspace
    batch.update(
      _firestore.collection('workspaces').doc(group.workspaceId),
      {
        'groupIds': FieldValue.arrayRemove([groupId]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
    print('🗑️ Deleted group $groupId and all its messages');
  }

  Future<void> deleteWorkspace(String workspaceId) async {
    // Get the workspace to find all its groups
    final workspace = await getWorkspace(workspaceId);
    if (workspace == null) throw Exception('Workspace not found');

    // Delete all groups in the workspace (this will also delete all messages)
    for (final groupId in workspace.groupIds) {
      await deleteGroup(groupId);
    }

    // Delete the workspace
    await _firestore.collection('workspaces').doc(workspaceId).delete();
    print('🗑️ Deleted workspace $workspaceId and all its groups and messages');
  }

  // Message Operations
  Future<Message> sendMessage({
    required String groupId,
    required String content,
    MessageType type = MessageType.text,
    List<String>? attachmentUrls,
    String? replyToMessageId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final messageId = _firestore.collection('messages').doc().id;
    final message = Message(
      id: messageId,
      groupId: groupId,
      senderId: user.uid,
      senderName: user.displayName ?? user.email ?? 'Unknown',
      content: content,
      type: type,
      attachmentUrls: attachmentUrls,
      timestamp: DateTime.now(),
      isEdited: false,
      isDeleted: false,
      replyToMessageId: replyToMessageId,
      reactions: [],
    );

    print('Sending message: ${message.content} to group: $groupId');

    // Save message
    await _firestore.collection('messages').doc(messageId).set(message.toMap());
    print('Message saved to Firestore with ID: $messageId');

    // Update group message count and last updated
    await _firestore.collection('groups').doc(groupId).update({
      'messageCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('Group updated with new message count');

    return message;
  }

Future<List<Message>> getGroupMessages(String groupId, {int limit = 50}) async {
  print('📥 Fetching messages for group: $groupId');
  
  try {
    final snapshot = await _firestore
        .collection('messages')
        .where('groupId', isEqualTo: groupId)
        .get();
    
    print('📩 Got ${snapshot.docs.length} documents');
    
    final messages = snapshot.docs
        .map((doc) {
          try {
            return Message.fromMap(doc.data(), doc.id);
          } catch (e) {
            print('❌ Parse error for ${doc.id}: $e');
            return null;
          }
        })
        .whereType<Message>()
        .where((msg) => !msg.isDeleted)
        .toList();
    
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final result = messages.length > limit ? messages.take(limit).toList() : messages;
    print('✅ Returning ${result.length} messages');
    return result;
  } catch (e) {
    print('❌ Error fetching messages: $e');
    return [];
  }
}

Stream<List<Message>> getGroupMessagesStream(String groupId, {int limit = 50}) {
  print('📡 Setting up message stream for group: $groupId');
  
  return _firestore
      .collection('messages')
      .where('groupId', isEqualTo: groupId)
      .snapshots()
      .map((snapshot) {
        print('📡 Stream update: ${snapshot.docs.length} messages');
        
        final messages = snapshot.docs
            .map((doc) {
              try {
                return Message.fromMap(doc.data(), doc.id);
              } catch (e) {
                print('❌ Parse error for ${doc.id}: $e');
                return null;
              }
            })
            .whereType<Message>()
            .where((msg) => !msg.isDeleted)
            .toList();
        
        // Sort by timestamp in ascending order (oldest first)
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        // Apply limit after sorting
        final result = messages.length > limit ? messages.take(limit).toList() : messages;
        print('✅ Stream returning ${result.length} messages');
        return result;
      });
}

  Future<String> _testQuery(String groupId) async {
    try {
      print('=== TESTING FIRESTORE QUERY ===');
      print('Testing query for group: $groupId');
      
      // First, let's check if the messages collection exists at all
      final allMessagesSnapshot = await _firestore
          .collection('messages')
          .limit(5)
          .get();
      
      print('Total messages in collection: ${allMessagesSnapshot.docs.length}');
      if (allMessagesSnapshot.docs.isNotEmpty) {
        print('Sample message document:');
        print('- Document ID: ${allMessagesSnapshot.docs.first.id}');
        print('- Document data: ${allMessagesSnapshot.docs.first.data()}');
      }
      
      // Now test the specific group query
      final snapshot = await _firestore
          .collection('messages')
          .where('groupId', isEqualTo: groupId)
          .limit(10)
          .get();
      
      print('Query for group $groupId returned ${snapshot.docs.length} documents');
      
      if (snapshot.docs.isNotEmpty) {
        print('Sample group message:');
        print('- Document ID: ${snapshot.docs.first.id}');
        print('- Document data: ${snapshot.docs.first.data()}');
      }
      
      print('=== END TEST QUERY ===');
      return 'Test query successful: ${snapshot.docs.length} documents found for group $groupId';
    } catch (e) {
      print('Test query failed: $e');
      print('Error details: ${e.toString()}');
      return 'Test query failed: $e';
    }
  }


  Future<void> editMessage(String messageId, String newContent) async {
    await _firestore.collection('messages').doc(messageId).update({
      'content': newContent,
      'isEdited': true,
    });
  }

  Future<void> deleteMessage(String messageId, {bool isAdmin = false}) async {
    if (isAdmin) {
      // Admin can permanently delete
      await _firestore.collection('messages').doc(messageId).delete();
    } else {
      // Regular user can only mark as deleted
      await _firestore.collection('messages').doc(messageId).update({
        'content': 'This message was deleted',
        'isDeleted': true,
      });
    }
  }

  Future<void> deleteAllMessages(String groupId) async {
    final batch = _firestore.batch();
    final messagesSnapshot = await _firestore
        .collection('messages')
        .where('groupId', isEqualTo: groupId)
        .get();

    for (final doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    // Reset group message count
    await _firestore.collection('groups').doc(groupId).update({
      'messageCount': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addReaction(String messageId, String emoji) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('messages').doc(messageId).update({
      'reactions': FieldValue.arrayUnion(['$emoji:${user.uid}']),
    });
  }

  Future<void> removeReaction(String messageId, String emoji) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('messages').doc(messageId).update({
      'reactions': FieldValue.arrayRemove(['$emoji:${user.uid}']),
    });
  }

  // User Operations
  Future<UserProfile> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromMap(doc.data()!);
    } else {
      // Create default profile if doesn't exist
      final user = _auth.currentUser!;
      final profile = UserProfile(
        uid: uid,
        name: user.displayName ?? user.email ?? 'Unknown',
        email: user.email ?? '',
        profileImageUrl: user.photoURL,
        isOnline: true,
        lastSeen: DateTime.now(),
      );
      await _firestore.collection('users').doc(uid).set(profile.toMap());
      return profile;
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _firestore.collection('users').doc(profile.uid).set(profile.toMap());
  }

  Future<void> setUserOnlineStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // Admin Operations
  Future<bool> isAdmin(String workspaceId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final workspace = await getWorkspace(workspaceId);
    return workspace?.adminId == user.uid;
  }

  Future<void> removeUserFromWorkspace(String workspaceId, String userId) async {
    await _firestore.collection('workspaces').doc(workspaceId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeUserFromGroup(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
