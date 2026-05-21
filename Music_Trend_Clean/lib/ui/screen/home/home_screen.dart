import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/create_audio/create_audio_screen.dart';
import 'package:login_flutter/ui/screen/discover/discover_screen.dart';
import 'package:login_flutter/ui/screen/discover/widgets/custom_bottom_nav.dart';
import 'package:login_flutter/ui/screen/feed/feed_screen.dart';
import 'package:login_flutter/ui/screen/my_audios/my_audios_screen.dart';
import 'package:login_flutter/ui/screen/discover/widgets/mini_player.dart';
import 'package:login_flutter/ui/screen/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const DiscoverContent(),
          const FeedScreen(),
          const MyAudiosScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _HomeBottomBar(
        currentIndex: _currentIndex,
        onTabChanged: _onTabChanged,
      ),
    );
  }
}

class _HomeBottomBar extends ConsumerWidget {
  const _HomeBottomBar({
    required this.currentIndex,
    required this.onTabChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCurrentSong = ref.watch(
      audioPlayerNotifierProvider.select((state) => state.currentSong != null),
    );
    final isFeedTab = currentIndex == 1;
    final showMiniPlayer = hasCurrentSong && !isFeedTab;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final isTablet = screenWidth >= 700;
    final createButtonSize = isFeedTab
        ? (isTablet ? 54.0 : 48.0)
        : isTablet
        ? 60.0
        : (isCompact ? 52.0 : 56.0);
    final navHeight = isFeedTab
        ? (isTablet ? 66.0 : 58.0)
        : isTablet
        ? 76.0
        : (isCompact ? 68.0 : 72.0);
    final navTopOffset =
        createButtonSize / 2 - (isFeedTab ? 7.0 : (isCompact ? 8.0 : 9.0));
    final barHeight = navHeight + navTopOffset;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMiniPlayer)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: MiniPlayer(),
          ),
        if (showMiniPlayer) const SizedBox(height: 8),
        Container(
          color: isFeedTab ? Colors.black : Colors.white,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: barHeight,
              child: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: navTopOffset,
                    child: CustomBottomNav(
                      currentIndex: currentIndex,
                      onTap: onTabChanged,
                      height: navHeight,
                      isDark: isFeedTab,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: _CreateButton(
                      size: createButtonSize,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateAudioScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onTap, required this.size});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.57;
    final outerPadding = size < 56 ? 3.0 : 4.0;

    return Container(
      padding: EdgeInsets.all(outerPadding),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF8C52FF),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: Icon(Icons.add, color: Colors.white, size: iconSize),
            ),
          ),
        ),
      ),
    );
  }
}
