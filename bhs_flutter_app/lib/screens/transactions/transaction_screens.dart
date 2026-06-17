import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_store.dart';
import '../../core/utils/loading_helper.dart';
import '../../core/utils/roles.dart';
import '../../core/widgets/common_widgets.dart';

String _ym(DateTime d) => DateFormat('yyyy-MM').format(d);
String _date(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
String _money(dynamic value) {
  final parsed = value is num ? value : num.tryParse('${value ?? 0}') ?? 0;
  return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2)
      .format(parsed);
}

class TransactionStatementScreen extends StatefulWidget {
  const TransactionStatementScreen({super.key});
  @override
  State<TransactionStatementScreen> createState() =>
      _TransactionStatementScreenState();
}

class _TransactionStatementScreenState
    extends State<TransactionStatementScreen> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, dynamic> statement = {};
  bool loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: month,
      helpText: 'Select any date in the month',
    );
    if (picked == null) return;
    setState(() => month = DateTime(picked.year, picked.month));
    await _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    LoadingHelper.show(context);
    try {
      final data = await ApiClient(context.read<AuthStore>())
          .get('/transactions/monthly-statement', query: {'month': _ym(month)});
      setState(
          () => statement = data is Map ? Map<String, dynamic>.from(data) : {});
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _download() async {
    LoadingHelper.show(context);
    try {
      final bytes = await ApiClient(context.read<AuthStore>()).download(
          '/transactions/download-statement',
          query: {'month': _ym(month)});
      final dir = await getApplicationDocumentsDirectory();
      final file =
          File('${dir.path}/bhs_transaction_statement_${_ym(month)}.xlsx');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
    }
  }

  Future<void> _addTransaction() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => TransactionEntryScreen(initialDate: month)),
    );
    if (saved == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthStore>().role;
    final canAdd = Roles.canManageTransactions(role);
    final rows = statement['transactions'] is List
        ? statement['transactions'] as List
        : const [];
    return AppScaffold(
      title: 'Transaction Statement',
      actions: [
        if (canAdd)
          IconButton(onPressed: _addTransaction, icon: const Icon(Icons.add))
      ],
      body: loading && statement.isEmpty
          ? const LoadingView()
          : ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [
                Expanded(
                    child: Text('Month: ${_ym(month)}',
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                IconButton.filledTonal(
                    onPressed: _pickMonth,
                    icon: const Icon(Icons.calendar_month)),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                    onPressed: _load, icon: const Icon(Icons.refresh)),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _summaryCard('Opening Balance', statement['openingBalance']),
                _summaryCard('Total Credit', statement['totalCredit'],
                    color: Colors.green),
                _summaryCard('Total Debit', statement['totalDebit'],
                    color: Colors.red),
                _summaryCard('Closing Balance', statement['closingBalance'],
                    color: Colors.blue),
              ]),
              const SizedBox(height: 12),
              TransactionChartWidget(
                creditAmount: statement['totalCredit'],
                debitAmount: statement['totalDebit'],
                creditPercentage: statement['creditPercentage'],
                debitPercentage: statement['debitPercentage'],
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: _download,
                        icon: const Icon(Icons.download),
                        label: const Text('Download Statement'))),
                if (canAdd) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                      onPressed: _addTransaction,
                      icon: const Icon(Icons.add),
                      label: const Text('Add')),
                ],
              ]),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                const EmptyView('No transactions found for this month'),
              for (final row in rows)
                _statementRow(Map<String, dynamic>.from(row)),
            ]),
    );
  }

  Widget _summaryCard(String label, dynamic value, {Color? color}) => SizedBox(
        width: 165,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              Text(_money(value),
                  style: TextStyle(fontWeight: FontWeight.w800, color: color)),
            ]),
          ),
        ),
      );

  Widget _statementRow(Map<String, dynamic> row) {
    final isCredit = row['transactionType'] == 'CREDIT';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text('${row['transactionDate'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text('${row['transactionType'] ?? ''}'),
              backgroundColor:
                  isCredit ? Colors.green.shade50 : Colors.red.shade50,
            ),
          ]),
          const SizedBox(height: 4),
          Text('${row['purpose'] ?? '-'}'),
          if ((row['remarks'] ?? '').toString().isNotEmpty)
            Text('${row['remarks']}',
                style: Theme.of(context).textTheme.bodySmall),
          const Divider(),
          Row(children: [
            Expanded(
                child:
                    _amountColumn('Credit', row['creditAmount'], Colors.green)),
            Expanded(
                child: _amountColumn('Debit', row['debitAmount'], Colors.red)),
            Expanded(
                child: _amountColumn(
                    'Balance', row['balanceAfterTransaction'], Colors.blue)),
          ]),
        ]),
      ),
    );
  }

  Widget _amountColumn(String label, dynamic value, Color color) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        Text(_money(value),
            style: TextStyle(
                fontWeight: FontWeight.w700, color: color, fontSize: 12)),
      ]);
}

class TransactionChartWidget extends StatelessWidget {
  const TransactionChartWidget(
      {super.key,
      this.creditAmount,
      this.debitAmount,
      this.creditPercentage,
      this.debitPercentage});
  final dynamic creditAmount;
  final dynamic debitAmount;
  final dynamic creditPercentage;
  final dynamic debitPercentage;

  @override
  Widget build(BuildContext context) {
    final credit = _asDouble(creditPercentage);
    final debit = _asDouble(debitPercentage);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Credit vs Debit',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _bar('Credit', credit, creditAmount, Colors.green),
          const SizedBox(height: 10),
          _bar('Debit', debit, debitAmount, Colors.red),
        ]),
      ),
    );
  }

  Widget _bar(String label, double percent, dynamic amount, Color color) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label)),
          Text('${percent.toStringAsFixed(2)}% • ${_money(amount)}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
              value: (percent / 100).clamp(0, 1).toDouble(),
              minHeight: 12,
              color: color,
              backgroundColor: Colors.grey.shade200),
        ),
      ]);

  double _asDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('${value ?? 0}') ?? 0;
}

class TransactionEntryScreen extends StatefulWidget {
  const TransactionEntryScreen({super.key, this.initialDate});
  final DateTime? initialDate;

  @override
  State<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends State<TransactionEntryScreen> {
  late DateTime date;
  String type = 'CREDIT';
  final keyword = TextEditingController();
  final amount = TextEditingController();
  final purpose = TextEditingController();
  final remarks = TextEditingController();
  List members = [];
  Map<String, dynamic>? selected;
  int? selectedMemberId;
  int? selectedFamilyId;
  bool searching = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    date = widget.initialDate ?? DateTime.now();
  }

  Future<void> _search() async {
    setState(() => searching = true);
    LoadingHelper.show(context);
    try {
      final data = await ApiClient(context.read<AuthStore>())
          .get('/search/members', query: {'keyword': keyword.text.trim()});
      setState(() => members = data is List ? data : []);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => searching = false);
    }
  }

  Future<void> _save() async {
    final parsedAmount = num.tryParse(amount.text.trim());
    if (parsedAmount == null || parsedAmount <= 0) {
      return showSnack(context, 'Enter a valid amount');
    }
    if (purpose.text.trim().isEmpty) {
      return showSnack(context, 'Purpose is required');
    }
    setState(() => loading = true);
    LoadingHelper.show(context);
    try {
      await ApiClient(context.read<AuthStore>()).post('/transactions', body: {
        'transactionDate': _date(date),
        'transactionType': type,
        'familyId': type == 'CREDIT' ? selectedFamilyId : null,
        'memberId': type == 'CREDIT' ? selectedMemberId : null,
        'amount': parsedAmount,
        'purpose': purpose.text.trim(),
        'remarks': remarks.text.trim(),
      });
      if (mounted) showSnack(context, 'Transaction saved');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Add Transaction',
        body: ListView(padding: const EdgeInsets.all(16), children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Transaction Date: ${_date(date)}'),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDate: date);
              if (picked != null) setState(() => date = picked);
            },
          ),
          DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Transaction Type'),
              items: const ['CREDIT', 'DEBIT']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() {
                    type = v ?? 'CREDIT';
                    if (type == 'DEBIT') {
                      selected = null;
                      selectedMemberId = null;
                      selectedFamilyId = null;
                    }
                  })),
          const SizedBox(height: 10),
          TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount')),
          const SizedBox(height: 10),
          TextField(
              controller: purpose,
              decoration: const InputDecoration(labelText: 'Purpose')),
          const SizedBox(height: 10),
          TextField(
              controller: remarks,
              decoration: const InputDecoration(labelText: 'Remarks'),
              minLines: 2,
              maxLines: 3),
          if (type == 'CREDIT') ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: keyword,
                      decoration: const InputDecoration(
                          labelText: 'Optional family/member search'))),
              const SizedBox(width: 8),
              IconButton.filled(
                  onPressed: searching ? null : _search,
                  icon: const Icon(Icons.search)),
            ]),
            for (final m in members.take(4))
              if (_id(m) != null)
                RadioListTile<int>(
                  value: _id(m)!,
                  groupValue: selectedMemberId,
                  title: Text('${m['fullName']}'),
                  subtitle:
                      Text('Family ${m['familyCode'] ?? m['familyId'] ?? '-'}'),
                  onChanged: (v) => setState(() {
                    selectedMemberId = v;
                    selectedFamilyId = _familyId(m);
                    selected = Map<String, dynamic>.from(m);
                  }),
                ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
              label: 'Save Transaction', loading: loading, onPressed: _save),
        ]),
      );

  int? _id(dynamic value) =>
      value is Map && value['id'] is num ? (value['id'] as num).toInt() : null;
  int? _familyId(dynamic value) => value is Map && value['familyId'] is num
      ? (value['familyId'] as num).toInt()
      : null;
}

class TransactionViewScreen extends StatelessWidget {
  const TransactionViewScreen({super.key});
  @override
  Widget build(BuildContext context) => const TransactionStatementScreen();
}
