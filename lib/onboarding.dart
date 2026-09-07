import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const onboardingCompletedKey = 'meno_onboarding_completed_v1';
const _black = Color(0xFF121212);
const _gold = Color(0xFFD9A752);
const _beige = Color(0xFFE5C495);
const _surface = Color(0xFFFAF9F6);

Future<bool> isOnboardingCompleted() async =>
    (await SharedPreferences.getInstance()).getBool(onboardingCompletedKey) ??
    false;

Future<void> markOnboardingCompleted() async =>
    (await SharedPreferences.getInstance()).setBool(
      onboardingCompletedKey,
      true,
    );

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({
    super.key,
    required this.home,
    required this.showInitially,
  });

  final Widget home;
  final bool showInitially;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late bool completed = !widget.showInitially;

  @override
  Widget build(BuildContext context) => completed
      ? widget.home
      : OnboardingScreen(
          onDone: () async {
            await markOnboardingCompleted();
            if (mounted) setState(() => completed = true);
          },
        );
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final Future<void> Function() onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;

  static const slides = [
    (
      title: 'اسأل زول جرّب',
      body: 'اسأل السودانيين عن تجربة حقيقية.',
      icon: Icons.question_answer_outlined,
    ),
    (
      title: 'شارك تجربتك',
      body: 'جوابك ممكن يوفر على زول زمن وقروش.',
      icon: Icons.volunteer_activism_outlined,
    ),
    (
      title: 'مجتمع أنفع',
      body: 'الأسئلة والإجابات تخضع للمراجعة والإبلاغ للحفاظ على جودة المحتوى.',
      icon: Icons.verified_user_outlined,
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _surface,
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 18, 24, 4),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'Meno',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: _black,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  key: const Key('onboarding-pages'),
                  controller: controller,
                  itemCount: slides.length,
                  onPageChanged: (value) => setState(() => page = value),
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 112,
                            height: 112,
                            decoration: const BoxDecoration(
                              color: _beige,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(slide.icon, size: 50, color: _black),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              color: _black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            slide.body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, height: 1.7),
                          ),
                        ],
                      ),
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
                    width: index == page ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == page ? _gold : _beige,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: FilledButton(
                  key: const Key('onboarding-action'),
                  onPressed: () async {
                    if (page < slides.length - 1) {
                      await controller.nextPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      );
                    } else {
                      await widget.onDone();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: _black,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  child: Text(
                    page == slides.length - 1 ? 'ابدأ مع Meno' : 'التالي',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
