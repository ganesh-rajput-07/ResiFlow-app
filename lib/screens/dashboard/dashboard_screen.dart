import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../gatekeeper/create_pass_screen.dart';
import '../scanner/qr_scanner_screen.dart';
import '../approvals/pre_approval_screen.dart';
import '../approvals/approval_management_screen.dart';
import '../admin/society_config_screen.dart';
import '../admin/invite_members_screen.dart';
import '../admin/manage_helpers_screen.dart';
import '../admin/resident_approval_screen.dart';
import '../finance/penalties_screen.dart';
import '../finance/maintenance_finance_screen.dart';
import '../finance/resident_payments_screen.dart';
import '../finance/resident_penalties_screen.dart';
import '../directory/helpers_directory_screen.dart';
import '../communication/community_forum_screen.dart';
import '../communication/notices_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final role = user?['role'] ?? 'resident';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Text(
              'Welcome, ${user?['first_name'] ?? user?['username'] ?? 'User'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (user?['society_name'] != null) ...[
              const SizedBox(height: 4),
              Text(
                '${user?['society_name']} - Unit ${user?['unit_number'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 28),

            // ─── ADMIN PANEL ───
            if (role == 'admin') ...[
              _buildSection(
                title: 'Admin Panel',
                items: [
                  _DashboardItem(icon: Icons.settings, title: 'Society Config',
                    onTap: () => _push(context, const SocietyConfigScreen())),
                  _DashboardItem(icon: Icons.person_add_alt_1, title: 'Invite Residents',
                    onTap: () => _push(context, const InviteMembersScreen())),
                  _DashboardItem(icon: Icons.how_to_reg, title: 'Approvals',
                    onTap: () => _push(context, const ResidentApprovalScreen())),
                  _DashboardItem(icon: Icons.gavel, title: 'Penalties',
                    onTap: () => _push(context, const PenaltiesScreen())),
                  _DashboardItem(icon: Icons.cleaning_services, title: 'Manage Staff',
                    onTap: () => _push(context, const ManageHelpersScreen())),
                  _DashboardItem(icon: Icons.currency_rupee, title: 'Finance',
                    onTap: () => _push(context, const MaintenanceFinanceScreen())),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // ─── RESIDENT: QUICK ACCESS ───
            if (role == 'admin' || role == 'resident') ...[
              _buildSection(
                title: 'Quick Access',
                items: [
                  _DashboardItem(icon: Icons.qr_code_scanner, title: 'Gate Pass',
                    onTap: () => _push(context, const CreatePassScreen())),
                  _DashboardItem(icon: Icons.people_outline, title: 'Pre-Approval',
                    onTap: () {
                      if (role == 'admin') {
                        _push(context, const ApprovalManagementScreen());
                      } else {
                        _push(context, const PreApprovalScreen());
                      }
                    }),
                  _DashboardItem(icon: Icons.cleaning_services, title: 'Helpers',
                    onTap: () => _push(context, const HelpersDirectoryScreen())),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // ─── RESIDENT: PAYMENTS & PENALTIES ───
            if (role == 'admin' || role == 'resident') ...[
              _buildSection(
                title: 'Payments & Dues',
                items: [
                  _DashboardItem(icon: Icons.payment, title: 'Maintenance',
                    onTap: () {
                      if (role == 'admin') {
                        _push(context, const MaintenanceFinanceScreen());
                      } else {
                        _push(context, const ResidentPaymentsScreen());
                      }
                    }),
                  _DashboardItem(icon: Icons.gavel, title: 'My Penalties',
                    onTap: () {
                      if (role == 'admin') {
                        _push(context, const PenaltiesScreen());
                      } else {
                        _push(context, const ResidentPenaltiesScreen());
                      }
                    }),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // ─── GUARD: SECURITY ───
            if (role == 'guard' || role == 'admin') ...[
              _buildSection(
                title: 'Security',
                items: [
                  _DashboardItem(icon: Icons.camera_alt_outlined, title: 'Scan QR Pass',
                    onTap: () => _push(context, const QRScannerScreen())),
                  _DashboardItem(icon: Icons.history, title: 'Visitor Logs',
                    onTap: () {}),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // ─── COMMUNICATION (ALL ROLES) ───
            _buildSection(
              title: 'Communication',
              items: [
                _DashboardItem(icon: Icons.campaign_outlined, title: 'Notices',
                  onTap: () => _push(context, const NoticesScreen())),
                _DashboardItem(icon: Icons.forum_outlined, title: 'Community',
                  onTap: () => _push(context, const CommunityForumScreen())),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
          children: items,
        ),
      ],
    );
  }
}

class _DashboardItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DashboardItem({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 28),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
