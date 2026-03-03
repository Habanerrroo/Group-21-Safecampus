class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.attachmentUrl,
  });
}

enum MessageType {
  text,
  image,
  location,
  voice,
  incident,
}

class ChatChannel {
  final String id;
  final String name;
  final String description;
  final ChannelType type;
  final List<String> memberIds;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String? icon;

  ChatChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.memberIds,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.icon,
  });
}

enum ChannelType {
  general,
  emergency,
  shift,
  incident,
  direct,
}

