import 'package:flutter/material.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/core/widgets/coming_soon_screen.dart';
import 'package:naqsh_office/features/auth/auth_repository.dart';

class _MenuItem {
  const _MenuItem(this.title, this.icon);

  final String title;
  final IconData icon;
}

class _MenuGroup {
  const _MenuGroup(this.title, this.items);

  final String title;
  final List<_MenuItem> items;
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.userEmail});

  final String userEmail;

  static const List<_MenuGroup> groups = [
    _MenuGroup('Sales', [
      _MenuItem('Plot Map', Icons.map_outlined),
      _MenuItem('Bookings', Icons.bookmark_border_rounded),
      _MenuItem('Price List', Icons.sell_outlined),
    ]),
    _MenuGroup('Accounts', [
      _MenuItem('Receipts', Icons.receipt_long_outlined),
      _MenuItem('Ledger', Icons.menu_book_outlined),
      _MenuItem('Reports', Icons.bar_chart_rounded),
    ]),
    _MenuGroup('Ownership', [
      _MenuItem('NDC and Transfers', Icons.swap_horiz_rounded),
    ]),
    _MenuGroup('Support', [
      _MenuItem('Help Desk', Icons.support_agent_rounded),
      _MenuItem('Notices', Icons.campaign_outlined),
      _MenuItem('Emergency', Icons.warning_amber_rounded),
      _MenuItem('Visitors', Icons.badge_outlined),
    ]),
    _MenuGroup('Services', [
      _MenuItem('Workers', Icons.engineering_outlined),
      _MenuItem('Listings', Icons.storefront_outlined),
    ]),
    _MenuGroup('Admin', [
      _MenuItem('Staff', Icons.groups_outlined),
      _MenuItem('Audit Log', Icons.history_rounded),
      _MenuItem('Settings', Icons.settings_outlined),
    ]),
  ];

  void openItem(BuildContext context, String title) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ComingSoonScreen(title: title)),
    );
  }

  Future<void> logout() async {
    await AuthRepository().signOut();
    // Login screen khud khul jati hai (app.dart ka StreamBuilder).
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final initial = userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'N';

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header (compact)
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF3730A3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFFBBF24),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Naqsh',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x26FBBF24),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Demo City',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFBBF24),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu (scroll hota hai)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                for (final group in groups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
                    child: Text(
                      group.title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  for (final item in group.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        horizontalTitleGap: 12,
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item.icon,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                        onTap: () => openItem(context, item.title),
                      ),
                    ),
                ],
              ],
            ),
          ),

          // Logout (neeche fixed)
          const Divider(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Material(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFDC2626),
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  onTap: logout,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}