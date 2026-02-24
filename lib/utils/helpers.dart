import 'package:intl/intl.dart';

class Helpers {
  // Format timestamp to relative time (e.g., "5 minutes ago")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  // Format date and time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
  }

  // Format time only
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  // Format date only
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMMM d, yyyy').format(dateTime);
  }

  // Calculate distance between two points (simplified)
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} m away';
    } else {
      return '${distanceInKm.toStringAsFixed(1)} km away';
    }
  }

  // Validate email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Validate phone number (Nigerian format)
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^(\+234|0)[7-9][0-1]\d{8}$');
    return phoneRegex.hasMatch(phone);
  }

  // Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Get initials from name
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  // Generate random ID (for demo purposes)
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Check if string is empty or null
  static bool isEmpty(String? text) {
    return text == null || text.trim().isEmpty;
  }

  // Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Format incident ID
  static String formatIncidentId(String id) {
    return id.toUpperCase();
  }

  // Get severity level text
  static String getSeverityText(String severity) {
    return severity.toUpperCase();
  }

  // Calculate ETA in minutes
  static String formatETA(int minutes) {
    if (minutes < 1) return 'Arriving now';
    if (minutes == 1) return '1 min';
    return '$minutes min';
  }

  // Format percentage
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(0)}%';
  }

  // Format large numbers (e.g., 1000 -> 1K)
  static String formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}K';
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }
}

