import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/storage/auth_store.dart';
import '../../core/widgets/common_widgets.dart';
import '../home/home_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    return AppScaffold(
      title: 'Profile / Logout',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(auth.staffName?.isNotEmpty == true ? auth.staffName! : auth.adminId ?? 'Logged-in user'),
            subtitle: Text('Role: ${auth.role ?? '-'}'),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () async {
            await auth.logout();
            if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
          },
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
        ),
      ]),
    );
  }
}
