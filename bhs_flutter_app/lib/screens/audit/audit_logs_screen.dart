import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_store.dart';
import '../../core/widgets/common_widgets.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  List rows = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await ApiClient(context.read<AuthStore>()).get('/admin/audit-logs');
      setState(() => rows = data is List ? data : []);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Audit Logs',
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [const Expanded(child: Text('Latest 100 actions')), FilledButton(onPressed: _load, child: const Text('Refresh'))]),
            ),
            if (loading) const LinearProgressIndicator(),
            Expanded(
              child: rows.isEmpty
                  ? const EmptyView('No audit logs found')
                  : ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (_, i) {
                        final row = rows[i];
                        return ListTile(
                          title: Text('${row['action'] ?? ''} • ${row['moduleName'] ?? ''}'),
                          subtitle: Text('${row['performedBy'] ?? ''} • ${row['role'] ?? ''}\n${row['description'] ?? ''}'),
                          isThreeLine: true,
                          trailing: Text('${row['createdAt'] ?? ''}'.split('.').first),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
}
