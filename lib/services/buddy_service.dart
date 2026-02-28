import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;

class BuddyConnection {
  final String id;
  final String userId;
  final String buddyId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final models.User? buddy;

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

  Future<List<BuddyConnection>> getBuddyConnections() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      final userId = currentUser.id;
      final response = await _supabase
          .from('buddy_connections')
          .select()
          .or('user_id.eq.$userId,buddy_id.eq.$userId')
          .eq('status', 'accepted')
          .order('updated_at', ascending: false);

      final connections = <BuddyConnection>[];
      for (final conn in response as List) {
        final buddyUserId = conn['user_id'] == userId ? conn['buddy_id'] : conn['user_id'];
        try {
          final buddyUser = await _supabase
              .from('users')
              .select()
              .eq('id', buddyUserId)
              .single();
          connections.add(BuddyConnection.fromJson(conn, buddy: models.User.fromJson(buddyUser)));
        } catch (e) {
          connections.add(BuddyConnection.fromJson(conn));
        }
      }
      return connections;
    } catch (e) {
      return [];
    }
  }

  Future<List<BuddyConnection>> getPendingRequests() async {
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
          connections.add(BuddyConnection.fromJson(conn, buddy: models.User.fromJson(requesterUser)));
        } catch (e) {
          connections.add(BuddyConnection.fromJson(conn));
        }
      }
      return connections;
    } catch (e) {
      return [];
    }
  }

  Future<String?> sendBuddyRequest(String buddyEmail) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return 'Not authenticated';

      final buddyUserResponse = await _supabase
          .from('users')
          .select()
          .eq('email', buddyEmail.toLowerCase())
          .maybeSingle();

      if (buddyUserResponse == null) return 'User not found';

      final buddyId = buddyUserResponse['id'];
      if (buddyUserResponse['role'] != 'student') return 'Buddy system is only available for students';
      if (buddyId == currentUser.id) return 'Cannot add yourself as a buddy';

      final existing = await _supabase
          .from('buddy_connections')
          .select()
          .or('user_id.eq.${currentUser.id},buddy_id.eq.${currentUser.id}')
          .or('user_id.eq.$buddyId,buddy_id.eq.$buddyId');

      if ((existing as List).isNotEmpty) return 'Buddy connection already exists';

      await _supabase
          .from('buddy_connections')
          .insert({'user_id': currentUser.id, 'buddy_id': buddyId, 'status': 'pending'});

      return null;
    } catch (e) {
      if (e.toString().contains('duplicate')) return 'Buddy connection already exists';
      return e.toString();
    }
  }

  Future<bool> acceptBuddyRequest(String connectionId) async {
    try {
      await _supabase
          .from('buddy_connections')
          .update({'status': 'accepted', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', connectionId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectBuddyRequest(String connectionId) async {
    try {
      await _supabase
          .from('buddy_connections')
          .update({'status': 'rejected', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', connectionId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeBuddy(String connectionId) async {
    try {
      await _supabase.from('buddy_connections').delete().eq('id', connectionId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<models.User>> searchUsers(String query) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      final response = await _supabase
          .from('users')
          .select()
          .or('email.ilike.%$query%,student_id.ilike.%$query%')
          .eq('role', 'student')
          .neq('id', currentUser.id)
          .limit(10);

      return (response as List).map((user) => models.User.fromJson(user)).toList();
    } catch (e) {
      return [];
    }
  }
}
