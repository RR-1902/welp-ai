import 'package:ai_job_interview_simulator/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots through splash and reaches login', (tester) async {
    await tester.pumpWidget(const InterviewSimulatorApp());
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pumpAndSettle();

    expect(find.text('Welp.Ai'), findsWidgets);
  });
}
