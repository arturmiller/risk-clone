import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'elements/generic.dart';
import 'hud_loader.dart';
import 'models.dart';

class HudRenderer extends ConsumerWidget {
  const HudRenderer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(hudConfigProvider);
    return async.when(
      data: (config) => _HudRootLayout(config: config),
      loading: () => const SizedBox(),
      error: (e, st) => _HudErrorWidget(error: e),
    );
  }
}

class _HudRootLayout extends StatelessWidget {
  final HudConfig config;
  const _HudRootLayout({required this.config});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final key = width < 900 ? 'mobile-landscape' : 'desktop-landscape';
    final layout = config.layouts[key] ?? config.layouts.values.first;
    return IgnorePointer(
      ignoring: false,
      child: renderElement(layout.root, config.theme),
    );
  }
}

class _HudErrorWidget extends StatelessWidget {
  final Object error;
  const _HudErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'HUD failed to load\n\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red, fontSize: 14),
        ),
      ),
    );
  }
}
