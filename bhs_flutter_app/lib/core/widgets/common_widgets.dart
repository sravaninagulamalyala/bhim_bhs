import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../screens/attendance/attendance_screens.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/member_registration/member_registration_screen.dart';
import '../../screens/members/member_screens.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/reports/report_screens.dart';
import '../../screens/search/member_family_search_screen.dart';
import '../../screens/transactions/transaction_screens.dart';
import '../storage/auth_store.dart';
import '../utils/roles.dart';
import 'ambedkar_loading_dialog.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.title, required this.body, this.actions});
  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: const BhsDrawer(),
      body: SafeArea(child: body),
    );
  }
}

class BhsDrawer extends StatelessWidget {
  const BhsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final role = auth.role;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 12),
          _item(context, Icons.home, 'Home', const HomeScreen()),
          if (auth.isLoggedIn) _item(context, Icons.dashboard, 'Dashboard', const DashboardScreen()),
          _item(context, Icons.app_registration, 'Member Registration', const MemberRegistrationScreen()),
          if (auth.isLoggedIn) _item(context, Icons.search, 'Search Members', const MemberFamilySearchScreen()),
          if (Roles.canUpdateMembers(role)) _item(context, Icons.family_restroom, 'Family Mapping', const FamilyMappingScreen()),
          if (Roles.canManageAttendance(role)) _item(context, Icons.fact_check, 'Attendance', const MarkAttendanceScreen()),
          if (auth.isLoggedIn) _item(context, Icons.visibility, 'View Attendance', const ViewAttendanceScreen()),
          if (auth.isLoggedIn) _item(context, Icons.payments, 'Transactions', Roles.canManageTransactions(role) ? const TransactionEntryScreen() : const TransactionViewScreen()),
          if (auth.isLoggedIn) _item(context, Icons.bar_chart, 'Reports', const ReportsScreen()),
          if (auth.isLoggedIn) _item(context, Icons.account_circle, 'Profile / Logout', const ProfileScreen()),
        ],
      ),
    );
  }

  ListTile _item(BuildContext context, IconData icon, String title, Widget screen) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: AmbedkarLoadingContent());
}

class ErrorText extends StatelessWidget {
  const ErrorText(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message, style: const TextStyle(color: Colors.red)),
      );
}

class EmptyView extends StatelessWidget {
  const EmptyView(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message)));
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: loading ? null : onPressed,
        child: Text(loading ? 'Please wait...' : label),
      );
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
