import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_station/services/bookmark_service.dart';
import 'package:open_station/theme/app_theme.dart';

enum NavigationTab { discover, bookmarks, about }

class Sidebar extends StatelessWidget {
  final NavigationTab activeTab;
  final ValueChanged<NavigationTab> onTabSelected;

  const Sidebar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bookmarkCount = context.watch<BookmarkService>().bookmarks.length;

    return Container(
      width: 220,
      color: AppColors.deepNavy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Branding Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.openGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.radio,
                    color: AppColors.openGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Open Station',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Internet Radio',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.softDivider, height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildNavItem(
                            context: context,
                            tab: NavigationTab.discover,
                            icon: Icons.explore,
                            label: 'Discover',
                          ),
                          const SizedBox(height: 4),
                          _buildNavItem(
                            context: context,
                            tab: NavigationTab.bookmarks,
                            icon: Icons.favorite,
                            label: 'Bookmarks',
                            badgeCount: bookmarkCount,
                          ),
                          const SizedBox(height: 4),
                          _buildNavItem(
                            context: context,
                            tab: NavigationTab.about,
                            icon: Icons.info_outline,
                            label: 'About & Privacy',
                          ),
                          const Spacer(),
                          // Privacy & Info footer
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Local-first & Private',
                                  style: TextStyle(
                                    color: AppColors.disabledText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'v0.1.0 MVP',
                                  style: TextStyle(
                                    color: AppColors.disabledText,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required NavigationTab tab,
    required IconData icon,
    required String label,
    int? badgeCount,
  }) {
    final isSelected = activeTab == tab;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onTabSelected(tab),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.signalBlue.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? const Border(
                        left: BorderSide(color: AppColors.signalBlue, width: 3),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? AppColors.signalBlue
                        : AppColors.secondaryText,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primaryText
                            : AppColors.secondaryText,
                      ),
                    ),
                  ),
                  if (badgeCount != null && badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.signalBlue
                            : AppColors.raisedSlate,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
