import 'package:supabase_flutter/supabase_flutter.dart';

class PersonalContact {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? relationship;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;

  PersonalContact({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.relationship,
    this.isPrimary = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PersonalContact.fromJson(Map<String, dynamic> json) {
    return PersonalContact(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      phone: json['phone'],
      relationship: json['relationship'],
      isPrimary: json['is_primary'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'is_primary': isPrimary,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class PersonalContactService {
  final _supabase = Supabase.instance.client;

  Future<List<PersonalContact>> getUserContacts(String userId) async {
    try {
      final response = await _supabase
          .from('personal_contacts')
          .select()
          .eq('user_id', userId)
          .order('is_primary', ascending: false)
          .order('created_at', ascending: false);

      return (response as List).map((contact) => PersonalContact.fromJson(contact)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String?> addContact({
    required String userId,
    required String name,
    required String phone,
    String? relationship,
    bool isPrimary = false,
  }) async {
    try {
      if (isPrimary) {
        await _supabase
            .from('personal_contacts')
            .update({'is_primary': false})
            .eq('user_id', userId)
            .eq('is_primary', true);
      }

      final response = await _supabase
          .from('personal_contacts')
          .insert({
        'user_id': userId,
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'is_primary': isPrimary,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .select('id')
          .single();

      return response['id'];
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateContact({
    required String contactId,
    String? name,
    String? phone,
    String? relationship,
    bool? isPrimary,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (relationship != null) updates['relationship'] = relationship;
      if (isPrimary != null) {
        updates['is_primary'] = isPrimary;
        if (isPrimary) {
          final contact = await _supabase
              .from('personal_contacts')
              .select('user_id')
              .eq('id', contactId)
              .single();
          await _supabase
              .from('personal_contacts')
              .update({'is_primary': false})
              .eq('user_id', contact['user_id'])
              .eq('is_primary', true)
              .neq('id', contactId);
        }
      }
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('personal_contacts').update(updates).eq('id', contactId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteContact(String contactId) async {
    try {
      await _supabase.from('personal_contacts').delete().eq('id', contactId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<PersonalContact?> getPrimaryContact(String userId) async {
    try {
      final response = await _supabase
          .from('personal_contacts')
          .select()
          .eq('user_id', userId)
          .eq('is_primary', true)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return PersonalContact.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}

