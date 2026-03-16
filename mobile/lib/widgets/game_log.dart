import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_log_provider.dart';

/// Scrolling list of game events. Auto-scrolls to latest entry.
class GameLogWidget extends ConsumerStatefulWidget {
  const GameLogWidget({super.key});

  @override
  ConsumerState<GameLogWidget> createState() => _GameLogWidgetState();
}

class _GameLogWidgetState extends ConsumerState<GameLogWidget> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
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

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(gameLogProvider);

    // Auto-scroll when new entry added
    ref.listen(gameLogProvider, (prev, next) {
      if (next.length > (prev?.length ?? 0)) _scrollToBottom();
    });

    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'No events yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final entry = entries[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Text(
            entry.message,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      },
    );
  }
}
