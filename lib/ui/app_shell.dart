import 'package:flutter/material.dart';
import 'package:open_station/ui/pages/bookmarks_page.dart';
import 'package:open_station/ui/pages/discover_page.dart';
import 'package:open_station/ui/widgets/player_bar.dart';
import 'package:open_station/ui/widgets/sidebar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  NavigationTab _activeTab = NavigationTab.discover;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Upper Desktop Body: Sidebar + Main Content Area
          Expanded(
            child: Row(
              children: [
                Sidebar(
                  activeTab: _activeTab,
                  onTabSelected: (tab) {
                    setState(() => _activeTab = tab);
                  },
                ),
                Expanded(
                  child: IndexedStack(
                    index: _activeTab == NavigationTab.discover ? 0 : 1,
                    children: const [
                      DiscoverPage(),
                      BookmarksPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Player Bar
          const PlayerBar(),
        ],
      ),
    );
  }
}
