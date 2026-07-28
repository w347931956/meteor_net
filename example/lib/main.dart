import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meteor_net/meteor_net.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeteorNet Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> implements LoadingObserver {
  late final DioHttpClient http;
  late final RealtimeClient ws;
  StreamSubscription<dynamic>? wsMessageSub;
  StreamSubscription<RealtimeStatus>? wsStatusSub;

  bool loading = false;
  String httpResult = '点击按钮发起 HTTP 请求';
  String wsResult = '点击连接 WebSocket';

  @override
  void initState() {
    super.initState();
    http = DioHttpClient(
      config: ApiConfig(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        enableLog: true,
        enableCache: true,
        enableRetry: true,
        enableDeduplicate: true,
        enableTrace: true,
        enableMock: true,
        enableProxy: false,
        proxy: '电脑局域网 IP:8888',
        loadingObserver: this,
        defaultHeaders: () => {
          'X-App-Version': '1.0.0',
          'X-Platform': 'flutter',
        },
        globalQuery: () => {'locale': 'zh-CN'},
        defaultRetryPolicy: const RetryPolicy(
          enabled: true,
          retries: 2,
          delay: Duration(milliseconds: 400),
        ),
      ),
    );

    ws = RealtimeClient(
        urlBuilder: () => Uri.parse('wss://ws.postman-echo.com/raw'));
    wsMessageSub = ws.messageStream.listen((event) {
      setState(() => wsResult = '收到消息：$event');
    }, onError: (Object error) {
      setState(() => wsResult = 'WebSocket 错误：$error');
    });
    wsStatusSub = ws.statusStream.listen((event) {
      setState(() => wsResult = 'WebSocket 状态：$event');
    });
  }

  @override
  void dispose() {
    wsMessageSub?.cancel();
    wsStatusSub?.cancel();
    ws.dispose();
    super.dispose();
  }

  @override
  void onRequestStart() {
    setState(() => loading = true);
  }

  @override
  void onRequestEnd() {
    setState(() => loading = false);
  }

  Future<void> requestPost() async {
    try {
      final post = await http.get<Post>(
        '/posts/1',
        fromJson: Post.fromJson,
        config: const RequestConfig(
          showLoading: true,
          cachePolicy: CachePolicy.networkFirst,
          cacheDuration: Duration(minutes: 10),
        ),
      );
      setState(() => httpResult = '${post.id}. ${post.title}\n\n${post.body}');
    } on ApiException catch (error) {
      setState(() => httpResult = error.message);
    }
  }

  Future<void> requestMock() async {
    final post = await http.get<Post>(
      '/mock/post',
      fromJson: Post.fromJson,
      config: const RequestConfig(
        mockData: {
          'id': 100,
          'title': 'Mock 标题',
          'body': '这个结果来自 RequestConfig.mockData。',
        },
      ),
    );
    setState(() => httpResult = '${post.id}. ${post.title}\n\n${post.body}');
  }

  Future<void> connectWebSocket() async {
    try {
      await ws.connect();
      ws.send({'type': 'ping', 'time': DateTime.now().toIso8601String()});
    } catch (error) {
      setState(() => wsResult = 'WebSocket 连接失败：$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MeteorNet 真机示例')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton(
              onPressed: loading ? null : requestPost,
              child: Text(loading ? '请求中...' : '请求 HTTP 接口'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: requestMock,
              child: const Text('请求 Mock 数据'),
            ),
            const SizedBox(height: 12),
            Text(httpResult),
            const Divider(height: 32),
            FilledButton.tonal(
              onPressed: connectWebSocket,
              child: const Text('连接 WebSocket 并发送消息'),
            ),
            const SizedBox(height: 12),
            Text(wsResult),
          ],
        ),
      ),
    );
  }
}

class Post {
  const Post({required this.id, required this.title, required this.body});

  final int id;
  final String title;
  final String body;

  factory Post.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return Post(
      id: map['id'] as int,
      title: map['title'] as String,
      body: map['body'] as String,
    );
  }
}
