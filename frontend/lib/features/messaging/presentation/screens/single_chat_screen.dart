import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../data/models/chat_conversation_model.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/messaging_repository.dart';
import '../viewmodels/single_chat_viewmodel.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/date_separator.dart';
import '../widgets/message_bubble.dart';

class SingleChatScreen extends StatefulWidget {
  final ChatConversationModel conversation;

  /// When provided, the screen resolves the conversation ID via
  /// [startConversation] before loading messages. Navigation happens
  /// immediately so the header shows the participant info right away.
  final String? recipientId;

  /// Pre-fills the message input on open (e.g. from a collab post CTA).
  final String? initialMessage;

  /// When set, shows a dismissable collab quote block above the input.
  final String? collabTitle;
  final String? collabCreator;

  const SingleChatScreen({
    super.key,
    required this.conversation,
    this.recipientId,
    this.initialMessage,
    this.collabTitle,
    this.collabCreator,
  });

  @override
  State<SingleChatScreen> createState() => _SingleChatScreenState();
}

class _SingleChatScreenState extends State<SingleChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  SingleChatViewmodel? _viewmodel;
  late final String _currentUserId;
  bool _isInitializing = false;
  int _lastMessageCount = 0;
  bool _showQuoteBlock = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<StorageService>().getUserId() ?? '';
    _scrollController.addListener(_onScroll);
    if (widget.initialMessage != null) {
      _messageController.text = widget.initialMessage!;
    }
    _showQuoteBlock = widget.collabTitle != null;

    if (widget.recipientId != null) {
      // Navigate was instant — resolve conversation ID in the background.
      setState(() => _isInitializing = true);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _resolveAndStart(widget.recipientId!),
      );
    } else {
      _startChat(widget.conversation.id);
    }
  }

  @override
  void dispose() {
    _viewmodel?.removeListener(_onViewmodelChange);
    _viewmodel?.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Initialisation ─────────────────────────────────────

  Future<void> _resolveAndStart(String recipientId) async {
    try {
      final repo = context.read<MessagingRepository>();
      final conversation = await repo.startConversation(recipientId);
      if (!mounted) return;
      _startChat(conversation.id);
      setState(() => _isInitializing = false);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error('Could not open conversation. Please try again.');
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _startChat(String conversationId) {
    _viewmodel = SingleChatViewmodel(
      repository: context.read<MessagingRepository>(),
      conversationId: conversationId,
      currentUserId: _currentUserId,
    );
    _viewmodel!.subscribeToMessages();
    _viewmodel!.addListener(_onViewmodelChange);
    _viewmodel!.loadMessages().then((_) {
      if (mounted) _viewmodel?.markAsRead();
    });
  }

  // ── Listeners ──────────────────────────────────────────

  void _onViewmodelChange() {
    final vm = _viewmodel;
    if (vm == null) return;

    // Only scroll to bottom when a new message is added — not on deletes,
    // mark-read, or other state changes that shouldn't move the viewport.
    final currentCount = vm.messages.length;
    final newMessageArrived = currentCount > _lastMessageCount;
    _lastMessageCount = currentCount;

    if (newMessageArrived && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 80) {
      _viewmodel?.loadMore();
    }
  }

  void _showDeleteSheet(String messageId) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.cardFront,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text(
                AppStrings.messaging.deleteMessageAction,
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _viewmodel?.deleteMessage(messageId);
                AppSnackbar.withUndo(
                  message: AppStrings.messaging.deleteMessageUndo,
                  onUndo: () => _viewmodel?.undoDeleteMessage(messageId),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.close, color: AppColors.textSecondary),
              title: Text(AppStrings.messaging.cancelAction, style: TextStyle(color: AppColors.textSecondary)),
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    if (_showQuoteBlock) setState(() => _showQuoteBlock = false);
    _viewmodel?.sendMessage(text);
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Header always visible immediately — uses profile data from widget.conversation
            ChatAppBar(conversation: widget.conversation),

            if (_isInitializing || _viewmodel == null)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: ListenableBuilder(
                  listenable: _viewmodel!,
                  builder: (context, _) {
                    return Column(
                      children: [
                        if (_viewmodel!.isReconnecting)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            color: AppColors.outline,
                            child: Text(
                              'Reconnecting…',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Expanded(child: _buildMessageList()),
                        if (_showQuoteBlock && widget.collabTitle != null)
                          _CollabQuoteBlock(
                            collabTitle: widget.collabTitle!,
                            collabCreator: widget.collabCreator,
                            onDismiss: () => setState(() => _showQuoteBlock = false),
                          ),
                        ChatInputField(
                          controller: _messageController,
                          onSend: _handleSend,
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    final vm = _viewmodel!;
    if (vm.isLoading && vm.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.error != null && vm.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            vm.error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: _buildMessageWidgets(vm.messages),
    );
  }

  // ── Message grouping ───────────────────────────────────

  List<Widget> _buildMessageWidgets(List<MessageModel> messages) {
    final widgets = <Widget>[];

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final prevMsg = i > 0 ? messages[i - 1] : null;
      final nextMsg = i < messages.length - 1 ? messages[i + 1] : null;

      if (prevMsg == null || !_isSameDay(prevMsg.createdAt, msg.createdAt)) {
        if (i > 0) widgets.add(const SizedBox(height: 24));
        widgets.add(DateSeparator(dateText: _formatDateLabel(msg.createdAt)));
        widgets.add(const SizedBox(height: 16));
      }

      final isSent = msg.senderId == _currentUserId;

      final sameDayAsPrev =
          prevMsg != null && _isSameDay(prevMsg.createdAt, msg.createdAt);
      if (sameDayAsPrev && prevMsg.senderId != msg.senderId) {
        widgets.add(const SizedBox(height: 24));
      }

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
        isDeleted: msg.isDeleted,
        onLongPress: () => _showDeleteSheet(msg.id),
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

class _CollabQuoteBlock extends StatelessWidget {
  final String collabTitle;
  final String? collabCreator;
  final VoidCallback onDismiss;

  const _CollabQuoteBlock({
    required this.collabTitle,
    this.collabCreator,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.25)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Green left accent bar
            Container(
              width: 3,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collabCreator != null ? '@$collabCreator\'s collab' : 'Collab post',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      collabTitle,
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
