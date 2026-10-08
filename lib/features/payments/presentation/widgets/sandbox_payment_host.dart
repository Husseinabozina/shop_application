import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/sandbox_payment_controller.dart';

/// Recovery stays available on every route, including an app restart on Home.
class SandboxPaymentHost extends StatefulWidget {
  const SandboxPaymentHost({super.key, required this.child});
  final Widget child;
  @override
  State<SandboxPaymentHost> createState() => _SandboxPaymentHostState();
}

class _SandboxPaymentHostState extends State<SandboxPaymentHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      context.read<SandboxPaymentController>().check();
  }

  @override
  Widget build(BuildContext context) {
    final payment = context.watch<SandboxPaymentController>();
    if (!payment.hasNotice) return widget.child;
    final theme = Theme.of(context);
    return Column(
      children: [
        Material(
          color: theme.colorScheme.primaryContainer,
          child: SafeArea(
            bottom: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .38,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.credit_card_outlined, size: 21),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'MyFatoorah Sandbox • 1 KWD',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (payment.isBusy)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      payment.message ?? 'An unfinished test payment is saved for this account.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (payment.attempt != null) ...[
                          TextButton(
                            onPressed: payment.isBusy ? null : payment.open,
                            child: const Text('Open test payment'),
                          ),
                          TextButton(
                            onPressed: payment.isBusy ? null : payment.check,
                            child: const Text('Check payment result'),
                          ),
                        ] else if (!payment.isBusy)
                          TextButton(
                            onPressed: payment.dismissNotice,
                            child: const Text('Done'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
