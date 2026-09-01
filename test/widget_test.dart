import 'package:flutter_test/flutter_test.dart';
import 'package:meno/data/in_memory_question_repository.dart';
import 'package:meno/main.dart';

void main() {
  testWidgets('shows the Arabic-first home feed', (tester) async {
    await tester.pumpWidget(MenoApp(repository: InMemoryQuestionRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Meno'), findsOneWidget);
    expect(find.text('اسأل زول جرّب'), findsOneWidget);
    expect(find.text('اسأل'), findsOneWidget);
  });
}
