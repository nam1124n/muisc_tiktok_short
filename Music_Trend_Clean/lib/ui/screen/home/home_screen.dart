import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/create_audio/create_audio_screen.dart';
import 'package:login_flutter/ui/screen/discover/discover_screen.dart';
import 'package:login_flutter/ui/screen/discover/widgets/custom_bottom_nav.dart';
import 'package:login_flutter/ui/screen/genre/genre_screen.dart';
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
          const GenreScreen(),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasCurrentSong)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: MiniPlayer(),
          ),
        if (hasCurrentSong) const SizedBox(height: 8),
        Container(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 84,
              child: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: 19,
                    child: CustomBottomNav(
                      currentIndex: currentIndex,
                      onTap: onTabChanged,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: _CreateButton(
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
  const _CreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF8C52FF),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Center(
              child: Icon(Icons.add, color: Colors.white, size: 32),
            ),
          ),
        ),
      ),
    );
  }
}
