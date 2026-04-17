import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/admin/admin_dashboard_screen.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_provider.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_state.dart';
import 'package:login_flutter/ui/screen/search/search_screen.dart';

class DiscoverAppBar extends ConsumerWidget {
  const DiscoverAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authNotifierProvider);
    final isAdmin =
        authState is AuthSuccess && authState.user.email == 'admin@gmail.com';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8DEFF),
                ),
                child: const Center(
                  child: Icon(Icons.graphic_eq, color: Color(0xFF8C52FF)),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                l10n.musicDiscoveryTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (isAdmin)
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminDashboardScreen(),
                    ),
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF8C52FF),
                      border: Border.all(color: Colors.transparent),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              if (isAdmin) const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(
                  Icons.notifications_none,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Material(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      l10n.discoverSearchHint,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
