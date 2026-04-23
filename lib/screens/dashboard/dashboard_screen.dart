import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../gatekeeper/create_pass_screen.dart';
import '../scanner/qr_scanner_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
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
            Text(
              'Welcome, ${user?['first_name'] ?? user?['username'] ?? 'User'}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (user?['society_name'] != null) ...[
              const SizedBox(height: 4),
              Text(
                '${user?['society_name']} - Unit ${user?['unit_number'] ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 32),
            if (user?['role'] == 'admin' || user?['role'] == 'resident')
              _buildSection(
                title: 'Quick Access',
                items: [
                  _DashboardItem(
                    icon: Icons.qr_code_scanner,
                    title: 'Gate Pass',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreatePassScreen()),
                      );
                    },
                  ),
                  _DashboardItem(
                    icon: Icons.people_outline,
                    title: 'Pre-Approval',
                    onTap: () {},
                  ),
                  _DashboardItem(
                    icon: Icons.payment,
                    title: 'Payments',
                    onTap: () {},
                  ),
                ],
              ),
              
            if (user?['role'] == 'guard' || user?['role'] == 'admin') ...[
              const SizedBox(height: 24),
              _buildSection(
                title: 'Security',
                items: [
                  _DashboardItem(
                    icon: Icons.camera_alt_outlined,
                    title: 'Scan QR Pass',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                      );
                    },
                  ),
                  _DashboardItem(
                    icon: Icons.history,
                    title: 'Visitor Logs',
                    onTap: () {},
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            _buildSection(
              title: 'Communication',
              items: [
                _DashboardItem(
                  icon: Icons.campaign_outlined,
                  title: 'Notices',
                  onTap: () {},
                ),
                _DashboardItem(
                  icon: Icons.report_problem_outlined,
                  title: 'Complaints',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
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

  const _DashboardItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

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
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
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
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
