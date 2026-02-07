import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import '../models/user.dart' as models;

class BuddyConnection {
  final String id;
  final String userId;
  final String buddyId;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;
  final DateTime updatedAt;
  final models.User? buddy; // Buddy's user info

  BuddyConnection({
    required this.id,
    required this.userId,
    required this.buddyId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.buddy,
  });

  factory BuddyConnection.fromJson(Map<String, dynamic> json, {models.User? buddy}) {
    return BuddyConnection(
      id: json['id'],
      userId: json['user_id'],
      buddyId: json['buddy_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at']),
      buddy: buddy,
    );
  }
}

class BuddyService {
  final _supabase = Supabase.instance.client;

  // Get all buddy connections for current user
  Future<List<BuddyConnection>> getBuddyConnections() async {
    developer.log('👥 FETCHING BUDDY CONNECTIONS', name: 'BuddyService');
    
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      // Get connections where user is either user_id or buddy_id
      final userId = currentUser.id;
      final response = await _supabase
          .from('buddy_connections')
          .select()
          .or('user_id.eq.$userId,buddy_id.eq.$userId')
          .eq('status', 'accepted')
          .order('updated_at', ascending: false);

      final connections = <BuddyConnection>[];
      
      for (final conn in response as List) {
        // Get buddy's user info
        final buddyUserId = conn['user_id'] == userId 
            ? conn['buddy_id'] 
            : conn['user_id'];
        
        try {
          final buddyUser = await _supabase
              .from('users')
              .select()
              .eq('id', buddyUserId)
              .single();
          
          final buddy = models.User.fromJson(buddyUser);
          connections.add(BuddyConnection.fromJson(conn, buddy: buddy));
        } catch (e) {
          developer.log('⚠️ Could not fetch buddy user info: $e', name: 'BuddyService');
          connections.add(BuddyConnection.fromJson(conn));
        }
      }

      developer.log('✅ Fetched ${connections.length} buddy connections', name: 'BuddyService');
      return connections;
    } catch (e) {
      developer.log('❌ Error fetching buddy connections: $e', name: 'BuddyService');
      return [];
    }
  }

  // Get pending buddy requests (where user is the recipient)
  Future<List<BuddyConnection>> getPendingRequests() async {
    developer.log('📥 FETCHING PENDING REQUESTS', name: 'BuddyService');
    
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      final response = await _supabase
          .from('buddy_connections')
          .select()
          .eq('buddy_id', currentUser.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final connections = <BuddyConnection>[];
      
      for (final conn in response as List) {
        try {
          final requesterUser = await _supabase
              .from('users')
              .select()
              .eq('id', conn['user_id'])
              .single();
          
          final buddy = models.User.fromJson(requesterUser);
          connections.add(BuddyConnection.fromJson(conn, buddy: buddy));
        } catch (e) {
          developer.log('⚠️ Could not fetch requester user info: $e', name: 'BuddyService');
          connections.add(BuddyConnection.fromJson(conn));
        }
      }

      developer.log('✅ Fetched ${connections.length} pending requests', name: 'BuddyService');
      return connections;
    } catch (e) {
      developer.log('❌ Error fetching pending requests: $e', name: 'BuddyService');
      return [];
    }
  }

  // Send buddy request
  Future<String?> sendBuddyRequest(String buddyEmail) async {
    developer.log('📤 SENDING BUDDY REQUEST', name: 'BuddyService');
    developer.log('📧 Buddy email: $buddyEmail', name: 'BuddyService');
    
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        developer.log('❌ No current user', name: 'BuddyService');
        return 'Not authenticated';
      }

      // Find user by email
      final buddyUserResponse = await _supabase
          .from('users')
          .select()
          .eq('email', buddyEmail.toLowerCase())
          .maybeSingle();

      if (buddyUserResponse == null) {
        return 'User not found';
      }

      final buddyId = buddyUserResponse['id'];
      final buddyRole = buddyUserResponse['role'];
      
      // Only allow students to be buddies
      if (buddyRole != 'student') {
        return 'Buddy system is only available for students';
      }
      
      final userId = currentUser.id;
      
      if (buddyId == userId) {
        return 'Cannot add yourself as a buddy';
      }

      // Check if connection already exists
      final existing = await _supabase
          .from('buddy_connections')
          .select()
          .or('user_id.eq.$userId,buddy_id.eq.$userId')
          .or('user_id.eq.$buddyId,buddy_id.eq.$buddyId');

      if ((existing as List).isNotEmpty) {
        return 'Buddy connection already exists';
      }

      // Create buddy request
      final response = await _supabase
          .from('buddy_connections')
          .insert({
            'user_id': userId,
            'buddy_id': buddyId,
            'status': 'pending',
          })
          .select('id')
          .single();

      developer.log('✅ Buddy request sent: ${response['id']}', name: 'BuddyService');
      return null; // Success
    } catch (e) {
      developer.log('❌ Error sending buddy request: $e', name: 'BuddyService');
      if (e.toString().contains('duplicate')) {
        return 'Buddy connection already exists';
      }
      return e.toString();
    }
  }

  // Accept buddy request
  Future<bool> acceptBuddyRequest(String connectionId) async {
    developer.log('✅ ACCEPTING BUDDY REQUEST', name: 'BuddyService');
    developer.log('🆔 Connection ID: $connectionId', name: 'BuddyService');
    
    try {
      await _supabase
          .from('buddy_connections')
          .update({
            'status': 'accepted',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', connectionId);

      developer.log('✅ Buddy request accepted', name: 'BuddyService');
      return true;
    } catch (e) {
      developer.log('❌ Error accepting buddy request: $e', name: 'BuddyService');
      return false;
    }
  }

  // Reject buddy request
  Future<bool> rejectBuddyRequest(String connectionId) async {
    developer.log('❌ REJECTING BUDDY REQUEST', name: 'BuddyService');
    developer.log('🆔 Connection ID: $connectionId', name: 'BuddyService');
    
    try {
      await _supabase
          .from('buddy_connections')
          .update({
            'status': 'rejected',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', connectionId);

      developer.log('✅ Buddy request rejected', name: 'BuddyService');
      return true;
    } catch (e) {
      developer.log('❌ Error rejecting buddy request: $e', name: 'BuddyService');
      return false;
    }
  }

  // Remove buddy connection
  Future<bool> removeBuddy(String connectionId) async {
    developer.log('🗑️ REMOVING BUDDY', name: 'BuddyService');
    developer.log('🆔 Connection ID: $connectionId', name: 'BuddyService');
    
    try {
      await _supabase
          .from('buddy_connections')
          .delete()
          .eq('id', connectionId);

      developer.log('✅ Buddy removed', name: 'BuddyService');
      return true;
    } catch (e) {
      developer.log('❌ Error removing buddy: $e', name: 'BuddyService');
      return false;
    }
  }

  // Search users by email or student ID
  Future<List<models.User>> searchUsers(String query) async {
    developer.log('🔍 SEARCHING USERS', name: 'BuddyService');
    developer.log('🔎 Query: $query', name: 'BuddyService');
    
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      // Search by email or student_id
      final response = await _supabase
          .from('users')
          .select()
          .or('email.ilike.%$query%,student_id.ilike.%$query%')
          .eq('role', 'student')
          .neq('id', currentUser.id)
          .limit(10);

      final users = (response as List)
          .map((user) => models.User.fromJson(user))
          .toList();

      developer.log('✅ Found ${users.length} users', name: 'BuddyService');
      return users;
    } catch (e) {
      developer.log('❌ Error searching users: $e', name: 'BuddyService');
      return [];
    }
  }
}

