import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/repositories/messaging_repository.dart';
import '../viewmodels/chats_list_viewmodel.dart';
import '../widgets/chat_tile.dart';

class ChatsListScreen extends StatefulWidget {
  static final _key = GlobalKey<_ChatsListScreenState>();

  ChatsListScreen() : super(key: _key);

  /// Called by [MainLayoutScreen] whenever the inbox tab is selected so
  /// the list refreshes when the user arrives from another tab or screen.
  static void refresh() => _key.currentState?._refresh();

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  late final ChatsListViewmodel _viewmodel;

  void _refresh() => _viewmodel.loadConversations();

  @override
  void initState() {
    super.initState();
    final repository = context.read<MessagingRepository>();
    final currentUserId =
        context.read<StorageService>().getUserId() ?? '';

    _viewmodel = ChatsListViewmodel(repository, currentUserId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewmodel.loadConversations();
    });
    _viewmodel.subscribeToInboxUpdates();
  }

  @override
  void dispose() {
    _viewmodel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewmodel,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.messaging.chatsTitle,
                        style: AppTextStyles.heading2.copyWith(fontSize: 28),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.cardFront,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: HugeIcon(
                          icon: AppAssets.icon.notification,
                          color: AppColors.textWhite,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: AppSearchBar(
                    hintText: AppStrings.messaging.searchChatHint,
                    borderWidth: 0,
                  ),
                ),
                const SizedBox(height: 24),

                // Reconnecting banner
                if (_viewmodel.isReconnecting)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    color: AppColors.outline,
                    child: Text(
                      'Reconnecting…',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                // Conversations Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    AppStrings.messaging.conversationsSection,
                    style: AppTextStyles.bodySecondary.copyWith(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // List of conversations
                Expanded(
                  child: _buildBody(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_viewmodel.isLoading && _viewmodel.conversations.isEmpty) {
      return const _ChatsListShimmer();
    }

    if (_viewmodel.error != null && _viewmodel.conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _viewmodel.error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ),
      );
    }

    if (_viewmodel.conversations.isEmpty) {
      return Center(
        child: Text(
          AppStrings.messaging.noChatHistory,
          style: AppTextStyles.bodySecondary,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      itemCount: _viewmodel.conversations.length,
      itemBuilder: (context, index) {
        final conversation = _viewmodel.conversations[index];
        return Dismissible(
          key: Key(conversation.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => AppConfirmDialog.show(
            context,
            title: AppStrings.messaging.deleteConversationTitle,
            message: AppStrings.messaging.deleteConversationMessage,
            confirmLabel: AppStrings.messaging.deleteMessageAction,
            isDanger: true,
          ),
          onDismissed: (_) async {
            final ok = await _viewmodel.deleteConversation(conversation.id);
            if (!ok && mounted) {
              AppSnackbar.error('Could not delete conversation. Please try again.');
            }
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.delete_outline, color: AppColors.textWhite, size: 24),
          ),
          child: ChatTile(
            conversation: conversation,
            onReturn: () => _viewmodel.loadConversations(),
          ),
        );
      },
    );
  }
}

class _ChatsListShimmer extends StatelessWidget {
  const _ChatsListShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 7,
        itemBuilder: (_, _) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardFront,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const ShimmerCircle(size: 50),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 120, height: 14, radius: 6),
                    SizedBox(height: 6),
                    ShimmerBox(height: 12, radius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const ShimmerBox(width: 36, height: 11, radius: 6),
            ],
          ),
        ),
      ),
    );
  }
}
