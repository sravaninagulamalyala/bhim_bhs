import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../screens/attendance/attendance_screens.dart';
import '../../screens/audit/audit_logs_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/member_registration/member_registration_screen.dart';
import '../../screens/members/member_screens.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/reports/report_screens.dart';
import '../../screens/search/member_family_search_screen.dart';
import '../../screens/staff/staff_management_screen.dart';
import '../../screens/transactions/transaction_screens.dart';
import '../constants/api_constants.dart';
import '../storage/auth_store.dart';
import '../utils/roles.dart';

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
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF0D47A1)),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(ApiConstants.associationName, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            ),
          ),
          _item(context, Icons.home, 'Home', const HomeScreen()),
          if (!auth.isLoggedIn) _item(context, Icons.login, 'Staff Login', const StaffLoginScreen()),
          if (!auth.isLoggedIn) _item(context, Icons.person, 'Member Login', const StaffLoginScreen(title: 'Member Login')),
          _item(context, Icons.app_registration, 'Member Registration', const MemberRegistrationScreen()),
          if (auth.isLoggedIn) _item(context, Icons.dashboard, 'Dashboard', const DashboardScreen()),
          if (auth.isLoggedIn) _item(context, Icons.search, 'Search', const MemberFamilySearchScreen()),
          if (Roles.isSuperAdmin(role)) _item(context, Icons.upload_file, 'Excel Upload', const ExcelUploadScreen()),
          if (Roles.isSuperAdmin(role)) _item(context, Icons.admin_panel_settings, 'Staff Management', const StaffManagementScreen()),
          if (Roles.isSuperAdmin(role)) _item(context, Icons.history, 'Audit Logs', const AuditLogsScreen()),
          if (Roles.canUpdateMembers(role)) _item(context, Icons.edit, 'Members', const MemberUpdateScreen()),
          if (Roles.canUpdateMembers(role)) _item(context, Icons.family_restroom, 'Family Mapping', const FamilyMappingScreen()),
          if (Roles.canManageAttendance(role)) _item(context, Icons.fact_check, 'Mark Attendance', const MarkAttendanceScreen()),
          if (auth.isLoggedIn) _item(context, Icons.visibility, 'View Attendance', const ViewAttendanceScreen()),
          if (Roles.canManageTransactions(role)) _item(context, Icons.payments, 'Transaction Entry', const TransactionEntryScreen()),
          if (auth.isLoggedIn) _item(context, Icons.receipt_long, 'Transactions View', const TransactionViewScreen()),
          if (auth.isLoggedIn) _item(context, Icons.bar_chart, 'Reports', const ReportsScreen()),
          if (auth.isLoggedIn) _item(context, Icons.grid_on, 'Heatmap View', const HeatmapScreen()),
          if (auth.isLoggedIn) _item(context, Icons.account_circle, 'Profile / Logout', const ProfileScreen()),
          const Divider(),
          const ListTile(title: Text('Active Family Count')),
          const ListTile(title: Text('Active Member Count')),
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
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
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
        child: loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(label),
      );
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
