import 'package:beyond_tv/src/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra o nome do produto', (tester) async {
    await tester.pumpWidget(const TvApp());

    expect(find.text('Beyond TV'), findsOneWidget);
  });
}
