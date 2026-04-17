import 'package:flutter/material.dart';
import 'package:login_flutter/l10n/app_localizations.dart';

class DiscoverTabBar extends StatelessWidget {
  final TabController tabController;

  const DiscoverTabBar({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Align(
      alignment: Alignment.centerLeft,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        labelColor: const Color(0xFF8C52FF),
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: const Color(0xFF8C52FF),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.grey.shade200,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(text: l10n.discoverTabSuggestions),
          Tab(text: l10n.favoritesLabel),
          Tab(text: l10n.recentLabel),
        ],
      ),
    );
  }
}
