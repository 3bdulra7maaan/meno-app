import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'brand.dart';
import 'models/question.dart';

const menoPublicUrl = 'https://3bdulra7maaan.github.io/meno-app/';

String questionShareText(Question question) =>
    '${question.title}\n\nاسأل زول جرّب على Meno\n'
    '$menoPublicUrl?question=${Uri.encodeQueryComponent(question.id)}';

class QuestionShareSheet extends StatelessWidget {
  const QuestionShareSheet({super.key, required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final text = questionShareText(question);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'شارك السؤال',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: darkSurface,
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      MenoMark(size: 24),
                      SizedBox(width: 7),
                      Text(
                        'Meno',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: warmGold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    question.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: cream, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const Key('share-native-button'),
              onPressed: () => Share.share(text),
              style: FilledButton.styleFrom(
                backgroundColor: warmGold,
                foregroundColor: primaryBlack,
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text(
                'مشاركة عبر التطبيقات',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('copy-question-link'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ رابط السؤال')),
                );
              },
              icon: const Icon(Icons.link_rounded),
              label: const Text('نسخ الرابط'),
            ),
          ],
        ),
      ),
    );
  }
}
