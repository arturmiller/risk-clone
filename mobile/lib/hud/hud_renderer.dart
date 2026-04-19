import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'elements/generic.dart';
import 'hud_loader.dart';
import 'models.dart';

const double _mobileLandscapeMaxWidth = 900.0;

class HudRenderer extends ConsumerWidget {
  const HudRenderer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(hudConfigProvider);
    return async.when(
      data: (config) => _HudRootLayout(config: config),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Loading HUD\u2026',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ),
      ),
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
    final key = width < _mobileLandscapeMaxWidth ? 'mobile-landscape' : 'desktop-landscape';
    final layout = config.layouts[key] ??
        (config.layouts.isEmpty ? null : config.layouts.values.first);
    if (layout == null) {
      return const _HudErrorWidget(
        error: 'No layouts defined in hud.json',
      );
    }
    return renderElement(layout.root, config.theme);
  }
}

class _HudErrorWidget extends StatelessWidget {
  final Object error;
  const _HudErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('[hud] Render failed: $error');
    }
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'HUD failed to load.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red, fontSize: 14),
        ),
      ),
    );
  }
}
