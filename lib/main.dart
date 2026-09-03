import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/in_memory_question_repository.dart';
import 'data/question_repository.dart';
import 'data/supabase_question_repository.dart';
import 'models/question.dart';

const primaryBlack = Color(0xFF121212);
const warmGold = Color(0xFFD9A752);
const darkGold = Color(0xFFC59243);
const warmBeige = Color(0xFFE5C495);
const secondaryBeige = Color(0xFFDEB887);
const surface = Color(0xFFFAF9F6);
const ink = primaryBlack;
const muted = Color(0xFF68635C);
const border = Color(0xFFE8E3DA);

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const rawUrl = String.fromEnvironment('SUPABASE_URL');
  final url = normalizeSupabaseUrl(rawUrl);
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isNotEmpty && anonKey.isNotEmpty) {
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }
  final repository = url.isNotEmpty && anonKey.isNotEmpty
      ? SupabaseQuestionRepository(Supabase.instance.client)
      : InMemoryQuestionRepository();
  runApp(MenoApp(repository: repository));
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
  const MenoApp({super.key, required this.repository});

  final QuestionRepository repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Meno',
        theme: ThemeData(
          fontFamily: 'Almarai',
          colorScheme: ColorScheme.fromSeed(seedColor: primaryBlack, primary: primaryBlack, secondary: warmGold, surface: Colors.white),
          scaffoldBackgroundColor: surface,
          useMaterial3: true,
          textTheme: const TextTheme(
            headlineSmall: TextStyle(fontSize: 24, height: 1.4, fontWeight: FontWeight.w800, color: ink),
            titleLarge: TextStyle(fontSize: 19, height: 1.5, fontWeight: FontWeight.w800, color: ink),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: darkGold, width: 1.5)),
          ),
          snackBarTheme: const SnackBarThemeData(backgroundColor: primaryBlack, behavior: SnackBarBehavior.floating),
        ),
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        home: HomeShell(repository: repository),
      );
}

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
  late Future<List<Question>> questions;

  @override
  void initState() {
    super.initState();
    questions = widget.repository.approvedQuestions();
  }

  void refresh() => setState(() => questions = widget.repository.approvedQuestions());

  Future<void> openAsk() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AskQuestionScreen(repository: widget.repository)),
    );
    if (!mounted) return;
    if (submitted == true) {
      await showDialog<void>(
        context: context,
        builder: (context) => const _SubmissionDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _home(),
      _search(),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 68,
        titleSpacing: 18,
        title: Row(
          textDirection: TextDirection.ltr,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Meno', style: TextStyle(color: primaryBlack, fontWeight: FontWeight.w800, fontSize: 24.5, letterSpacing: -1)),
            FilledButton.icon(
              onPressed: openAsk,
              style: FilledButton.styleFrom(backgroundColor: warmGold, foregroundColor: primaryBlack, minimumSize: const Size(92, 42), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
              icon: const Icon(Icons.add, size: 19),
              label: const Text('اسأل', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        height: 70,
        backgroundColor: Colors.white,
        selectedIndex: index == 0 ? 0 : 2,
        indicatorColor: warmGold.withValues(alpha: .45),
        onDestinationSelected: (value) {
          if (value == 1) {
            openAsk();
          } else {
            setState(() => index = value == 0 ? 0 : 1);
          }
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(
            icon: Container(
              width: 42,
              height: 34,
              decoration: BoxDecoration(color: warmGold, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.add_rounded, color: primaryBlack),
            ),
            label: 'اسأل',
          ),
          const NavigationDestination(icon: Icon(Icons.search), label: 'بحث'),
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
              decoration: const BoxDecoration(color: primaryBlack, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(26), bottomRight: Radius.circular(26))),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اسأل زول جرّب', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  const Text('إجابات قريبة منك، من ناس عندهم تجربة حقيقية.', style: TextStyle(color: Color(0xFFF2E9DA), fontSize: 15)),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => setState(() => index = 1),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: const Row(children: [Icon(Icons.search_rounded, color: primaryBlack), SizedBox(width: 10), Expanded(child: Text('فتّش في تجارب الناس...', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 15)))]),
                    ),
                  ),
                ],
              ),
            ),
            _categoryList(),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 6, 18, 2),
              child: Text('أسئلة من المجتمع', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: ink)),
            ),
            _questionList(),
          ],
        ),
      );

  Widget _search() => Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: Column(
          children: [
            TextField(
              key: const Key('search-field'),
              autofocus: false,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => search = value),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'فتّش في الأسئلة...'),
            ),
            const SizedBox(height: 6),
            _categoryList(),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: 20), child: _questionList())),
          ],
        ),
      );

  Widget _categoryList() => SizedBox(
        height: 52,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final selected = category == categories[i];
            return ChoiceChip(
              label: Text(categories[i]),
              selected: selected,
              showCheckmark: false,
              backgroundColor: Colors.white,
              selectedColor: warmGold,
              side: BorderSide(color: selected ? darkGold : border),
              labelStyle: const TextStyle(color: primaryBlack, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              onSelected: (_) => setState(() => category = categories[i]),
            );
          },
        ),
      );

  Widget _questionList() => FutureBuilder<List<Question>>(
        future: questions,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              key: const Key('error-state'),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 42),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 72, height: 72, decoration: BoxDecoration(color: warmBeige.withValues(alpha: .52), shape: BoxShape.circle), child: const Icon(Icons.wifi_off_rounded, size: 34, color: primaryBlack)),
                  const SizedBox(height: 18),
                  const Text('الاتصال ما زبط', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
                  const SizedBox(height: 7),
                  const Text('اتأكد من الإنترنت وحاول تاني. أسئلتك وتجاربك ما حتضيع.', textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.6)),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(onPressed: refresh, icon: const Icon(Icons.refresh_rounded), label: const Text('حاول تاني')),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const _LoadingFeed();
          }
          final filtered = snapshot.data!.where((q) {
            final matchesCategory = category == 'الكل' || q.category == category;
            final term = search.trim().toLowerCase();
            return matchesCategory && (term.isEmpty || q.title.toLowerCase().contains(term) || q.body.toLowerCase().contains(term));
          }).toList();
          if (filtered.isEmpty) {
            return Padding(
              key: const Key('empty-state'),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 42),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 72, height: 72, decoration: const BoxDecoration(color: Color(0xFFF2EDE5), shape: BoxShape.circle), child: const Icon(Icons.search_off_rounded, size: 34, color: primaryBlack)),
                const SizedBox(height: 18),
                const Text('ما لقينا نتيجة مطابقة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
                const SizedBox(height: 7),
                const Text('جرّب كلمة أقصر أو اختار «الكل».', style: TextStyle(color: muted)),
                const SizedBox(height: 14),
                FilledButton(onPressed: () => setState(() { search = ''; category = 'الكل'; }), child: const Text('امسح البحث')),
              ]),
            );
          }
          return Column(
            children: filtered
                .map((question) => QuestionCard(
                      question: question,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => QuestionDetailsScreen(question: question, repository: widget.repository)),
                      ).then((_) => refresh()),
                    ))
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
        shape: RoundedRectangleBorder(side: const BorderSide(color: border), borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFF5EBDD), borderRadius: BorderRadius.circular(9)), child: Text(question.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: primaryBlack, fontSize: 12, fontWeight: FontWeight.w800)))),
                  const SizedBox(width: 8),
                  const Spacer(),
                  Text(_timeAgo(question.createdAt), style: const TextStyle(color: Colors.black45, fontSize: 12)),
                ]),
                const SizedBox(height: 10),
                Text(question.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(question.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54, height: 1.5)),
                const SizedBox(height: 9),
                const Divider(height: 1, color: border),
                const SizedBox(height: 8),
                Row(children: [
                  CircleAvatar(radius: 14, backgroundColor: const Color(0xFFF2EDE5), child: Text(question.author.characters.first, style: const TextStyle(color: primaryBlack, fontSize: 12, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(question.author, style: const TextStyle(fontWeight: FontWeight.w700, color: ink, fontSize: 13))),
                  const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.black54),
                  const SizedBox(width: 5),
                  Text(answerCountLabel(question.answers.length), style: const TextStyle(color: Colors.black54)),
                ]),
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
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ما قدرنا نرسل السؤال. اتأكد من الإنترنت وحاول تاني.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('سؤال جديد', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.white),
        body: Form(
          key: formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: warmBeige.withValues(alpha: .28), borderRadius: BorderRadius.circular(18)),
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.lightbulb_outline_rounded, color: primaryBlack), SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('خلي سؤالك واضح ومحدد', style: TextStyle(fontWeight: FontWeight.w800, color: primaryBlack, fontSize: 16)),
                    SizedBox(height: 3),
                    Text('قول للناس شنو جرّبت وشنو بالضبط الداير تعرفو.', style: TextStyle(color: Color(0xFF67583F), height: 1.55)),
                  ])),
                ]),
              ),
              const SizedBox(height: 22),
              const _FieldLabel(number: '١', title: 'اكتب السؤال'),
              const SizedBox(height: 8),
              TextFormField(key: const Key('question-title-field'), controller: title, maxLength: 120, textInputAction: TextInputAction.next, decoration: const InputDecoration(hintText: 'شنو الداير تعرفو؟'), validator: (v) => v == null || v.trim().length < 8 ? 'اكتب سؤال أوضح — على الأقل ٨ حروف' : null),
              const SizedBox(height: 12),
              const _FieldLabel(number: '٢', title: 'أضف التفاصيل'),
              const SizedBox(height: 8),
              TextFormField(key: const Key('question-body-field'), controller: body, minLines: 4, maxLines: 7, maxLength: 500, decoration: const InputDecoration(hintText: 'أشرح الظروف المهمة عشان الناس يجاوبوك بدقة...'), validator: (v) => v == null || v.trim().isEmpty ? 'أضف شوية تفاصيل تساعد الناس' : null),
              const SizedBox(height: 12),
              const _FieldLabel(number: '٣', title: 'اختار التصنيف'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'التصنيف'),
                items: categories.skip(1).map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                onChanged: (value) => setState(() => category = value!),
              ),
              const SizedBox(height: 14),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(side: const BorderSide(color: border), borderRadius: BorderRadius.circular(18)),
                clipBehavior: Clip.antiAlias,
                child: SwitchListTile(
                  minTileHeight: 72,
                  value: anonymous,
                  activeThumbColor: darkGold,
                  secondary: const Icon(Icons.visibility_off_outlined, color: primaryBlack),
                  title: const Text('اسأل كمجهول', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('اسمك ما حيظهر مع السؤال'),
                  onChanged: (value) => setState(() => anonymous = value),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('submit-question-button'),
                onPressed: saving ? null : submit,
                style: FilledButton.styleFrom(backgroundColor: warmGold, foregroundColor: primaryBlack, minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(saving ? 'جاري الإرسال...' : 'أرسل للمراجعة', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              const Text('كل الأسئلة بتتراجع قبل ما تظهر للناس.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black45, fontSize: 12)),
            ],
          ),
        ),
      );
}

class QuestionDetailsScreen extends StatefulWidget {
  const QuestionDetailsScreen({super.key, required this.question, required this.repository});
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
      if (!widget.question.answers.any((item) => item.id == created.id)) {
        widget.question.answers.add(created);
      }
      answer.clear();
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ما قدرنا نضيف الإجابة. حاول تاني.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: const Text('السؤال'), backgroundColor: Colors.white),
        body: ListView(
          key: const Key('details-list'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: border), borderRadius: BorderRadius.circular(20)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Flexible(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFF5EBDD), borderRadius: BorderRadius.circular(9)), child: Text(widget.question.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: primaryBlack, fontSize: 12, fontWeight: FontWeight.w800)))), const SizedBox(width: 8), const Spacer(), Text(_timeAgo(widget.question.createdAt), style: const TextStyle(color: muted, fontSize: 12))]),
                const SizedBox(height: 15),
                Text(widget.question.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(widget.question.body, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 16),
                const Divider(color: border),
                Row(children: [const CircleAvatar(radius: 15, backgroundColor: Color(0xFFF2EDE5), child: Icon(Icons.person_outline_rounded, size: 17, color: primaryBlack)), const SizedBox(width: 8), Text(widget.question.author, style: const TextStyle(fontWeight: FontWeight.w700, color: ink))]),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(answerCountLabel(widget.question.answers.length), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: ink)),
            ),
            ...widget.question.answers.map((item) => _AnswerCard(
                  answer: item,
                  onHelpful: () async {
                    try {
                      final result = await widget.repository.toggleHelpful(
                        questionId: widget.question.id,
                        answerId: item.id,
                      );
                      item.isHelpful = result.isHelpful;
                      item.helpfulCount = result.helpfulCount;
                      if (mounted) setState(() {});
                    } catch (_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('ما قدرنا نسجل «أفادني». حاول تاني.')),
                      );
                    }
                  },
                )),
          ],
        ),
        bottomSheet: SafeArea(
          top: false,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
            child: Row(children: [
              Expanded(child: TextField(key: const Key('answer-field'), controller: answer, minLines: 1, maxLines: 4, decoration: const InputDecoration(hintText: 'شارك تجربة أو معلومة مفيدة...'))),
              const SizedBox(width: 8),
              IconButton.filled(key: const Key('answer-send-button'), onPressed: addAnswer, style: IconButton.styleFrom(backgroundColor: primaryBlack), icon: const Icon(Icons.send)),
            ]),
          ),
        ),
      );
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.answer, required this.onHelpful});
  final Answer answer;
  final VoidCallback onHelpful;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.fromLTRB(12, 5, 12, 5),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(side: const BorderSide(color: border), borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const CircleAvatar(radius: 16, backgroundColor: primaryBlack, child: Icon(Icons.person, color: Colors.white, size: 18)),
              const SizedBox(width: 9),
              Expanded(child: Text(answer.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: secondaryBeige.withValues(alpha: .28), borderRadius: BorderRadius.circular(9)), child: Text(answer.answerType, style: const TextStyle(color: primaryBlack, fontSize: 11.5, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 12),
            Text(answer.body, style: const TextStyle(fontSize: 15, height: 1.6)),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onHelpful,
              style: TextButton.styleFrom(foregroundColor: answer.isHelpful ? primaryBlack : Colors.black54, backgroundColor: answer.isHelpful ? warmGold.withValues(alpha: .25) : null),
              icon: Icon(answer.isHelpful ? Icons.thumb_up : Icons.thumb_up_outlined, size: 18),
              label: Text('أفادني  ${answer.helpfulCount}'),
            ),
          ]),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.number, required this.title});
  final String number;
  final String title;
  @override
  Widget build(BuildContext context) => Row(children: [
    CircleAvatar(radius: 13, backgroundColor: primaryBlack, child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
    const SizedBox(width: 9),
    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink)),
  ]);
}

class _SubmissionDialog extends StatelessWidget {
  const _SubmissionDialog();
  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: Container(width: 70, height: 70, decoration: const BoxDecoration(color: warmBeige, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, size: 38, color: primaryBlack)),
    title: const Text('وصلنا سؤالك', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: primaryBlack)),
    content: const Text('سؤالك الآن في المراجعة، وحيظهر للمجتمع أول ما يتم اعتماده.', textAlign: TextAlign.center),
    actionsAlignment: MainAxisAlignment.center,
    actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('تمام'))],
  );
}

class _LoadingFeed extends StatelessWidget {
  const _LoadingFeed();
  @override
  Widget build(BuildContext context) => Padding(
    key: const Key('loading-state'),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Column(children: List.generate(3, (index) => Container(
      height: 155,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: border), borderRadius: BorderRadius.circular(18)),
      child: const Center(child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlack))),
    ))),
  );
}
