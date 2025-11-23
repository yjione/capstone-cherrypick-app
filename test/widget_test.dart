// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:cherry_pick/main.dart';
import 'package:cherry_pick/providers/device_provider.dart';
import 'package:cherry_pick/service/device_api.dart';

void main() {
  testWidgets('CherryPick app smoke test', (WidgetTester tester) async {
    // 테스트용 DeviceProvider 생성 (실제 네트워크 호출은 안 써도 됨)
    final deviceProvider = DeviceProvider(api: DeviceApiService());

    // 앱 빌드
    await tester.pumpWidget(
      CherryPickApp(deviceProvider: deviceProvider),
    );

    // 라우터/프레임 안정화
    await tester.pumpAndSettle();

    // 초기 화면(AppBar)에 'cherry pick' 이 표시되는지 확인
    expect(find.text('cherry pick'), findsOneWidget);
  });
}
