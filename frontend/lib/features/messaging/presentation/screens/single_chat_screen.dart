import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/chat_conversation_model.dart';
import '../../data/models/message_model.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/date_separator.dart';
import '../widgets/message_bubble.dart';

class SingleChatScreen extends StatefulWidget {
  final ChatConversationModel conversation;

  const SingleChatScreen({super.key, required this.conversation});

  @override
  State<SingleChatScreen> createState() => _SingleChatScreenState();
}

class _SingleChatScreenState extends State<SingleChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  // TODO: Replace with real current user ID from auth state
  static const _currentUserId = 'current-user';

  // TODO: Replace with real messages from backend / viewmodel
  late final List<MessageModel> _messages = [
    MessageModel(
      id: '1',
      senderId: _currentUserId,
      text: 'I am so ready. I think they do a new',
      createdAt: DateTime.now().subtract(const Duration(days: 5, hours: 2)),
    ),
    MessageModel(
      id: '2',
      senderId: _currentUserId,
      text: 'they do a new',
      createdAt: DateTime.now().subtract(const Duration(days: 5, hours: 1)),
    ),
    MessageModel(
      id: '3',
      senderId: widget.conversation.participantId,
      text: 'Are we still',
      createdAt: DateTime.now().subtract(const Duration(days: 5, minutes: 30)),
    ),
    MessageModel(
      id: '4',
      senderId: widget.conversation.participantId,
      text: 'Are we still going to the Zodac meeting',
      createdAt: DateTime.now().subtract(const Duration(days: 5, minutes: 29)),
    ),
    MessageModel(
      id: '5',
      senderId: widget.conversation.participantId,
      text: 'Are we still going to the Zodac meeting tomorrow?',
      createdAt: DateTime.now().subtract(const Duration(days: 5, minutes: 28)),
    ),
    MessageModel(
      id: '6',
      senderId: _currentUserId,
      text: 'okay',
      createdAt: DateTime.now().subtract(const Duration(days: 5, minutes: 20)),
    ),
    MessageModel(
      id: '7',
      senderId: widget.conversation.participantId,
      text: 'Are we still going to the Zodac meeting tomorrow?',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    MessageModel(
      id: '8',
      senderId: _currentUserId,
      text: 'Yeah! I am so ready. I think they do a great stout.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId,
        text: text,
        createdAt: DateTime.now(),
      ));
    });
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            ChatAppBar(conversation: widget.conversation),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _buildMessageWidgets(),
              ),
            ),
            ChatInputField(
              controller: _messageController,
              onSend: _handleSend,
            ),
          ],
        ),
      ),
    );
  }

  // ── Message grouping logic ───────────────────────────────

  List<Widget> _buildMessageWidgets() {
    final widgets = <Widget>[];

    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      final prevMsg = i > 0 ? _messages[i - 1] : null;
      final nextMsg = i < _messages.length - 1 ? _messages[i + 1] : null;

      // Insert date separator when the date changes
      if (prevMsg == null || !_isSameDay(prevMsg.createdAt, msg.createdAt)) {
        if (i > 0) widgets.add(const SizedBox(height: 24));
        widgets.add(DateSeparator(dateText: _formatDateLabel(msg.createdAt)));
        widgets.add(const SizedBox(height: 16));
      }

      final isSent = msg.senderId == _currentUserId;

      // Spacing between sender groups on the same day
      final sameDayAsPrev =
          prevMsg != null && _isSameDay(prevMsg.createdAt, msg.createdAt);
      if (sameDayAsPrev && prevMsg.senderId != msg.senderId) {
        widgets.add(const SizedBox(height: 24));
      }

      // Corner-rounding flags for consecutive same-sender bubbles
      final isFirstInGroup = prevMsg == null ||
          prevMsg.senderId != msg.senderId ||
          !_isSameDay(prevMsg.createdAt, msg.createdAt);
      final isLastInGroup = nextMsg == null ||
          nextMsg.senderId != msg.senderId ||
          !_isSameDay(nextMsg.createdAt, msg.createdAt);

      widgets.add(MessageBubble(
        text: msg.text,
        isSent: isSent,
        isFirst: isFirstInGroup,
        isLast: isLastInGroup,
      ));
    }

    widgets.add(const SizedBox(height: 16));
    return widgets;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) return AppStrings.messaging.todayLabel;
    if (messageDate == today.subtract(const Duration(days: 1))) {
      return AppStrings.messaging.yesterdayLabel;
    }
    return AppStrings.messaging.lastWeekLabel;
  }
}
