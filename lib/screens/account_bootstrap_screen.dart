import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../widgets/action_button.dart';
import '../widgets/screen_frame.dart';

class AccountBootstrapScreen extends StatelessWidget {
  const AccountBootstrapScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ScreenFrame(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Setting up account',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (controller.busy) ...[
                        const SizedBox(height: 18),
                        const LinearProgressIndicator(),
                      ],
                      if (controller.statusMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          controller.statusMessage!,
                          style: TextStyle(color: colorScheme.error),
                        ),
                        const SizedBox(height: 18),
                        ActionButton(
                          icon: Icons.refresh,
                          label: 'Try again',
                          onPressed: controller.busy
                              ? null
                              : controller.ensureAutomaticAccount,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
