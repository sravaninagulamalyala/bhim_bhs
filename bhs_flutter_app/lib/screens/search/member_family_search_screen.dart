import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_store.dart';
import '../../core/utils/loading_helper.dart';
import '../../core/widgets/common_widgets.dart';
import '../members/member_screens.dart';

class MemberFamilySearchScreen extends StatelessWidget {
  const MemberFamilySearchScreen({super.key});

  @override
  Widget build(BuildContext context) => const MemberSearchScreen();
}

class MemberSearchScreen extends StatefulWidget {
  const MemberSearchScreen({super.key});

  @override
  State<MemberSearchScreen> createState() => _MemberSearchScreenState();
}

class _MemberSearchScreenState extends State<MemberSearchScreen> {
  final keyword = TextEditingController();
  List members = [];
  bool loading = false;

  Future<void> _search() async {
    setState(() => loading = true);
    LoadingHelper.show(context);
    try {
      final data = await ApiClient(context.read<AuthStore>()).get('/search/members', query: {'keyword': keyword.text.trim()});
      setState(() => members = data is List ? data : []);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Member Search',
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: TextField(controller: keyword, decoration: const InputDecoration(labelText: 'Name / mobile / house / family code'))),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: loading ? null : _search, icon: const Icon(Icons.search)),
            ]),
          ),
          Expanded(
            child: members.isEmpty
                ? const EmptyView('Search members to view details')
                : ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (_, i) => _MemberResultCard(member: Map<String, dynamic>.from(members[i]), onUpdated: _search),
                  ),
          ),
        ]),
      );
}

class _MemberResultCard extends StatelessWidget {
  const _MemberResultCard({required this.member, required this.onUpdated});
  final Map<String, dynamic> member;
  final VoidCallback onUpdated;

  Future<void> _edit(BuildContext context) async {
    final id = member['id'];
    if (id is! num) return;
    try {
      LoadingHelper.show(context);
      final data = await ApiClient(context.read<AuthStore>()).get('/members/${id.toInt()}/details');
      final detailMember = data is Map && data['member'] is Map ? Map<String, dynamic>.from(data['member']) : member;
      if (!context.mounted) return;
      LoadingHelper.hide(context);
      await Navigator.push(context, MaterialPageRoute(builder: (_) => MemberEditScreen(member: detailMember)));
      onUpdated();
    } catch (e) {
      if (context.mounted) showSnack(context, '$e');
    } finally {
      if (context.mounted) LoadingHelper.hide(context);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${member['fullName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            _line('Father/Husband', member['fatherOrHusbandName']),
            _line('Mobile', member['mobileNo']),
            _line('House No', member['houseNo']),
            _line('Family Code', member['familyCode'] ?? member['familyId']),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.edit),
                  label: const Text('Update'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    final id = member['id'];
                    if (id is num) Navigator.push(context, MaterialPageRoute(builder: (_) => MemberDetailScreen(memberId: id.toInt()))).then((_) => onUpdated());
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View'),
                ),
              ],
            ),
          ]),
        ),
      );

  Widget _line(String label, Object? value) => Padding(padding: const EdgeInsets.only(top: 4), child: Text('$label: ${value ?? ''}'));
}

class MemberDetailScreen extends StatefulWidget {
  const MemberDetailScreen({super.key, required this.memberId});
  final int memberId;

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  Map<String, dynamic>? details;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => loading = true);
    LoadingHelper.show(context);
    try {
      final data = await ApiClient(context.read<AuthStore>()).get('/members/${widget.memberId}/details');
      setState(() => details = data is Map ? Map<String, dynamic>.from(data) : null);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _remove(Map<String, dynamic> familyMember) async {
    final family = _family;
    final memberId = _id(familyMember['id']);
    final familyId = _id(family?['id']);
    if (memberId == null || familyId == null) return;
    final api = ApiClient(context.read<AuthStore>());
    final ok = await _confirm();
    if (!ok) return;
    if (!mounted) return;
    setState(() => saving = true);
    LoadingHelper.show(context);
    try {
      await api.post('/members/family/remove', body: {'memberId': memberId, 'familyId': familyId});
      if (mounted) showSnack(context, 'Family mapping updated');
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _openAdd() async {
    final familyId = _id(_family?['id']);
    if (familyId == null) return showSnack(context, 'No family is mapped to this member');
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => FamilyMemberCorrectionScreen(targetFamilyId: familyId)));
    if (changed == true) await _load();
  }

  Future<bool> _confirm() async {
    final value = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm update'),
        content: const Text('Are you sure you want to update this family mapping?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update')),
        ],
      ),
    );
    return value == true;
  }

  Map<String, dynamic>? get _member => details?['member'] is Map ? Map<String, dynamic>.from(details!['member']) : null;
  Map<String, dynamic>? get _family => details?['family'] is Map ? Map<String, dynamic>.from(details!['family']) : null;
  List get _familyMembers => details?['familyMembers'] is List ? details!['familyMembers'] as List : const [];

  @override
  Widget build(BuildContext context) {
    final member = _member;
    final family = _family;
    final primaryMemberId = _id(family?['primaryMemberId']);
    return AppScaffold(
      title: 'Member Details',
      body: loading
          ? const LoadingView()
          : member == null
              ? const EmptyView('Member details not found')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    _SectionCard(title: 'Member', children: [
                      _line('Full Name', member['fullName']),
                      _line('Father/Husband', member['fatherOrHusbandName']),
                      _line('Age / Sex', '${member['age'] ?? ''} / ${member['sex'] ?? ''}'),
                      _line('Mobile', member['mobileNo']),
                      _line('Alternate Mobile', member['alternateMobileNo']),
                      _line('House No', member['houseNo']),
                      _line('Area', member['area']),
                      _line('Address', member['address']),
                    ]),
                    const SizedBox(height: 12),
                    _SectionCard(title: 'Family', children: [
                      _line('Family Code', family?['familyCode'] ?? member['familyId']),
                      _line('House No', family?['houseNo']),
                      _line('Area', family?['area']),
                      _line('Address', family?['address']),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: Text('Family Members', style: Theme.of(context).textTheme.titleMedium)),
                      FilledButton.icon(onPressed: saving ? null : _openAdd, icon: const Icon(Icons.person_add), label: const Text('Add Member')),
                    ]),
                    const SizedBox(height: 8),
                    for (final item in _familyMembers)
                      Card(
                        child: ListTile(
                          title: Text('${item['fullName'] ?? ''}'),
                          subtitle: Text('${item['mobileNo'] ?? ''} • ${item['houseNo'] ?? ''}'),
                          trailing: primaryMemberId != null && _id(item['id']) == primaryMemberId
                              ? const Text('Primary')
                              : IconButton(
                                  tooltip: 'Remove from family',
                                  onPressed: saving ? null : () => _remove(Map<String, dynamic>.from(item)),
                                  icon: const Icon(Icons.link_off),
                                ),
                        ),
                      ),
                  ]),
                ),
    );
  }

  Widget _line(String label, Object? value) => Padding(padding: const EdgeInsets.only(top: 6), child: Text('$label: ${value ?? ''}'));
}

class FamilyMemberCorrectionScreen extends StatefulWidget {
  const FamilyMemberCorrectionScreen({super.key, required this.targetFamilyId});
  final int targetFamilyId;

  @override
  State<FamilyMemberCorrectionScreen> createState() => _FamilyMemberCorrectionScreenState();
}

class _FamilyMemberCorrectionScreenState extends State<FamilyMemberCorrectionScreen> {
  final keyword = TextEditingController();
  List members = [];
  bool loading = false;
  bool saving = false;

  Future<void> _search() async {
    setState(() => loading = true);
    LoadingHelper.show(context);
    try {
      final data = await ApiClient(context.read<AuthStore>()).get('/search/members', query: {'keyword': keyword.text.trim()});
      setState(() => members = data is List ? data : []);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _add(Map<String, dynamic> member) async {
    final memberId = _id(member['id']);
    if (memberId == null) return;
    final api = ApiClient(context.read<AuthStore>());
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm update'),
        content: const Text('Are you sure you want to update this family mapping?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update')),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    setState(() => saving = true);
    LoadingHelper.show(context);
    try {
      await api.post('/members/family/add', body: {'memberId': memberId, 'targetFamilyId': widget.targetFamilyId});
      if (mounted) showSnack(context, 'Family mapping updated');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Add Family Member',
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: TextField(controller: keyword, decoration: const InputDecoration(labelText: 'Search member'))),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: loading ? null : _search, icon: const Icon(Icons.search)),
            ]),
          ),
          Expanded(
            child: members.isEmpty
                ? const EmptyView('Search and select a member')
                : ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (_, i) {
                      final member = Map<String, dynamic>.from(members[i]);
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: Text('${member['fullName'] ?? ''}'),
                          subtitle: Text('${member['mobileNo'] ?? ''} • Family ${member['familyId'] ?? '-'} • ${member['houseNo'] ?? ''}'),
                          trailing: FilledButton(onPressed: saving ? null : () => _add(member), child: const Text('Select')),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            ...children,
          ]),
        ),
      );
}

int? _id(Object? value) => value is num ? value.toInt() : int.tryParse('$value');
