import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_store.dart';
import '../../core/widgets/common_widgets.dart';

class MemberRegistrationScreen extends StatefulWidget {
  const MemberRegistrationScreen({super.key});

  @override
  State<MemberRegistrationScreen> createState() => _MemberRegistrationScreenState();
}

class _MemberRegistrationScreenState extends State<MemberRegistrationScreen> {
  final formKey = GlobalKey<FormState>();
  final main = _MemberFormData();
  final family = <_MemberFormData>[];
  bool loading = false;

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await ApiClient(context.read<AuthStore>()).post('/public/member-registration', body: {
        'mainMember': main.toJson(),
        'familyMembers': family.map((e) => e.toJson()).toList(),
      });
      if (!mounted) return;
      showSnack(context, 'Registration submitted');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Member Registration',
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Main member', style: TextStyle(fontWeight: FontWeight.bold)),
            _MemberForm(data: main),
            const SizedBox(height: 10),
            for (var i = 0; i < family.length; i++)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('Family member ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      IconButton(onPressed: () => setState(() => family.removeAt(i)), icon: const Icon(Icons.delete)),
                    ]),
                    _MemberForm(data: family[i]),
                  ]),
                ),
              ),
            OutlinedButton.icon(onPressed: () => setState(() => family.add(_MemberFormData())), icon: const Icon(Icons.add), label: const Text('Add Family Member')),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Register', loading: loading, onPressed: _submit),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }
}

class _MemberForm extends StatelessWidget {
  const _MemberForm({required this.data});
  final _MemberFormData data;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 10),
      TextFormField(controller: data.firstName, decoration: const InputDecoration(labelText: 'First Name'), validator: _required),
      const SizedBox(height: 10),
      TextFormField(controller: data.lastName, decoration: const InputDecoration(labelText: 'Last Name')),
      const SizedBox(height: 10),
      TextFormField(controller: data.fatherName, decoration: const InputDecoration(labelText: 'Father/Husband Name'), validator: _required),
      const SizedBox(height: 10),
      TextFormField(controller: data.age, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age'), validator: _age),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: data.sex,
        decoration: const InputDecoration(labelText: 'Sex'),
        items: const ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => data.sex = v ?? 'Male',
      ),
      const SizedBox(height: 10),
      TextFormField(controller: data.mobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile No')),
      const SizedBox(height: 10),
      TextFormField(controller: data.address, minLines: 2, maxLines: 3, decoration: const InputDecoration(labelText: 'Address'), validator: _required),
    ]);
  }

  static String? _required(String? v) => v == null || v.trim().isEmpty ? 'Required' : null;
  static String? _age(String? v) => v == null || v.trim().isEmpty || int.tryParse(v) != null ? null : 'Age must be numeric';
}

class _MemberFormData {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final fatherName = TextEditingController();
  final age = TextEditingController();
  final mobile = TextEditingController();
  final address = TextEditingController();
  String sex = 'Male';

  Map<String, dynamic> toJson() => {
        'firstName': firstName.text.trim(),
        'lastName': lastName.text.trim(),
        'fatherOrHusbandName': fatherName.text.trim(),
        'age': int.tryParse(age.text.trim()),
        'sex': sex,
        'mobileNo': mobile.text.trim(),
        'address': address.text.trim(),
      };
}
