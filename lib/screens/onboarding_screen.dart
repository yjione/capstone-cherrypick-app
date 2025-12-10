// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      imageAsset: 'assets/images/onboarding_luggage.png',
      titlePrefix: '여행 짐, 한 번에 정리하는',
      titleHighlight: '체리픽',
      description: '여행별 가방을 나눠 담고\n필요한 짐을 한 화면에서 관리해요.',
    ),
    _OnboardingPageData(
      imageAsset: 'assets/images/onboarding_scan.png',
      titlePrefix: '사진 한 장으로 끝내는',
      titleHighlight: '스캔 정리',
      description:
      '화장품 · 소지품을 스캔하면\n자동으로 아이템을 인식해 목록을 만들어줘요.',
    ),
    _OnboardingPageData(
      imageAsset: 'assets/images/onboarding_rule.png',
      titlePrefix: '항공사마다 다른',
      titleHighlight: '항공 규정 체크',
      description:
      '편명과 좌석 등급만 입력하면\n기내·수하물 규정을 한 번에 비교할 수 있어요.',
    ),
    _OnboardingPageData(
      imageAsset: 'assets/images/onboarding_recommendation.png',
      titlePrefix: '이번 여행에 꼭 필요한',
      titleHighlight: '추천 짐 리스트',
      description:
      '여행지와 기간에 맞춰\n놓치기 쉬운 아이템까지 똑똑하게 추천해줘요.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentIndex == _pages.length - 1) {
      context.go('/initial-trip');
    } else {
      _pageController.animateToPage(
        _currentIndex + 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/initial-trip'),
                child: const Text('건너뛰기'),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (idx) {
                  setState(() => _currentIndex = idx);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // 위: 폰, 아래: 설명 카드 비율
                      final phoneHeight = constraints.maxHeight * 0.55;
                      final infoHeight = constraints.maxHeight * 0.30;

                      return Column(
                        children: [
                          SizedBox(
                            height: phoneHeight,
                            child: Center(
                              child: _PhoneMockCard(page: page),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: infoHeight,
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                width: double.infinity,
                                padding:
                                const EdgeInsets.fromLTRB(20, 20, 20, 24),
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 🔹 제목 가운데 정렬
                                    RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        children: [
                                          TextSpan(text: '${page.titlePrefix} '),
                                          TextSpan(
                                            text: page.titleHighlight,
                                            style:
                                            TextStyle(color: cs.primary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // 본문도 가운데 정렬
                                    Text(
                                      page.description,
                                      textAlign: TextAlign.center,
                                      style: textTheme.bodyMedium?.copyWith(
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: List.generate(
                                        _pages.length,
                                            (i) => AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 200),
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          height: 6,
                                          width: _currentIndex == i ? 18 : 6,
                                          decoration: BoxDecoration(
                                            color: _currentIndex == i
                                                ? cs.primary
                                                : cs.primary.withOpacity(0.15),
                                            borderRadius:
                                            BorderRadius.circular(999),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: _onNextPressed,
                  child: Text(
                    _currentIndex == _pages.length - 1 ? '시작하기' : '다음',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String imageAsset;
  final String titlePrefix;
  final String titleHighlight;
  final String description;

  const _OnboardingPageData({
    required this.imageAsset,
    required this.titlePrefix,
    required this.titleHighlight,
    required this.description,
  });
}

class _PhoneMockCard extends StatelessWidget {
  final _OnboardingPageData page;

  const _PhoneMockCard({required this.page});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final screenWidth = MediaQuery.of(context).size.width;
    final phoneWidth = screenWidth * 0.55;
    final phoneHeight = phoneWidth * 1.9;

    return Container(
      width: phoneWidth,
      height: phoneHeight,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        // 베젤 두께도 약간 줄이기
        padding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            color: Colors.white,
            child: Image.asset(
              page.imageAsset,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: cs.primary.withOpacity(0.05),
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: cs.primary.withOpacity(0.5),
                      size: 48,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}


