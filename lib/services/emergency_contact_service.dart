import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String type;
  final String? description;
  final int priority;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    this.description,
    required this.priority,
  });
}

class EmergencyContactService {
  final _supabase = Supabase.instance.client;

  // Get all active emergency contacts
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    developer.log('📞 FETCHING EMERGENCY CONTACTS', name: 'EmergencyContactService');

    try {
      final response = await _supabase
          .from('emergency_contacts')
          .select()
          .eq('is_active', true)
          .order('priority', ascending: false);

      developer.log('✅ Fetched ${response.length} contacts', name: 'EmergencyContactService');

      return (response as List).map((contact) {
        return EmergencyContact(
          id: contact['id'],
          name: contact['name'],
          phone: contact['phone'],
          type: contact['type'],
          description: contact['description'],
          priority: contact['priority'] ?? 0,
        );
      }).toList();
    } catch (e) {
      developer.log('❌ Error fetching emergency contacts: $e', name: 'EmergencyContactService');
      return [];
    }
  }
}

