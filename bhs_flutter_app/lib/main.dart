import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/storage/auth_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authStore = AuthStore();
  await authStore.load();
  runApp(
    ChangeNotifierProvider.value(
      value: authStore,
      child: const BhsApp(),
    ),
  );
}
