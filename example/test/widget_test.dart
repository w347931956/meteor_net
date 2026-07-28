import 'package:flutter_test/flutter_test.dart';

import 'package:meteor_net_example/main.dart';

void main() {
  testWidgets('shows MeteorNet demo actions', (tester) async {
    await tester.pumpWidget(const DemoApp());

    expect(find.text('MeteorNet 真机示例'), findsOneWidget);
    expect(find.text('请求 HTTP 接口'), findsOneWidget);
    expect(find.text('请求 Mock 数据'), findsOneWidget);
    expect(find.text('连接 WebSocket 并发送消息'), findsOneWidget);
  });
}
