# MeteorNet

MeteorNet 是一个基于 Dio 的 Flutter 网络请求封装，目标是让业务层调用简单，同时保留 Dio 的扩展能力。

当前实现包含核心 HTTP 框架、常用增强功能、WebSocket 客户端、代理抓包配置和真机示例代码。

## 设计目标

- 业务层不直接依赖 Dio。
- 统一请求、响应解析和异常处理。
- 使用拦截器扩展认证、日志、缓存、重试、签名等能力。
- 所有增强功能默认可关闭，避免影响基础请求。
- 保留 `Options`、`CancelToken`、上传下载进度等 Dio 常用能力。

## 核心能力

- `GET`、`POST`、`PUT`、`PATCH`、`DELETE`
- 文件上传 `upload`
- 文件下载 `download`
- 泛型解析 `fromJson`
- 统一响应模型 `ApiResponse<T>`
- 统一异常 `ApiException`
- Token 注入和 401 自动刷新
- 请求取消 `CancelToken`
- 环境配置 `ApiConfig`
- 自定义拦截器 `extraInterceptors`

## 已添加的 10 个常用增强功能

这些功能都有总开关或单次请求开关。

| 功能 | 全局开关 | 单次请求配置 |
| --- | --- | --- |
| 请求去重 | `enableDeduplicate` | `RequestConfig.deduplicate` |
| 请求缓存 | `enableCache` | `RequestConfig.cachePolicy`、`cacheDuration` |
| Loading 事件 | `loadingObserver` | `RequestConfig.showLoading` |
| 错误文案映射 | `errorMessageMapper` | `RequestConfig.silent` |
| 请求耗时统计 | `enableLog` | 响应 `extra.durationMs` |
| Trace ID | `enableTrace` | `RequestConfig.traceId` |
| 签名机制 | `enableSign` | `RequestConfig.enableSign` |
| 全局 Header/参数 | `defaultHeaders`、`globalQuery` | `RequestConfig.headers`、`query` |
| 接口 Mock | `enableMock` | `RequestConfig.mockData` |
| 自动重试 | `enableRetry` | `RequestConfig.retryPolicy` |

另外还支持：

- 幂等 Key：`RequestConfig.idempotencyKey`
- 日志脱敏：自动隐藏 token、password、phone、email 等字段
- 代理抓包：`ApiConfig.enableProxy` + `proxy`
- WebSocket：`RealtimeClient`

## 安装

```yaml
dependencies:
  meteor_net: ^0.0.1
```

如果需要直接依赖 GitHub 上的源码版本，也可以使用：

```yaml
dependencies:
  meteor_net:
    git:
      url: git@github.com:w347931956/meteor_net.git
      ref: main
```

## 基础用法

```dart
final http = DioHttpClient(
  config: ApiConfig(
    baseUrl: 'https://api.example.com',
    enableLog: true,
    enableCache: true,
    enableRetry: true,
    enableDeduplicate: true,
    enableTrace: true,
    defaultHeaders: () => {
      'X-App-Version': '1.0.0',
      'X-Platform': 'flutter',
    },
    globalQuery: () => {
      'locale': 'zh-CN',
    },
    defaultRetryPolicy: const RetryPolicy(
      enabled: true,
      retries: 2,
    ),
  ),
);
```

```dart
final user = await http.get<User>(
  '/user/profile',
  fromJson: User.fromJson,
  config: const RequestConfig(
    showLoading: true,
    cachePolicy: CachePolicy.networkFirst,
  ),
);
```

POST：

```dart
final order = await http.post<Order>(
  '/orders',
  data: {
    'skuId': 1001,
    'count': 1,
  },
  fromJson: Order.fromJson,
  config: RequestConfig(
    idempotencyKey: 'create-order-uuid',
  ),
);
```

## 业务响应格式

默认按下面格式解析：

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

如果后端字段不同，可以在 `ApiConfig` 中改解析规则：

```dart
ApiConfig(
  baseUrl: 'https://api.example.com',
  successCode: 200,
  codeResolver: (json) => json['status'] as int,
  messageResolver: (json) => json['msg']?.toString() ?? '',
  dataResolver: (json) => json['result'],
)
```

## Token 刷新

实现 `AuthTokenProvider` 后传给 `DioHttpClient`：

```dart
class AppTokenProvider implements AuthTokenProvider {
  @override
  Future<String?> getAccessToken() async {
    return 'access-token';
  }

  @override
  Future<String?> refreshAccessToken() async {
    return 'new-access-token';
  }

  @override
  Future<void> onUnauthorized() async {
    // 清理登录态并跳转登录页
  }
}

final http = DioHttpClient(
  config: ApiConfig(baseUrl: 'https://api.example.com'),
  authTokenProvider: AppTokenProvider(),
);
```

401 后会调用 `refreshAccessToken()`，刷新成功后自动重放失败请求。

## 缓存策略

```dart
await http.get<Post>(
  '/posts/1',
  fromJson: Post.fromJson,
  config: const RequestConfig(
    cachePolicy: CachePolicy.networkFirst,
    cacheDuration: Duration(minutes: 10),
  ),
);
```

支持策略：

- `networkOnly`：只走网络
- `cacheOnly`：只读缓存
- `cacheFirst`：缓存有效则返回缓存，否则走网络
- `networkFirst`：网络失败时回退缓存
- `staleWhileRevalidate`：当前版本等同有效缓存优先，后台刷新待实现

## 代理抓包

iOS/Android/macOS 等 IO 平台可以这样配置：

```dart
final http = DioHttpClient(
  config: ApiConfig(
    baseUrl: 'https://api.example.com',
    enableProxy: true,
    proxy: '192.168.1.10:8888',
  ),
);
```

注意：

- 手机和电脑需要在同一局域网。
- `proxy` 填电脑局域网 IP 和抓包工具端口。
- Charles、Proxyman、Fiddler 抓 HTTPS 时，需要在手机安装并信任证书。
- 当前实现为了开发抓包方便，代理模式下允许自签证书，请不要在生产环境开启。

## WebSocket

```dart
final ws = RealtimeClient(
  urlBuilder: () => Uri.parse('wss://ws.postman-echo.com/raw'),
  reconnect: true,
  maxReconnectAttempts: 5,
);

ws.statusStream.listen(print);
ws.messageStream.listen(print);

await ws.connect();
ws.send({
  'type': 'ping',
  'time': DateTime.now().toIso8601String(),
});
```

鉴权建议放在 URL query 或连接成功后的业务首包里：

```dart
RealtimeClient(
  urlBuilder: () => Uri.parse('wss://api.example.com/ws?token=$token'),
);
```

## 真机示例

示例代码在：

- `example/lib/main.dart`

如果本地 Flutter SDK 正常，进入 `example` 后生成原生工程并运行：

```bash
cd example
flutter create --platforms=android,ios .
flutter pub get
flutter run
```

示例包含：

- HTTP GET 请求
- Mock 请求
- Loading 状态
- 缓存策略
- 请求重试
- 请求日志
- WebSocket 连接和发送消息
- 代理抓包配置示例

## 推荐分层

```text
UI
 |
ViewModel / Controller
 |
Repository
 |
ApiService
 |
DioHttpClient
 |
Dio
```

业务接口建议集中到 API Service：

```dart
class UserApi {
  UserApi(this.http);

  final HttpClient http;

  Future<User> profile() {
    return http.get<User>(
      '/user/profile',
      fromJson: User.fromJson,
    );
  }
}
```

## TODO

- 持久化缓存：当前缓存是内存缓存，App 重启后失效。
- `staleWhileRevalidate` 后台刷新：当前只返回有效缓存，未静默刷新网络。
- 更完整的离线模式：包括网络状态监听和离线数据标记。
- 请求队列和并发限流。
- 上传任务管理：暂停、恢复、失败重试、后台上传。
- 下载断点续传和文件完整性校验。
- WebSocket 原生 Header 注入：当前跨平台封装未强行暴露平台专属 Header。
- WebSocket 心跳包和应用层 ACK。
- SSL Pinning：生产环境证书绑定。
- 更完整的单元测试和 mock adapter。
