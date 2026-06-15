import 'package:flutter_test/flutter_test.dart';

import 'package:projekt_gh/main.dart';

void main() {
  testWidgets('shows mocked films list', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Filmy Studio Ghibli'), findsOneWidget);
    expect(find.text('Castle in the Sky'), findsOneWidget);
    expect(find.text('1986 - Hayao Miyazaki'), findsOneWidget);
  });
}
