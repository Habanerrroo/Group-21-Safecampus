import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/message.dart';

class TeamChat extends StatefulWidget {
  const TeamChat({super.key});

  @override
  State<TeamChat> createState() => _TeamChatState();
}

class _TeamChatState extends State<TeamChat> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  
  final List<ChatChannel> _channels = [
    ChatChannel(
      id: 'general',
      name: 'General',
      description: 'Team-wide announcements and updates',
      type: ChannelType.general,
      memberIds: ['1', '2', '3', '4', '5'],
      lastMessage: 'Shift change at 6 PM',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 15)),
      unreadCount: 2,
      icon: '📢',
    ),
    ChatChannel(
      id: 'emergency',
      name: 'Emergency',
      description: 'Critical incidents only',
      type: ChannelType.emergency,
      memberIds: ['1', '2', '3'],
      lastMessage: 'Medical emergency cleared',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
      unreadCount: 0,
      icon: '🚨',
    ),
    ChatChannel(
      id: 'night-shift',
      name: 'Night Shift',
      description: 'Night shift team coordination',
      type: ChannelType.shift,
      memberIds: ['1', '3', '5'],
      lastMessage: 'All quiet on north campus',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      unreadCount: 5,
      icon: '🌙',
    ),
  ];

  ChatChannel? _selectedChannel;
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedChannel = _channels[0];
    _loadMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    // Mock messages
    _messages = [
      ChatMessage(
        id: '1',
        senderId: '2',
        senderName: 'Officer Williams',
        content: 'All clear on the east side',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: true,
      ),
      ChatMessage(
        id: '2',
        senderId: '1',
        senderName: 'Me',
        content: 'Copy that, heading to library now',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        isRead: true,
      ),
      ChatMessage(
        id: '3',
        senderId: '3',
        senderName: 'Officer Lee',
        content: 'Need backup at student center',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        isRead: true,
      ),
      ChatMessage(
        id: '4',
        senderId: '1',
        senderName: 'Me',
        content: 'On my way',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
        isRead: true,
      ),
    ];
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: '1',
          senderName: 'Me',
          content: _messageController.text,
          type: MessageType.text,
          timestamp: DateTime.now(),
          isRead: false,
        ),
      );
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Team Chat',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.foregroundLight,
          tabs: const [
            Tab(text: 'Channels'),
            Tab(text: 'Direct'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChannelsView(),
          _buildDirectMessagesView(),
        ],
      ),
    );
  }

  Widget _buildChannelsView() {
    return Row(
      children: [
        // Channel list
        Container(
          width: 120,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(right: BorderSide(color: AppColors.border)),
          ),
          child: ListView.builder(
            itemCount: _channels.length,
            itemBuilder: (context, index) {
              final channel = _channels[index];
              final isSelected = _selectedChannel?.id == channel.id;
              
              return Material(
                color: isSelected ? AppColors.primaryLighter : Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedChannel = channel;
                      _loadMessages();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _getChannelColor(channel.type).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  channel.icon ?? '#',
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            if (channel.unreadCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.critical,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Center(
                                    child: Text(
                                      channel.unreadCount > 9 ? '9+' : channel.unreadCount.toString(),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          channel.name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? Colors.white : AppColors.foregroundLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Chat area
        Expanded(
          child: _selectedChannel == null
              ? _buildEmptyState()
              : _buildChatArea(),
        ),
      ],
    );
  }

  Widget _buildChatArea() {
    return Column(
      children: [
        // Channel header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Text(
                _selectedChannel!.icon ?? '#',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedChannel!.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_selectedChannel!.memberIds.length} members',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.foregroundLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.info_outline, color: AppColors.foregroundLight),
              ),
            ],
          ),
        ),
        
        // Messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isMe = message.senderId == '1';
              
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 12),
                          child: Text(
                            message.senderName,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foregroundLight,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.secondary : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message.content,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isMe ? AppColors.primary : Colors.white,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                        child: Text(
                          _formatTime(message.timestamp),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.foregroundLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Input area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.add_circle_outline, color: AppColors.secondary),
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: GoogleFonts.inter(color: AppColors.foregroundLight),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: GoogleFonts.inter(color: Colors.white),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send, color: AppColors.secondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDirectMessagesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.foregroundLight),
          const SizedBox(height: 16),
          Text(
            'Direct Messages',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.foregroundLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Select a channel',
        style: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.foregroundLight,
        ),
      ),
    );
  }

  Color _getChannelColor(ChannelType type) {
    switch (type) {
      case ChannelType.general:
        return AppColors.secondary;
      case ChannelType.emergency:
        return AppColors.critical;
      case ChannelType.shift:
        return AppColors.warning;
      case ChannelType.incident:
        return AppColors.accent;
      case ChannelType.direct:
        return AppColors.info;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

