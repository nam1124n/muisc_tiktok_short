import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/profile/providers/profile_provider.dart';
import 'package:login_flutter/ui/screen/profile/providers/profile_state.dart';
import 'package:login_flutter/ui/screen/profile/widgets/profile_actions.dart';
import 'package:login_flutter/ui/screen/profile/widgets/profile_header.dart';
import 'package:login_flutter/ui/screen/profile/widgets/profile_info.dart';
import 'package:login_flutter/ui/screen/profile/widgets/profile_stats.dart';
import 'package:login_flutter/ui/screen/auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _background = Color(0xFFF7F3FB);
  static const Color _primary = Color(0xFFA066FF);
  static const Color _secondary = Color(0xFFCDAEFF);
  static const Color _textPrimary = Color(0xFF20202B);
  static const Color _textMuted = Color(0xFF8E889C);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: _background, body: ProfileContent());
  }
}

class ProfileContent extends ConsumerWidget {
  const ProfileContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileNotifierProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9F7FD), Color(0xFFF3EDF9)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: _buildBody(context, state),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProfileState state) {
    final l10n = AppLocalizations.of(context)!;

    if (state is ProfileLoading || state is ProfileInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ProfileError) {
      final isAuthError =
          state.message.toLowerCase().contains('đăng nhập') ||
          state.message.toLowerCase().contains('login') ||
          state.message.toLowerCase().contains('auth');

      if (isAuthError) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ProfileScreen._primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_off_rounded,
                  size: 64,
                  color: ProfileScreen._primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Chưa đăng nhập',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: ProfileScreen._textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vui lòng đăng nhập để xem và tùy chỉnh hồ sơ cá nhân của bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: ProfileScreen._textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProfileScreen._primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Đăng nhập ngay',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
      return Center(child: Text('${l10n.errorLabel}: ${state.message}'));
    }

    if (state is ProfileLoaded) {
      final profile = state.profile;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ProfileHeader(textPrimary: ProfileScreen._textPrimary),
            const SizedBox(height: 18),
            ProfileInfo(
              profile: profile,
              primaryColor: ProfileScreen._primary,
              textPrimary: ProfileScreen._textPrimary,
              textMuted: ProfileScreen._textMuted,
            ),
            const SizedBox(height: 24),
            ProfileStats(
              profile: profile,
              textPrimary: ProfileScreen._textPrimary,
              textMuted: ProfileScreen._textMuted,
            ),
            const SizedBox(height: 22),
            ProfileActions(
              profile: profile,
              primaryColor: ProfileScreen._primary,
              textPrimary: ProfileScreen._textPrimary,
            ),
            const SizedBox(height: 24),
            const _LibraryTabs(),
            const SizedBox(height: 18),
            const _FeaturedPlaylistCard(),
            const SizedBox(height: 16),
            const _SecondaryPlaylists(),
            const SizedBox(height: 18),
            _CreatePlaylistButton(onPressed: () {}),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _LibraryTabs extends StatelessWidget {
  const _LibraryTabs();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LibraryTabItem(
              label: l10n.playlistsLabel,
              icon: Icons.grid_view_rounded,
              isActive: true,
            ),
          ),
          Expanded(
            child: _LibraryTabItem(
              label: l10n.recentLabel,
              icon: Icons.schedule_rounded,
            ),
          ),
          Expanded(
            child: _LibraryTabItem(
              label: l10n.favoritesLabel,
              icon: Icons.favorite_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryTabItem extends StatelessWidget {
  const _LibraryTabItem({
    required this.label,
    required this.icon,
    this.isActive = false,
  });

  final String label;
  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color foreground = isActive
        ? ProfileScreen._primary
        : ProfileScreen._textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Icon(icon, color: foreground, size: 18),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              letterSpacing: 1.0,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedPlaylistCard extends StatelessWidget {
  const _FeaturedPlaylistCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 162,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3F0E6), Color(0xFFB1A99D)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(
              left: -18,
              top: -26,
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
            ),
            Positioned(
              left: 28,
              top: 28,
              child: Text(
                'PLANT',
                style: TextStyle(
                  color: ProfileScreen._primary.withValues(alpha: 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const Positioned(left: 74, top: 22, child: _LeafArt()),
            Positioned(
              right: 20,
              top: -8,
              child: Transform.rotate(
                angle: -math.pi / 7,
                child: Container(
                  width: 82,
                  height: 132,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(48),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF6C9A9), Color(0xFFEAA46E)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 66,
              top: 34,
              child: Transform.rotate(
                angle: math.pi / 9,
                child: Container(
                  width: 38,
                  height: 74,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFDEC6), Color(0xFFF2B78A)],
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 22,
              bottom: 34,
              child: Text(
                'Midnight Echoes 2024',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Positioned(
              left: 22,
              bottom: 16,
              child: Text(
                l10n.trackCount(42),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 16,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.3),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeafArt extends StatelessWidget {
  const _LeafArt();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -math.pi / 9,
            child: Container(
              width: 26,
              height: 78,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF466F5E), Color(0xFF173B2D)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 26,
            top: 22,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 26,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF4B7866), Color(0xFF294F3E)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 24,
            top: 18,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 26,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF618E79), Color(0xFF244534)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 10,
            child: Transform.rotate(
              angle: -math.pi / 3.3,
              child: Container(
                width: 26,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF5C8975), Color(0xFF204132)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 12,
            child: Transform.rotate(
              angle: math.pi / 3.4,
              child: Container(
                width: 26,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF719983), Color(0xFF264837)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryPlaylists extends StatelessWidget {
  const _SecondaryPlaylists();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 330;
        final Widget first = const _DarkFocusCard();
        final Widget second = const _VinylCard();

        if (compact) {
          return Column(children: [first, const SizedBox(height: 14), second]);
        }

        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 14),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _DarkFocusCard extends StatelessWidget {
  const _DarkFocusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 136,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1E22), Color(0xFF09090C)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              left: -14,
              top: -20,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: 18,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.2,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 18,
              child: Text(
                'Deep Focus',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.96),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VinylCard extends StatelessWidget {
  const _VinylCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 136,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B5B5F), Color(0xFF2D2D31)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            const Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: _VinylDisc(),
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 18,
              child: Text(
                'Jazz Vibes',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.94),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VinylDisc extends StatelessWidget {
  const _VinylDisc();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF444448), Color(0xFF111114)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.1,
            ),
          ),
          child: Center(
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF1E8D9),
              ),
              alignment: Alignment.center,
              child: const Text(
                'VIB',
                style: TextStyle(
                  color: Color(0xFF23232B),
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreatePlaylistButton extends StatelessWidget {
  const _CreatePlaylistButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ProfileScreen._secondary.withValues(alpha: 0.32),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ProfileScreen._primary,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.createNewPlaylist.toUpperCase(),
                style: TextStyle(
                  color: ProfileScreen._textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
