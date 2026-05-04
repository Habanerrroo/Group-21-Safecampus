import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<List<EmergencyContact>> getEmergencyContacts() async {
    try {
      final response = await _supabase
          .from('emergency_contacts')
          .select()
          .eq('is_active', true)
          .order('priority', ascending: false);

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
      return [];
    }
  }
}
