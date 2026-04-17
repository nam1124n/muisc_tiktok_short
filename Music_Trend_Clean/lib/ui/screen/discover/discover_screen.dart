import 'package:flutter/material.dart';

import 'package:login_flutter/ui/screen/discover/widgets/discover_app_bar.dart';
import 'package:login_flutter/ui/screen/discover/widgets/discover_tab_bar.dart';
import 'package:login_flutter/ui/screen/discover/tabs/suggestions_tab.dart';
import 'package:login_flutter/ui/screen/discover/tabs/favorites_tab.dart';
import 'package:login_flutter/ui/screen/discover/tabs/recents_tab.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: DiscoverContent(),
    );
  }
}

class DiscoverContent extends StatefulWidget {
  const DiscoverContent({super.key});

  @override
  State<DiscoverContent> createState() => _DiscoverContentState();
}

class _DiscoverContentState extends State<DiscoverContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const DiscoverAppBar(),
          DiscoverTabBar(tabController: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const SuggestionsTab(),
                const FavoritesTab(),
                const RecentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
