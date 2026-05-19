import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/providers/session_provider.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/admin/admin_analytics_screen.dart';
import 'package:login_flutter/ui/screen/admin/admin_dashboard_screen.dart';
import 'package:login_flutter/ui/screen/admin/admin_generated_audio_dashboard_screen.dart';

enum AdminWebSection { songs, analytics, aiAudio }

const _homeRouteName = '/';

class AdminWebShell extends ConsumerStatefulWidget {
  const AdminWebShell({super.key});

  @override
  ConsumerState<AdminWebShell> createState() => _AdminWebShellState();
}

class _AdminWebShellState extends ConsumerState<AdminWebShell> {
  AdminWebSection _currentSection = AdminWebSection.songs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessionState = ref.watch(sessionProvider);
    final currentTitle = switch (_currentSection) {
      AdminWebSection.songs => l10n.adminPanelTitle,
      AdminWebSection.analytics => l10n.adminAnalyticsTitle,
      AdminWebSection.aiAudio => 'Quản lý Nhạc AI (Suno)',
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: Row(
          children: [
            _AdminSidebar(
              currentSection: _currentSection,
              onSectionSelected: (section) {
                if (_currentSection == section) {
                  return;
                }

                setState(() {
                  _currentSection = section;
                });
              },
            ),
            Expanded(
              child: Column(
                children: [
                  _AdminTopBar(
                    title: currentTitle,
                    email: sessionState.email,
                    onOpenApp: () {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(_homeRouteName);
                    },
                    onSignOut: () {
                      ref.read(sessionProvider.notifier).signOut();
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: switch (_currentSection) {
                            AdminWebSection.songs => const AdminDashboardScreen(
                              embedded: true,
                            ),
                            AdminWebSection.analytics =>
                              const AdminAnalyticsScreen(),
                            AdminWebSection.aiAudio =>
                              const AdminGeneratedAudioDashboardScreen(
                                embedded: true,
                              ),
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.currentSection,
    required this.onSectionSelected,
  });

  final AdminWebSection currentSection;
  final ValueChanged<AdminWebSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: 264,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF181622),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(8, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFF8C52FF),
            child: Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.adminWorkspaceTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.adminWebOnlyMessage,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          _AdminSidebarItem(
            label: l10n.adminSongsSectionLabel,
            icon: Icons.library_music_outlined,
            selected: currentSection == AdminWebSection.songs,
            onTap: () => onSectionSelected(AdminWebSection.songs),
          ),
          const SizedBox(height: 10),
          _AdminSidebarItem(
            label: l10n.adminAnalyticsSectionLabel,
            icon: Icons.bar_chart_rounded,
            selected: currentSection == AdminWebSection.analytics,
            onTap: () => onSectionSelected(AdminWebSection.analytics),
          ),
          const SizedBox(height: 10),
          _AdminSidebarItem(
            label: 'Nhạc AI',
            icon: Icons.smart_toy_outlined,
            selected: currentSection == AdminWebSection.aiAudio,
            onTap: () => onSectionSelected(AdminWebSection.aiAudio),
          ),
          const Spacer(),
          Text(
            l10n.adminOpenAppLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSidebarItem extends StatelessWidget {
  const _AdminSidebarItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected
                ? const Color(0xFF8C52FF)
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.title,
    required this.email,
    required this.onOpenApp,
    required this.onSignOut,
  });

  final String? email;
  final String title;
  final VoidCallback onOpenApp;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEDEDED))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D1C24),
                  ),
                ),
                if ((email ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email!,
                    style: const TextStyle(
                      color: Color(0xFF6B6780),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onOpenApp,
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(l10n.adminOpenAppLabel),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}
