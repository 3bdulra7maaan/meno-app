import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/in_memory_question_repository.dart';
import 'data/question_repository.dart';
import 'data/supabase_question_repository.dart';
import 'models/question.dart';

const navy = Color(0xFF102A43);
const gold = Color(0xFFF6C344);
const surface = Color(0xFFF4F6F8);

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
  const url = String.fromEnvironment('SUPABASE_URL');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isNotEmpty && anonKey.isNotEmpty) {
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }
  final repository = url.isNotEmpty && anonKey.isNotEmpty
      ? SupabaseQuestionRepository(Supabase.instance.client)
      : InMemoryQuestionRepository();
  runApp(MenoApp(repository: repository));
}

class MenoApp extends StatelessWidget {
  const MenoApp({super.key, required this.repository});

  final QuestionRepository repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Meno',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy, secondary: gold),
          scaffoldBackgroundColor: surface,
          fontFamily: 'sans-serif',
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide.none),
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('وصلنا سؤالك، وحيظهر بعد مراجعة المشرف.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _home(),
      _search(),
      const Center(child: Text('إشعاراتك حتظهر هنا', style: TextStyle(fontSize: 18, color: navy))),
      const Center(child: Text('حسابي', style: TextStyle(fontSize: 18, color: navy))),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 16,
        title: Row(
          textDirection: TextDirection.ltr,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Meno', style: TextStyle(color: navy, fontWeight: FontWeight.w900, fontSize: 27)),
            FilledButton.icon(
              onPressed: openAsk,
              style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: navy),
              icon: const Icon(Icons.add, size: 19),
              label: const Text('اسأل', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        indicatorColor: gold.withValues(alpha: .45),
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.search), label: 'بحث'),
          NavigationDestination(icon: Icon(Icons.notifications_none), label: 'الإشعارات'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'حسابي'),
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
              color: navy,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('اسأل زول جرّب', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text('إجابات سودانية من تجارب حقيقية', style: TextStyle(color: Colors.white70, fontSize: 15)),
                ],
              ),
            ),
            _categoryList(),
            _questionList(),
          ],
        ),
      );

  Widget _search() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => search = value),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'فتّش في الأسئلة...'),
            ),
            const SizedBox(height: 12),
            Expanded(child: _questionList()),
          ],
        ),
      );

  Widget _categoryList() => SizedBox(
        height: 58,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => ChoiceChip(
            label: Text(categories[i]),
            selected: category == categories[i],
            selectedColor: gold,
            onSelected: (_) => setState(() => category = categories[i]),
          ),
        ),
      );

  Widget _questionList() => FutureBuilder<List<Question>>(
        future: questions,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 42, color: navy),
                  const SizedBox(height: 12),
                  const Text('ما قدرنا نحمّل الأسئلة. اتأكد من الإنترنت.'),
                  const SizedBox(height: 8),
                  TextButton(onPressed: refresh, child: const Text('حاول تاني')),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
          }
          final filtered = snapshot.data!.where((q) {
            final matchesCategory = category == 'الكل' || q.category == category;
            final term = search.trim().toLowerCase();
            return matchesCategory && (term.isEmpty || q.title.toLowerCase().contains(term) || q.body.toLowerCase().contains(term));
          }).toList();
          if (filtered.isEmpty) {
            return const Padding(padding: EdgeInsets.all(36), child: Center(child: Text('ما لقينا أسئلة مطابقة')));
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
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(radius: 18, backgroundColor: surface, child: Text(question.author.characters.first, style: const TextStyle(color: navy))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(question.author, style: const TextStyle(fontWeight: FontWeight.w700))),
                  Text(_timeAgo(question.createdAt), style: const TextStyle(color: Colors.black45, fontSize: 12)),
                ]),
                const SizedBox(height: 14),
                Text(question.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.4)),
                const SizedBox(height: 7),
                Text(question.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54, height: 1.5)),
                const SizedBox(height: 14),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: gold.withValues(alpha: .22), borderRadius: BorderRadius.circular(20)),
                    child: Text(question.category, style: const TextStyle(color: navy, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.black54),
                  const SizedBox(width: 5),
                  Text('${question.answers.length} إجابة', style: const TextStyle(color: Colors.black54)),
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
        appBar: AppBar(title: const Text('اسأل سؤال'), backgroundColor: Colors.white),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text('شنو الداير تعرفو؟', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: navy)),
              const SizedBox(height: 6),
              const Text('اكتب بوضوح عشان الناس المجربين يقدروا يفيدوك.', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 22),
              TextFormField(controller: title, maxLength: 120, decoration: const InputDecoration(labelText: 'السؤال'), validator: (v) => v == null || v.trim().length < 8 ? 'اكتب سؤال أوضح' : null),
              const SizedBox(height: 12),
              TextFormField(controller: body, maxLines: 4, maxLength: 500, decoration: const InputDecoration(labelText: 'تفاصيل إضافية'), validator: (v) => v == null || v.trim().isEmpty ? 'أضف شوية تفاصيل' : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'التصنيف'),
                items: categories.skip(1).map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                onChanged: (value) => setState(() => category = value!),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: anonymous,
                activeThumbColor: navy,
                title: const Text('اسأل كمجهول', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('اسمك ما حيظهر مع السؤال'),
                onChanged: (value) => setState(() => anonymous = value),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: saving ? null : submit,
                style: FilledButton.styleFrom(backgroundColor: navy, padding: const EdgeInsets.symmetric(vertical: 15)),
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
        appBar: AppBar(title: const Text('السؤال'), backgroundColor: Colors.white),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            QuestionCard(question: widget.question, onTap: () {}),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text('${widget.question.answers.length} إجابة', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: navy)),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ما قدرنا نسجل «أفادني». حاول تاني.')),
                      );
                    }
                  },
                )),
          ],
        ),
        bottomSheet: SafeArea(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
            child: Row(children: [
              Expanded(child: TextField(controller: answer, minLines: 1, maxLines: 3, decoration: const InputDecoration(hintText: 'جاوب من تجربتك...'))),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: addAnswer, style: IconButton.styleFrom(backgroundColor: navy), icon: const Icon(Icons.send)),
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
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const CircleAvatar(radius: 16, backgroundColor: navy, child: Icon(Icons.person, color: Colors.white, size: 18)),
              const SizedBox(width: 9),
              Text(answer.author, style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(_timeAgo(answer.createdAt), style: const TextStyle(color: Colors.black45, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            Text(answer.body, style: const TextStyle(fontSize: 15, height: 1.6)),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onHelpful,
              style: TextButton.styleFrom(foregroundColor: answer.isHelpful ? navy : Colors.black54, backgroundColor: answer.isHelpful ? gold.withValues(alpha: .25) : null),
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
