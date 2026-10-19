import 'package:flutter_test/flutter_test.dart';
import 'package:qingtu_flutter/main.dart';

void main() {
  testWidgets('轻图应用可启动', (tester) async {
    await tester.pumpWidget(const QingtuApp());
    expect(find.text('轻图'), findsOneWidget);
  });
}
