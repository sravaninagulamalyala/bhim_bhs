import 'package:flutter/material.dart';

import '../widgets/ambedkar_loading_dialog.dart';

class LoadingHelper {
  static bool _showing = false;

  static void show(BuildContext context) {
    if (_showing || !context.mounted) return;
    _showing = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const AmbedkarLoadingDialog(),
    ).whenComplete(() => _showing = false);
  }

  static void hide(BuildContext context) {
    if (!_showing || !context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    _showing = false;
  }
}
