import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_store.dart';
import '../../core/utils/loading_helper.dart';
import '../../core/widgets/common_widgets.dart';

String _ym(DateTime d) => DateFormat('yyyy-MM').format(d);
String _date(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

class TransactionEntryScreen extends StatefulWidget {
  const TransactionEntryScreen({super.key});
  @override
  State<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends State<TransactionEntryScreen> {
  DateTime date = DateTime.now();
  String type = 'CREDIT';
  final keyword = TextEditingController();
  final amount = TextEditingController();
  final remarks = TextEditingController();
  List members = [];
  Map<String, dynamic>? selected;
  int? selectedMemberId;
  int? selectedFamilyId;
  bool searching = false;
  bool loading = false;

  Future<void> _search() async {
    setState(() => searching = true);
    LoadingHelper.show(context);
    try {
      final data = await ApiClient(context.read<AuthStore>()).get('/members/search', query: {'keyword': keyword.text.trim()});
      setState(() {
        members = data is List ? data : [];
        if (selectedMemberId != null && !members.any((m) => _id(m) == selectedMemberId)) {
          selected = null;
          selectedMemberId = null;
          selectedFamilyId = null;
        }
      });
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => searching = false);
    }
  }

  Future<void> _save() async {
    if (amount.text.trim().isEmpty) return showSnack(context, 'Amount is required');
    final parsedAmount = num.tryParse(amount.text.trim());
    if (parsedAmount == null || parsedAmount <= 0) return showSnack(context, 'Enter a valid amount');
    setState(() => loading = true);
    LoadingHelper.show(context);
    try {
      await ApiClient(context.read<AuthStore>()).post('/transactions', body: {
        'transactionDate': _date(date),
        'transactionType': type,
        'familyId': type == 'CREDIT' ? selectedFamilyId : null,
        'memberId': type == 'CREDIT' ? selectedMemberId : null,
        'amount': parsedAmount,
        'remarks': remarks.text.trim(),
      });
      if (mounted) showSnack(context, 'Transaction saved');
      amount.clear();
      remarks.clear();
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Transaction Entry',
        body: ListView(padding: const EdgeInsets.all(16), children: [
          ListTile(
            title: Text('Transaction Date: ${_date(date)}'),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final picked = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: date);
              if (picked != null) setState(() => date = picked);
            },
          ),
          DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Transaction Type'),
              items: const ['CREDIT', 'DEBIT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() {
                    type = v ?? 'CREDIT';
                    if (type == 'DEBIT') {
                      selected = null;
                      selectedMemberId = null;
                      selectedFamilyId = null;
                    }
                  })),
          if (type == 'CREDIT') ...[
            const SizedBox(height: 10),
            Row(children: [Expanded(child: TextField(controller: keyword, decoration: const InputDecoration(labelText: 'Search family/member'))), IconButton.filled(onPressed: searching ? null : _search, icon: const Icon(Icons.search))]),
            for (final m in members.take(4))
              if (_id(m) != null)
                RadioListTile<int>(
                  value: _id(m)!,
                  groupValue: selectedMemberId,
                  title: Text('${m['fullName']}'),
                  subtitle: Text('Family ${m['familyId'] ?? '-'}'),
                  onChanged: (v) => setState(() {
                    selectedMemberId = v;
                    selectedFamilyId = _familyId(m);
                    selected = Map<String, dynamic>.from(m);
                  }),
                ),
            if (selected != null) Text('Selected: ${selected?['fullName'] ?? ''} • Family ${selected?['familyId'] ?? '-'}'),
          ],
          const SizedBox(height: 10),
          TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount')),
          const SizedBox(height: 10),
          TextField(controller: remarks, decoration: const InputDecoration(labelText: 'Remarks'), minLines: 2, maxLines: 3),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Save Transaction', loading: loading, onPressed: _save),
        ]),
      );

  int? _id(dynamic value) => value is Map && value['id'] is num ? (value['id'] as num).toInt() : null;
  int? _familyId(dynamic value) => value is Map && value['familyId'] is num ? (value['familyId'] as num).toInt() : null;
}

class TransactionViewScreen extends StatefulWidget {
  const TransactionViewScreen({super.key});
  @override
  State<TransactionViewScreen> createState() => _TransactionViewScreenState();
}

class _TransactionViewScreenState extends State<TransactionViewScreen> {
  DateTime month = DateTime.now();
  List rows = [];
  Map balance = {};
  Map summary = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = ApiClient(context.read<AuthStore>());
    try {
      final r = await api.get('/transactions');
      final b = await api.get('/transactions/balance');
      final s = await api.get('/transactions/monthly-summary', query: {'month': _ym(month)});
      setState(() {
        rows = r is List ? r : [];
        balance = b is Map ? b : {};
        summary = s is Map ? s : {};
      });
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Transactions View',
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [Expanded(child: Text('Month: ${_ym(month)}')), FilledButton(onPressed: _load, child: const Text('Refresh'))]),
              Row(children: [
                Expanded(child: _tile('Credit', '${summary['totalCredit'] ?? balance['totalCredit'] ?? 0}')),
                Expanded(child: _tile('Debit', '${summary['totalDebit'] ?? balance['totalDebit'] ?? 0}')),
                Expanded(child: _tile('Balance', '${summary['balance'] ?? balance['balance'] ?? 0}')),
              ]),
            ]),
          ),
          Expanded(
            child: rows.isEmpty
                ? const EmptyView('No transactions found')
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text('${rows[i]['transactionType']} • ₹${rows[i]['amount']}'),
                      subtitle: Text('${rows[i]['transactionDate']} • ${rows[i]['remarks'] ?? ''}'),
                    ),
                  ),
          ),
        ]),
      );

  Widget _tile(String label, String value) => Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [Text(value, style: const TextStyle(fontWeight: FontWeight.bold)), Text(label)])));
}
