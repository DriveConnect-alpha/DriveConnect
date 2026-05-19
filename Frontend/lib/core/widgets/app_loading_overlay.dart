import 'package:flutter/material.dart';
import '../loading/app_loading.dart';
import 'dc_loading.dart';

class AppLoadingOverlay extends StatelessWidget {
  final Widget child;

  const AppLoadingOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLoading.controller,
      builder: (context, _) {
        final isLoading = AppLoading.controller.isLoading;
        final message = AppLoading.controller.message;

        if (!isLoading) return child;

        return Stack(
          children: [
            child,
            const Positioned.fill(
              child: ModalBarrier(dismissible: false, color: Colors.black54),
            ),
            Positioned.fill(
              child: DCLoading(message: message ?? 'Carregando...'),
            ),
          ],
        );
      },
    );
  }
}
