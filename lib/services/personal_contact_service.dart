import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

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

  // Get all personal contacts for a user
  Future<List<PersonalContact>> getUserContacts(String userId) async {
    developer.log('📇 FETCHING PERSONAL CONTACTS', name: 'PersonalContactService');
    developer.log('👤 User ID: $userId', name: 'PersonalContactService');

    try {
      final response = await _supabase
          .from('personal_contacts')
          .select()
          .eq('user_id', userId)
          .order('is_primary', ascending: false)
          .order('created_at', ascending: false);

      developer.log('✅ Fetched ${response.length} contacts', name: 'PersonalContactService');

      return (response as List).map((contact) {
        return PersonalContact.fromJson(contact);
      }).toList();
    } catch (e) {
      developer.log('❌ Error fetching contacts: $e', name: 'PersonalContactService');
      return [];
    }
  }

  // Add a new personal contact
  Future<String?> addContact({
    required String userId,
    required String name,
    required String phone,
    String? relationship,
    bool isPrimary = false,
  }) async {
    developer.log('➕ ADDING PERSONAL CONTACT', name: 'PersonalContactService');
    developer.log('👤 User ID: $userId', name: 'PersonalContactService');
    developer.log('📇 Name: $name', name: 'PersonalContactService');
    developer.log('📞 Phone: $phone', name: 'PersonalContactService');

    try {
      // If this is set as primary, unset other primary contacts
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

      final contactId = response['id'];
      developer.log('✅ Contact added with ID: $contactId', name: 'PersonalContactService');
      return contactId;
    } catch (e) {
      developer.log('❌ Error adding contact: $e', name: 'PersonalContactService');
      return null;
    }
  }

  // Update a personal contact
  Future<bool> updateContact({
    required String contactId,
    String? name,
    String? phone,
    String? relationship,
    bool? isPrimary,
  }) async {
    developer.log('✏️ UPDATING PERSONAL CONTACT', name: 'PersonalContactService');
    developer.log('🆔 Contact ID: $contactId', name: 'PersonalContactService');

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (relationship != null) updates['relationship'] = relationship;
      if (isPrimary != null) {
        updates['is_primary'] = isPrimary;
        
        // If setting as primary, unset other primary contacts
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

      await _supabase
          .from('personal_contacts')
          .update(updates)
          .eq('id', contactId);

      developer.log('✅ Contact updated successfully', name: 'PersonalContactService');
      return true;
    } catch (e) {
      developer.log('❌ Error updating contact: $e', name: 'PersonalContactService');
      return false;
    }
  }

  // Delete a personal contact
  Future<bool> deleteContact(String contactId) async {
    developer.log('🗑️ DELETING PERSONAL CONTACT', name: 'PersonalContactService');
    developer.log('🆔 Contact ID: $contactId', name: 'PersonalContactService');

    try {
      await _supabase
          .from('personal_contacts')
          .delete()
          .eq('id', contactId);

      developer.log('✅ Contact deleted successfully', name: 'PersonalContactService');
      return true;
    } catch (e) {
      developer.log('❌ Error deleting contact: $e', name: 'PersonalContactService');
      return false;
    }
  }

  // Get primary contact
  Future<PersonalContact?> getPrimaryContact(String userId) async {
    developer.log('⭐ FETCHING PRIMARY CONTACT', name: 'PersonalContactService');

    try {
      final response = await _supabase
          .from('personal_contacts')
          .select()
          .eq('user_id', userId)
          .eq('is_primary', true)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        developer.log('ℹ️ No primary contact found', name: 'PersonalContactService');
        return null;
      }

      return PersonalContact.fromJson(response);
    } catch (e) {
      developer.log('❌ Error fetching primary contact: $e', name: 'PersonalContactService');
      return null;
    }
  }
}


