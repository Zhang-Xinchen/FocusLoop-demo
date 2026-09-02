import 'package:flutter_test/flutter_test.dart';

import 'package:focusloop/main.dart';

void main() {
  testWidgets('App launches and shows home page', (tester) async {
    await tester.pumpWidget(const FocusLoopApp());
    expect(find.text('FocusLoop'), findsWidgets);
    expect(find.text('Task timing · Ebbinghaus review · Multi-device sync'), findsOneWidget);
  });
}
