import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'banner_detail_screen.dart';
import 'brand.dart';
import 'data/analytics_service.dart';
import 'data/content_safety.dart';
import 'data/in_memory_question_repository.dart';
import 'data/question_repository.dart';
import 'data/supabase_question_repository.dart';
import 'models/home_banner.dart';
import 'models/question.dart';
import 'onboarding.dart';
import 'question_share_sheet.dart';
import 'widgets/home_banner_carousel.dart';

const categories = [
  'الكل',
  'البنوك والتحويلات',
  'السفر والتأشيرات',
  'المغتربين',
  'السيارات',
  'السكن',
  'الصحة',
  'التعليم',
  'المعاملات الحكومية',
  'التسوق والأسعار',
  'الاتصالات والإنترنت',
  'الشحن',
  'الوظائف',
  'الخدمات',
  'أخرى',
];

const reportReasons = {
  'abuse': 'إساءة أو تنمر',
  'misleading': 'معلومات مضللة',
  'spam': 'إعلان أو Spam',
  'inappropriate': 'محتوى غير مناسب',
  'other': 'أخرى',
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const rawUrl = String.fromEnvironment('SUPABASE_URL');
  final url = normalizeSupabaseUrl(rawUrl);
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isNotEmpty && anonKey.isNotEmpty) {
    await Supabase.initialize(url: url, publishableKey: anonKey);
    AnalyticsService.instance.configure(Supabase.instance.client);
    unawaited(AnalyticsService.instance.track('app_open'));
  }
  final repository = url.isNotEmpty && anonKey.isNotEmpty
      ? SupabaseQuestionRepository(Supabase.instance.client)
      : InMemoryQuestionRepository();
  final showOnboarding = !(await isOnboardingCompleted());
  runApp(
    MenoApp(
      repository: repository,
      showOnboarding: showOnboarding,
      showSplash: true,
    ),
  );
}

String normalizeSupabaseUrl(String value) {
  var url = value.trim();
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  if (url.endsWith('/rest/v1')) {
    url = url.substring(0, url.length - '/rest/v1'.length);
  }
  return url;
}

class MenoApp extends StatelessWidget {
  const MenoApp({
    super.key,
    required this.repository,
    this.showOnboarding = false,
    this.showSplash = false,
  });

  final QuestionRepository repository;
  final bool showOnboarding;
  final bool showSplash;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Meno',
        theme: ThemeData(
          fontFamily: 'Almarai',
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryBlack,
            primary: primaryBlack,
            secondary: warmGold,
            surface: Colors.white,
          ),
          scaffoldBackgroundColor: surface,
          useMaterial3: true,
          textTheme: const TextTheme(
            headlineSmall: TextStyle(
              fontSize: 24,
              height: 1.4,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
            titleLarge: TextStyle(
              fontSize: 19,
              height: 1.5,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
            bodyLarge: TextStyle(fontSize: 16, height: 1.7, color: ink),
            bodyMedium: TextStyle(fontSize: 14, height: 1.6, color: muted),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            counterStyle: const TextStyle(
              color: muted,
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: darkGold, width: 1.5),
            ),
          ),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: primaryBlack,
            behavior: SnackBarBehavior.floating,
          ),
        ),
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: SplashGate(
          enabled: showSplash,
          child: OnboardingGate(
            showInitially: showOnboarding,
            home: HomeShell(repository: repository),
          ),
        ),
      );
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool complete = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) {
      complete = true;
    } else {
      Timer(const Duration(milliseconds: 1100), () {
        if (mounted) setState(() => complete = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      complete ? widget.child : const MenoSplashScreen();
}

class MenoSplashScreen extends StatelessWidget {
  const MenoSplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        key: Key('meno-splash'),
        backgroundColor: primaryBlack,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MenoMark(size: 112),
                SizedBox(height: 22),
                Text(
                  'Meno',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'اسأل زول جرّب',
                  style: TextStyle(
                    color: warmBeige,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

enum _MenuAction { about, privacy, contact }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.repository});
  final QuestionRepository repository;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  String search = '';
  String category = 'الكل';
  String searchCategory = 'الكل';
  final searchController = TextEditingController();
  Timer? searchDebounce;
  late Future<List<Question>> questions;
  late Future<List<Question>> searchResults;
  late Future<List<HomeBanner>> banners;
  final myQuestionsKey = GlobalKey<_MyQuestionsScreenState>();

  @override
  void initState() {
    super.initState();
    questions = widget.repository.approvedQuestions();
    banners = widget.repository.activeBanners();
    searchResults = widget.repository.searchApprovedQuestions(
      query: '',
      category: searchCategory,
    );
  }

  @override
  void dispose() {
    searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void refresh() => setState(() {
        questions = widget.repository.approvedQuestions();
        banners = widget.repository.activeBanners();
        searchResults = widget.repository.searchApprovedQuestions(
          query: search,
          category: searchCategory,
        );
      });

  void runSearch({bool track = false}) {
    searchDebounce?.cancel();
    searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        searchResults = widget.repository.searchApprovedQuestions(
          query: search,
          category: searchCategory,
        );
      });
      if (track && search.trim().isNotEmpty) {
        unawaited(AnalyticsService.instance.track('search'));
      }
    });
  }

  void clearSearch() {
    searchDebounce?.cancel();
    searchController.clear();
    setState(() {
      search = '';
      searchCategory = 'الكل';
      searchResults = widget.repository.searchApprovedQuestions(
        query: '',
        category: 'الكل',
      );
    });
  }

  Future<void> openAsk() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AskQuestionScreen(repository: widget.repository),
      ),
    );
    if (!mounted) return;
    if (submitted == true) {
      await showDialog<void>(
        context: context,
        builder: (context) => const _SubmissionDialog(),
      );
    }
  }

  Future<void> openBanner(HomeBanner banner) async {
    if (banner.targetType == HomeBannerTargetType.internalPage) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => BannerDetailScreen(banner: banner)),
      );
      return;
    }
    if (banner.targetType != HomeBannerTargetType.externalUrl ||
        banner.targetUrl == null) {
      return;
    }
    final uri = Uri.tryParse(banner.targetUrl!);
    if (uri == null || uri.scheme != 'https') return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الرابط الخارجي.')),
      );
    }
  }

  Future<void> handleMenu(_MenuAction action) async {
    switch (action) {
      case _MenuAction.about:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => OnboardingScreen(
              onDone: () async => Navigator.of(context).pop(),
            ),
          ),
        );
        return;
      case _MenuAction.privacy:
        await launchUrl(
          Uri.parse('https://3bdulra7maaan.github.io/meno-app/privacy.html'),
          mode: LaunchMode.externalApplication,
        );
        return;
      case _MenuAction.contact:
        await launchUrl(
          Uri.parse('mailto:support.meno.app@gmail.com'),
          mode: LaunchMode.externalApplication,
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _home(),
      _search(),
      MyQuestionsScreen(
        key: myQuestionsKey,
        repository: widget.repository,
        embedded: true,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 62,
        titleSpacing: 18,
        title: Row(
          textDirection: TextDirection.ltr,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const MenoWordmark(height: 34),
            PopupMenuButton<_MenuAction>(
              key: const Key('profile-menu'),
              tooltip: 'القائمة',
              icon: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFF2EDE5),
                child: Icon(Icons.person_outline_rounded, color: primaryBlack),
              ),
              onSelected: handleMenu,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _MenuAction.about,
                  child: Text('عن Meno'),
                ),
                PopupMenuItem(
                  value: _MenuAction.privacy,
                  child: Text('سياسة الخصوصية'),
                ),
                PopupMenuItem(
                  value: _MenuAction.contact,
                  child: Text('تواصل معنا'),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        height: 70,
        backgroundColor: Colors.white,
        selectedIndex: index == 0 ? 0 : (index == 1 ? 1 : 3),
        indicatorColor: warmGold.withValues(alpha: .45),
        onDestinationSelected: (value) {
          if (value == 2) {
            openAsk();
          } else {
            setState(() => index = value == 0 ? 0 : (value == 1 ? 1 : 2));
            if (value == 3) myQuestionsKey.currentState?.refresh();
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'البحث',
          ),
          NavigationDestination(
            icon: Container(
              width: 42,
              height: 34,
              decoration: BoxDecoration(
                color: warmGold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_rounded, color: primaryBlack),
            ),
            label: 'اسأل',
          ),
          const NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt_rounded),
            label: 'أسئلتي',
          ),
        ],
      ),
    );
  }

  Widget _home() => RefreshIndicator(
        onRefresh: () async => refresh(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            Container(
              decoration: const BoxDecoration(
                color: primaryBlack,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اسأل زول جرّب',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'إجابات قريبة منك، من ناس عندهم تجربة حقيقية.',
                    style: TextStyle(color: Color(0xFFF2E9DA), fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => setState(() => index = 1),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search_rounded, color: primaryBlack),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'فتّش في تجارب الناس...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: muted, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FutureBuilder<List<HomeBanner>>(
              future: banners,
              builder: (context, snapshot) => HomeBannerCarousel(
                banners: snapshot.data ?? const [],
                onBannerTap: openBanner,
              ),
            ),
            _categoryList(),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 6, 18, 2),
              child: Text(
                'أسئلة من المجتمع',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
            ),
            _questionList(onReset: () => setState(() => category = 'الكل')),
          ],
        ),
      );

  Widget _search() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: Column(
          children: [
            TextField(
              key: const Key('search-field'),
              controller: searchController,
              autofocus: false,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                search = value;
                runSearch();
              },
              onSubmitted: (value) {
                search = value;
                runSearch(track: true);
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'فتّش في الأسئلة...',
                suffixIcon: search.isEmpty
                    ? null
                    : IconButton(
                        key: const Key('clear-search'),
                        onPressed: clearSearch,
                        tooltip: 'مسح البحث',
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            _searchCategoryList(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _questionList(
                    source: searchResults,
                    selectedCategory: 'الكل',
                    query: '',
                    onReset: clearSearch,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _searchCategoryList() => _categoryChips(
        selectedCategory: searchCategory,
        onSelected: (value) {
          setState(() => searchCategory = value);
          runSearch();
        },
      );

  Widget _categoryList() => _categoryChips(
        selectedCategory: category,
        onSelected: (value) => setState(() => category = value),
      );

  Widget _categoryChips({
    required String selectedCategory,
    required ValueChanged<String> onSelected,
  }) =>
      SizedBox(
        height: 52,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final selected = selectedCategory == categories[i];
            return ChoiceChip(
              label: Text(categories[i]),
              selected: selected,
              showCheckmark: false,
              backgroundColor: Colors.white,
              selectedColor: warmGold,
              side: BorderSide(color: selected ? darkGold : border),
              labelStyle: const TextStyle(
                color: primaryBlack,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              onSelected: (_) {
                onSelected(categories[i]);
                unawaited(
                  AnalyticsService.instance.track(
                    'category_selected',
                    category: categories[i],
                  ),
                );
              },
            );
          },
        ),
      );

  Widget _questionList({
    Future<List<Question>>? source,
    String? selectedCategory,
    String? query,
    VoidCallback? onReset,
  }) =>
      FutureBuilder<List<Question>>(
        future: source ?? questions,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              key: const Key('error-state'),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 42),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: warmBeige.withValues(alpha: .52),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      size: 34,
                      color: primaryBlack,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'الاتصال ما زبط',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'اتأكد من الإنترنت وحاول تاني. أسئلتك وتجاربك ما حتضيع.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, height: 1.6),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('حاول تاني'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const _LoadingFeed();
          }
          final filtered = snapshot.data!.where((q) {
            final activeCategory = selectedCategory ?? category;
            final activeQuery = query ?? '';
            final matchesCategory =
                activeCategory == 'الكل' || q.category == activeCategory;
            final term = activeQuery.trim().toLowerCase();
            return matchesCategory &&
                (term.isEmpty ||
                    q.title.toLowerCase().contains(term) ||
                    q.body.toLowerCase().contains(term));
          }).toList();
          if (filtered.isEmpty) {
            return Padding(
              key: const Key('empty-state'),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 42),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2EDE5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_off_rounded,
                      size: 34,
                      color: primaryBlack,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'ما لقينا نتيجة مطابقة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'جرّب كلمة أقصر أو اختار «الكل».',
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: onReset ?? clearSearch,
                    child: const Text('امسح البحث'),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: filtered
                .map(
                  (question) => QuestionCard(
                    question: question,
                    onTap: () {
                      unawaited(
                        AnalyticsService.instance.track(
                          'question_view',
                          category: question.category,
                          entityId: question.id,
                        ),
                      );
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => QuestionDetailsScreen(
                                question: question,
                                repository: widget.repository,
                              ),
                            ),
                          )
                          .then((_) => refresh());
                    },
                  ),
                )
                .toList(),
          );
        },
      );
}

class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key, required this.question, required this.onTap});
  final Question question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.fromLTRB(14, 5, 14, 5),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5EBDD),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          question.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: primaryBlack,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Spacer(),
                    Text(
                      _timeAgo(question.createdAt),
                      style:
                          const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(question.title,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  question.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 9),
                const Divider(height: 1, color: border),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFF2EDE5),
                      child: Text(
                        question.author.characters.first,
                        style: const TextStyle(
                          color: primaryBlack,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.author,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ink,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      answerCountLabel(question.answers.length),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class MyQuestionsScreen extends StatefulWidget {
  const MyQuestionsScreen({
    super.key,
    required this.repository,
    this.embedded = false,
  });
  final QuestionRepository repository;
  final bool embedded;

  @override
  State<MyQuestionsScreen> createState() => _MyQuestionsScreenState();
}

class _MyQuestionsScreenState extends State<MyQuestionsScreen> {
  late Future<List<Question>> questions;

  @override
  void initState() {
    super.initState();
    questions = widget.repository.currentUserQuestions();
  }

  Future<void> refresh() async {
    final next = widget.repository.currentUserQuestions();
    setState(() => questions = next);
    await next;
  }

  void openQuestion(Question question) {
    if (question.status != QuestionStatus.approved) return;
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute(
            builder: (_) => QuestionDetailsScreen(
              question: question,
              repository: widget.repository,
            ),
          ),
        )
        .then((_) => refresh());
  }

  @override
  Widget build(BuildContext context) {
    final content = FutureBuilder<List<Question>>(
      future: questions,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 42),
                const SizedBox(height: 12),
                const Text('ما قدرنا نحمّل أسئلتك.'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: refresh,
                  child: const Text('حاول تاني'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) return const _LoadingFeed();
        final items = snapshot.data!;
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 150),
                Icon(Icons.help_outline_rounded, size: 48),
                SizedBox(height: 12),
                Text('ما عندك أسئلة مرسلة لسه.', textAlign: TextAlign.center),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final question = items[index];
              return _MyQuestionCard(
                question: question,
                onTap: () => openQuestion(question),
              );
            },
          ),
        );
      },
    );
    if (widget.embedded) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'أسئلتي',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Expanded(child: content),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('أسئلتي'),
        backgroundColor: Colors.white,
      ),
      body: content,
    );
  }
}

class _MyQuestionCard extends StatelessWidget {
  const _MyQuestionCard({required this.question, required this.onTap});
  final Question question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: InkWell(
          key: Key('my-question-${question.id}'),
          onTap: question.status == QuestionStatus.approved ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EBDD),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        questionStatusLabel(question.status),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _timeAgo(question.createdAt),
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(question.title,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  question.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, height: 1.5),
                ),
                if (question.status == QuestionStatus.approved) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'افتح السؤال',
                    style:
                        TextStyle(color: darkGold, fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({super.key, required this.repository});
  final QuestionRepository repository;

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final body = TextEditingController();
  String category = categories[1];
  bool anonymous = false;
  bool saving = false;

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await widget.repository.submitQuestion(
        title: title.text.trim(),
        body: body.text.trim(),
        category: category,
        anonymous: anonymous,
      );
      unawaited(
        AnalyticsService.instance.track(
          'question_submitted',
          category: category,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on BlockedContentException {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(blockedContentMessage)));
    } catch (_) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ما قدرنا نرسل السؤال. اتأكد من الإنترنت وحاول تاني.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'سؤال جديد',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          backgroundColor: Colors.white,
        ),
        body: Form(
          key: formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: warmBeige.withValues(alpha: .28),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, color: primaryBlack),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'خلي سؤالك واضح ومحدد',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: primaryBlack,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'قول للناس شنو جرّبت وشنو بالضبط الداير تعرفو.',
                            style: TextStyle(
                              color: Color(0xFF67583F),
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _FieldLabel(number: '١', title: 'اكتب السؤال'),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('question-title-field'),
                controller: title,
                maxLength: 120,
                textInputAction: TextInputAction.next,
                decoration:
                    const InputDecoration(hintText: 'شنو الداير تعرفو؟'),
                validator: (v) => v == null || v.trim().length < 8
                    ? 'اكتب سؤال أوضح — على الأقل ٨ حروف'
                    : null,
              ),
              const SizedBox(height: 12),
              const _FieldLabel(number: '٢', title: 'أضف التفاصيل'),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('question-body-field'),
                controller: body,
                minLines: 4,
                maxLines: 7,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'أشرح الظروف المهمة عشان الناس يجاوبوك بدقة...',
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'أضف شوية تفاصيل تساعد الناس'
                    : null,
              ),
              const SizedBox(height: 12),
              const _FieldLabel(number: '٣', title: 'اختار التصنيف'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'التصنيف'),
                items: categories
                    .skip(1)
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) => setState(() => category = value!),
              ),
              const SizedBox(height: 14),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: border),
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: SwitchListTile(
                  minTileHeight: 72,
                  value: anonymous,
                  activeThumbColor: darkGold,
                  secondary: const Icon(
                    Icons.visibility_off_outlined,
                    color: primaryBlack,
                  ),
                  title: const Text(
                    'اسأل كمجهول',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('اسمك ما حيظهر مع السؤال'),
                  onChanged: (value) => setState(() => anonymous = value),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('submit-question-button'),
                onPressed: saving ? null : submit,
                style: FilledButton.styleFrom(
                  backgroundColor: warmGold,
                  foregroundColor: primaryBlack,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  saving ? 'جاري الإرسال...' : 'أرسل للمراجعة',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'كل الأسئلة بتتراجع قبل ما تظهر للناس.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
        ),
      );
}

class QuestionDetailsScreen extends StatefulWidget {
  const QuestionDetailsScreen({
    super.key,
    required this.question,
    required this.repository,
  });
  final Question question;
  final QuestionRepository repository;

  @override
  State<QuestionDetailsScreen> createState() => _QuestionDetailsScreenState();
}

class _QuestionDetailsScreenState extends State<QuestionDetailsScreen> {
  final answer = TextEditingController();

  @override
  void dispose() {
    answer.dispose();
    super.dispose();
  }

  Future<void> addAnswer() async {
    if (answer.text.trim().isEmpty) return;
    try {
      final created = await widget.repository.submitAnswer(
        questionId: widget.question.id,
        body: answer.text.trim(),
      );
      unawaited(
        AnalyticsService.instance.track(
          'answer_submitted',
          category: widget.question.category,
          entityId: widget.question.id,
        ),
      );
      if (!widget.question.answers.any((item) => item.id == created.id)) {
        widget.question.answers.add(created);
      }
      answer.clear();
      if (mounted) setState(() {});
    } on BlockedContentException {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(blockedContentMessage)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ما قدرنا نضيف الإجابة. حاول تاني.')),
      );
    }
  }

  Future<void> reportAnswer(Answer item, String reason) async {
    try {
      final created = await widget.repository.reportAnswer(
        answerId: item.id,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            created
                ? 'وصلنا بلاغك، شكراً لمساعدتك في الحفاظ على المجتمع.'
                : 'سبق وأبلغت عن هذه الإجابة.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ما قدرنا نرسل البلاغ. حاول تاني.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('السؤال'),
          backgroundColor: Colors.white,
          actions: [
            IconButton(
              key: const Key('share-question-action'),
              tooltip: 'شارك السؤال',
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: false,
                isScrollControlled: true,
                builder: (_) => QuestionShareSheet(question: widget.question),
              ),
              icon: const Icon(Icons.ios_share_rounded),
            ),
          ],
        ),
        body: ListView(
          key: const Key('details-list'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EBDD),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            widget.question.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: primaryBlack,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Spacer(),
                      Text(
                        _timeAgo(widget.question.createdAt),
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    widget.question.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.question.body,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: border),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 15,
                        backgroundColor: Color(0xFFF2EDE5),
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 17,
                          color: primaryBlack,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.question.author,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(
                answerCountLabel(widget.question.answers.length),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
            ),
            ...widget.question.answers.map(
              (item) => _AnswerCard(
                answer: item,
                onReport: (reason) => reportAnswer(item, reason),
                onHelpful: () async {
                  try {
                    final result = await widget.repository.toggleHelpful(
                      questionId: widget.question.id,
                      answerId: item.id,
                    );
                    unawaited(
                      AnalyticsService.instance.track(
                        'helpful_vote',
                        category: widget.question.category,
                        entityId: widget.question.id,
                      ),
                    );
                    item.isHelpful = result.isHelpful;
                    item.helpfulCount = result.helpfulCount;
                    if (mounted) setState(() {});
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('ما قدرنا نسجل «أفادني». حاول تاني.'),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: AnimatedPadding(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('answer-field'),
                        controller: answer,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: 'شارك تجربة أو معلومة مفيدة...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      key: const Key('answer-send-button'),
                      onPressed: addAnswer,
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      style:
                          IconButton.styleFrom(backgroundColor: primaryBlack),
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.answer,
    required this.onHelpful,
    required this.onReport,
  });
  final Answer answer;
  final VoidCallback onHelpful;
  final ValueChanged<String> onReport;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.fromLTRB(12, 5, 12, 5),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: primaryBlack,
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      answer.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: secondaryBeige.withValues(alpha: .28),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      answer.answerType,
                      style: const TextStyle(
                        color: primaryBlack,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(answer.body,
                  style: const TextStyle(fontSize: 15, height: 1.6)),
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onHelpful,
                    style: TextButton.styleFrom(
                      foregroundColor:
                          answer.isHelpful ? primaryBlack : Colors.black54,
                      backgroundColor: answer.isHelpful
                          ? warmGold.withValues(alpha: .25)
                          : null,
                    ),
                    icon: Icon(
                      answer.isHelpful
                          ? Icons.thumb_up
                          : Icons.thumb_up_outlined,
                      size: 18,
                    ),
                    label: Text('أفادني  ${answer.helpfulCount}'),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    key: Key('report-answer-${answer.id}'),
                    tooltip: 'إبلاغ',
                    onSelected: onReport,
                    itemBuilder: (context) => reportReasons.entries
                        .map(
                          (entry) => PopupMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 18,
                            color: Colors.black54,
                          ),
                          SizedBox(width: 5),
                          Text('إبلاغ',
                              style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

String _timeAgo(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 60) return 'منذ ${difference.inMinutes} د';
  if (difference.inHours < 24) return 'منذ ${difference.inHours} س';
  return 'منذ ${difference.inDays} يوم';
}

String answerCountLabel(int count) {
  if (count == 0) return 'لا توجد إجابات';
  if (count == 1) return 'إجابة واحدة';
  if (count == 2) return 'إجابتان';
  if (count <= 10) return '$count إجابات';
  return '$count إجابة';
}

String questionStatusLabel(QuestionStatus status) => switch (status) {
      QuestionStatus.pending => 'قيد المراجعة',
      QuestionStatus.approved => 'تم النشر',
      QuestionStatus.rejected => 'لم يتم النشر',
    };

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.number, required this.title});
  final String number;
  final String title;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: primaryBlack,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
        ],
      );
}

class _SubmissionDialog extends StatelessWidget {
  const _SubmissionDialog();
  @override
  Widget build(BuildContext context) => AlertDialog(
        icon: Container(
          width: 70,
          height: 70,
          decoration:
              const BoxDecoration(color: warmBeige, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: 38, color: primaryBlack),
        ),
        title: const Text(
          'وصلنا سؤالك',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, color: primaryBlack),
        ),
        content: const Text(
          'تم إرسال سؤالك للمراجعة، ويمكنك متابعة حالته من أسئلتي.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تمام'),
          ),
        ],
      );
}

class _LoadingFeed extends StatelessWidget {
  const _LoadingFeed();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final placeholders = List.generate(
            3,
            (index) => Container(
              height: 155,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryBlack,
                  ),
                ),
              ),
            ),
          );
          return Padding(
            key: const Key('loading-state'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: constraints.hasBoundedHeight
                ? ListView(children: placeholders)
                : Column(children: placeholders),
          );
        },
      );
}
