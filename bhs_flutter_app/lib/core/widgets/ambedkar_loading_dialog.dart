import 'dart:async';

import 'package:flutter/material.dart';

import 'ambedkar_image.dart';

class AmbedkarLoadingDialog extends StatefulWidget {
  const AmbedkarLoadingDialog({super.key});

  @override
  State<AmbedkarLoadingDialog> createState() => _AmbedkarLoadingDialogState();
}

class _AmbedkarLoadingDialogState extends State<AmbedkarLoadingDialog> {
  int dots = 1;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (mounted) setState(() => dots = dots == 3 ? 1 : dots + 1);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: bg,
        surfaceTintColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AmbedkarImage(size: 112, showShadow: true),
              const SizedBox(height: 18),
              Text(
                'Loading${'.' * dots}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
