import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_store.dart';
import '../../core/widgets/common_widgets.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final search = TextEditingController();
  final adminId = TextEditingController();
  final password = TextEditingController();
  List members = [];
  List staff = [];
  Map<String, dynamic>? selectedMember;
  int? selectedMemberId;
  String role = 'STAFF';
  bool active = true;
  bool loading = false;
  bool searchingMembers = false;
  bool loadingStaff = false;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  ApiClient get api => ApiClient(context.read<AuthStore>());

  Future<void> _memberSearch() async {
    setState(() => searchingMembers = true);
    try {
      final data = await api.get('/members/search', query: {'keyword': search.text.trim()});
      setState(() {
        members = data is List ? data : [];
        if (selectedMemberId != null && !members.any((m) => _id(m) == selectedMemberId)) {
          selectedMember = null;
          selectedMemberId = null;
        }
      });
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) setState(() => searchingMembers = false);
    }
  }

  Future<void> _loadStaff() async {
    setState(() => loadingStaff = true);
    try {
      final data = await api.get('/admin/staff');
      setState(() => staff = data is List ? data : []);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) setState(() => loadingStaff = false);
    }
  }

  Future<void> _create() async {
    if (adminId.text.trim().isEmpty || password.text.isEmpty) {
      showSnack(context, 'Admin ID and password are required');
      return;
    }
    setState(() => loading = true);
    try {
      await api.post('/admin/staff/create', body: {
        'memberId': selectedMemberId,
        'adminId': adminId.text.trim(),
        'password': password.text,
        'role': role,
        'active': active,
      });
      adminId.clear();
      password.clear();
      selectedMember = null;
      selectedMemberId = null;
      await _loadStaff();
      if (mounted) showSnack(context, 'Staff created');
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Staff Management',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(child: TextField(controller: search, decoration: const InputDecoration(labelText: 'Search member by name/mobile'))),
          IconButton.filled(onPressed: searchingMembers ? null : _memberSearch, icon: searchingMembers ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search)),
        ]),
        if (searchingMembers) const LinearProgressIndicator(),
        for (final m in members.take(5))
          if (_id(m) != null)
          RadioListTile<int>(
            value: _id(m)!,
            groupValue: selectedMemberId,
            title: Text('${m['fullName'] ?? ''}'),
            subtitle: Text('ID: ${m['id']} • ${m['mobileNo'] ?? ''}'),
            onChanged: (v) => setState(() {
              selectedMemberId = v;
              selectedMember = Map<String, dynamic>.from(m);
            }),
          ),
        const SizedBox(height: 12),
        TextFormField(readOnly: true, decoration: InputDecoration(labelText: 'Member ID', hintText: '${selectedMemberId ?? ''}')),
        const SizedBox(height: 10),
        TextFormField(readOnly: true, decoration: InputDecoration(labelText: 'Member Name', hintText: '${selectedMember?['fullName'] ?? ''}')),
        const SizedBox(height: 10),
        TextFormField(readOnly: true, decoration: InputDecoration(labelText: 'Mobile No', hintText: '${selectedMember?['mobileNo'] ?? ''}')),
        const SizedBox(height: 10),
        TextField(controller: adminId, decoration: const InputDecoration(labelText: 'Admin ID')),
        const SizedBox(height: 10),
        TextField(controller: password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: role,
          decoration: const InputDecoration(labelText: 'Role'),
          items: _roles
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => role = v ?? 'STAFF'),
        ),
        SwitchListTile(value: active, onChanged: (v) => setState(() => active = v), title: const Text('Active')),
        PrimaryButton(label: 'Create Staff Login', loading: loading, onPressed: _create),
        const Divider(),
        const Text('Existing staff', style: TextStyle(fontWeight: FontWeight.bold)),
        if (loadingStaff) const LinearProgressIndicator(),
        for (final s in staff)
          ListTile(
            title: Text('${s['adminId'] ?? ''}'),
            subtitle: Text('${s['role'] ?? ''} • ${s['fullName'] ?? ''} • Active: ${s['active'] ?? ''}'),
            trailing: const Icon(Icons.edit),
            onTap: () => _editStaff(Map<String, dynamic>.from(s)),
          ),
      ]),
    );
  }

  Future<void> _editStaff(Map<String, dynamic> staffRow) async {
    final passwordController = TextEditingController();
    String editedRole = '${staffRow['role'] ?? 'STAFF'}';
    bool editedActive = staffRow['active'] != false;
    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Edit ${staffRow['adminId'] ?? 'Staff'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: editedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: _roles.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setDialogState(() => editedRole = v ?? 'STAFF'),
              ),
              const SizedBox(height: 10),
              TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'New password (optional)'), obscureText: true),
              SwitchListTile(value: editedActive, onChanged: (v) => setDialogState(() => editedActive = v), title: const Text('Active')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  await api.put('/admin/staff/${staffRow['id']}', body: {
                    'password': passwordController.text.trim().isEmpty ? null : passwordController.text,
                    'role': editedRole,
                    'active': editedActive,
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (e) {
                  if (dialogContext.mounted) showSnack(dialogContext, '$e');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (updated == true) {
      await _loadStaff();
      if (mounted) showSnack(context, 'Staff updated');
    }
  }

  int? _id(dynamic value) => value is Map && value['id'] is num ? (value['id'] as num).toInt() : null;

  static const _roles = ['SUPER_ADMIN', 'PRESIDENT', 'VICE_PRESIDENT', 'GENERAL_SECRETARY', 'JOINT_SECRETARY', 'ORG_SECRETARY', 'TREASURER', 'SECRETARY', 'STAFF', 'MEMBER'];
}
