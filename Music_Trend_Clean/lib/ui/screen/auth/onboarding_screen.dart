import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/providers/app_launch_provider.dart';
import 'package:login_flutter/l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await ref.read(appLaunchProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final slides = _slidesForLocale(context);
    final isLastPage = _currentPage == slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(_isVietnamese(context) ? 'Bỏ qua' : 'Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: slides.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Icon(
                            slide.icon,
                            size: 52,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (isLastPage) {
                    await _completeOnboarding();
                    return;
                  }

                  await _pageController.nextPage(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                  );
                },
                child: Text(
                  isLastPage
                      ? l10n.getStartedNow
                      : (_isVietnamese(context) ? 'Tiếp tục' : 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_OnboardingSlide> _slidesForLocale(BuildContext context) {
    if (_isVietnamese(context)) {
      return const [
        _OnboardingSlide(
          icon: Icons.auto_awesome_rounded,
          title: 'Bắt đầu nhanh với AI Audio',
          subtitle:
              'Tạo nhạc ngắn từ prompt, nhận nhiều phiên bản và lưu lại những bản bạn thích.',
        ),
        _OnboardingSlide(
          icon: Icons.explore_rounded,
          title: 'Khám phá theo năm và xu hướng',
          subtitle:
              'Nghe lại những giai điệu nổi bật, top trending tuần và danh sách gợi ý dành cho bạn.',
        ),
        _OnboardingSlide(
          icon: Icons.library_music_rounded,
          title: 'Quản lý thư viện dễ dàng',
          subtitle:
              'Theo dõi My Audios, playlist và hồ sơ cá nhân trong một flow gọn gàng.',
        ),
      ];
    }

    return const [
      _OnboardingSlide(
        icon: Icons.auto_awesome_rounded,
        title: 'Create AI audio in seconds',
        subtitle:
            'Turn prompts into short music ideas, compare multiple versions, and keep the ones you love.',
      ),
      _OnboardingSlide(
        icon: Icons.explore_rounded,
        title: 'Discover trends and music by year',
        subtitle:
            'Revisit standout tracks, weekly trending songs, and personalized suggestions in one place.',
      ),
      _OnboardingSlide(
        icon: Icons.library_music_rounded,
        title: 'Keep your library organized',
        subtitle:
            'Manage My Audios, playlists, and your profile through a clean and focused experience.',
      ),
    ];
  }

  bool _isVietnamese(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'vi';
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}
