# FocusLoop 跨端架构设计

> 目标平台：Android / iOS / Windows / macOS（后续可扩展 Web）
> 定位：任务计时 + 艾宾浩斯复习的专注管理工具，多端数据互通
> 更新日期：2026-09-02

## 1. 功能需求

| # | 需求 | 架构落点 |
|---|---|---|
| 1 | 多端数据互通 | Local-first + 云端增量同步（见 §6） |
| 2 | 任务计时 | 计时状态机 + 不可变 TimeLog 记录（见 §4） |
| 3 | 艾宾浩斯复习任务 | 复习调度引擎，到期自动重新出现（见 §5） |
| 4 | 目标时长（小时/分钟） | Task.targetSeconds，进度 = 累计/目标 |
| 5 | 任务分类 | Category 实体 + 任务关联 |
| 6 | 后续扩展 | 特性模块化（features/），同步层接口化，新功能加模块即可 |

## 2. 技术选型

**首选 Flutter（Dart）**，单一代码库覆盖四端。

| 方案 | 结论 |
|---|---|
| Flutter | ✅ 首选。2026 年桌面端生产可用，生态最全，一套 UI 代码 |
| Compose Multiplatform | 备选。iOS 已转 Stable，适合纯 Kotlin 背景团队 |
| .NET MAUI | 不推荐。社区口碑弱，macOS 支持薄弱 |

## 3. 领域模型

```
Category 1 ──── * Task 1 ──── * TimeLog
                    │
                    └──── * ReviewSchedule（启用复习时）

User（云端） 1 ──── * 以上所有数据
```

### 核心实体

```dart
class Category {          // 任务分类
  String id;
  String name;
  int color;              // ARGB
  int sortOrder;
}

class Task {              // 任务
  String id;
  String title;
  String? note;
  String? categoryId;
  int targetSeconds;      // 目标时长，0 = 不设目标
  int accumulatedSeconds; // 累计时长（由 TimeLog 聚合，缓存值）
  TaskStatus status;      // active / completed / archived
  bool reviewEnabled;     // 是否艾宾浩斯复习任务
  String reviewTemplateId;// 使用的复习曲线模板
}

class TimeLog {           // 计时记录（不可变、只追加，天然无同步冲突）
  String id;
  String taskId;
  String deviceId;        // 来源设备，用于多端区分与审计
  DateTime startedAt;
  int durationSeconds;
}

class ReviewSchedule {    // 复习计划（每一轮一条）
  String id;
  String taskId;
  int round;              // 第几轮复习
  DateTime dueAt;         // 到期时间 → 到期即"重新出现"
  DateTime? completedAt;
  ReviewResult? result;   // remembered / forgotten
}
```

### 数据库表（drift / SQLite，本地）

| 表 | 说明 | 同步特性 |
|---|---|---|
| categories | 分类 | 可变行，LWW + tombstone |
| tasks | 任务 | 可变行，LWW + tombstone |
| time_logs | 计时记录 | 只追加，按 id 幂等合并 |
| review_schedules | 复习计划 | 可变行，LWW |
| review_templates | 复习曲线模板 | 内置 + 用户自定义 |

所有可变表带 `updated_at`、`device_id`、`deleted`（软删除墓碑）三列，供同步使用。

## 4. 计时与目标时长设计

- 计时引擎是纯 Dart 状态机：`idle → running → paused → running → stopped`
- 停止时生成一条 TimeLog，`task.accumulatedSeconds` 为聚合缓存
- 进度 = `accumulatedSeconds / targetSeconds`，UI 用进度环展示
- **跨息屏/后台**：移动端用前台服务保活 + 记录 startedAt，恢复时对时差补账（以墙钟为准，不依赖 tick 计数）
- 多端同时计时同一任务：允许，TimeLog 各自追加，汇总即总时长

## 5. 艾宾浩斯复习调度

### 间隔模板（可配置）

```
标准曲线：1天 → 2天 → 4天 → 7天 → 15天 → 30天
紧凑曲线：12小时 → 1天 → 2天 → 4天 → 7天
```

以 review_templates 表存储，用户可自定义，后续可扩展为根据记忆效果自适应。

### 调度规则（纯函数，核心可单元测试）

```
任务首次完成学习          → 生成 round=1，dueAt = now + interval[0]
第 i 轮复习完成(记得)      → 生成 round=i+1，dueAt = now + interval[i]
第 i 轮复习标记(忘记)      → 回退：重置到 round = max(1, i-2)，dueAt = now + 12h
全部轮次完成              → 任务标记"已掌握"，复习结束
```

### "重新出现"的实现

- `dueAt <= now` 且未完成的 ReviewSchedule 进入"今日待复习"列表（首页展示）
- 到期前通过本地通知提醒（移动端批量调度待触发通知；桌面端应用内提醒 + 托盘）
- 用户也可以随时手动发起复习（提前复习会顺延后续轮次）

## 6. 多端数据互通（同步设计）

### 方案：Local-first + 云端行级增量同步

```
设备A SQLite ──┐                    ┌── 设备B SQLite
               ├─→ 同步引擎 ←→ 云端 Postgres ←─┤
设备C SQLite ──┘   (增量+冲突解决)    └── ...
```

- **服务端首选 Supabase**：PostgreSQL + 认证 + 行级安全（RLS）+ 实时订阅，免运维，免费额度够个人/小团队用
- **备选 PowerSync**：现成的 SQLite↔Postgres 同步引擎，想省自研成本可选
- 同步层放在仓储接口之后，客户端代码不感知具体后端，未来可替换自建服务

### 冲突解决策略

| 数据类型 | 策略 |
|---|---|
| tasks / categories / review_schedules | Last-Write-Wins（按 updated_at，同值比 device_id） |
| time_logs | 只追加，无冲突，按 id 去重 |
| 删除 | 软删除墓碑，全端同步后由服务端定期清理 |

### 同步流程

1. 本地写操作立即落库（离线优先，永不阻塞用户）
2. 有网时增量推送 `updated_at > last_synced_at` 的行
3. 拉取远端变更合并进本地，触发 UI 刷新（Supabase Realtime 可实现准实时）
4. 未登录用户数据仅存本地，登录后可一键上传合并

## 7. 分层架构与目录结构

```
┌──────────────────────────────────────────────┐
│ Presentation：Widget + Riverpod               │
│   首页(今日任务+到期复习) / 计时页 / 任务列表    │
│   分类管理 / 统计 / 设置                        │
├──────────────────────────────────────────────┤
│ Domain（纯 Dart，100% 可单元测试）              │
│   计时状态机 / 目标进度计算 / 艾宾浩斯调度器      │
├──────────────────────────────────────────────┤
│ Data：drift(SQLite) + 同步仓库                 │
├──────────────────────────────────────────────┤
│ Platform Services：通知 / 托盘 / 自启 / 窗口    │
└──────────────────────────────────────────────┘
```

```
focusloop/
├── lib/
│   ├── main.dart
│   ├── app/                      # 路由(go_router)、主题、端自适应布局
│   ├── core/                     # 错误处理、常量、工具
│   ├── domain/                   # ★ 业务核心（纯 Dart）
│   │   ├── timer_state_machine.dart
│   │   ├── ebbinghaus_scheduler.dart
│   │   └── models/               # Task / Category / TimeLog / ReviewSchedule
│   ├── features/
│   │   ├── home/                 # 今日任务 + 到期复习
│   │   ├── timer/                # 计时页
│   │   ├── tasks/                # 任务 CRUD + 分类筛选
│   │   ├── categories/
│   │   ├── review/               # 复习流程（记得/忘记）
│   │   ├── stats/                # 专注统计图表
│   │   ├── settings/
│   │   └── sync/                 # 登录、同步状态、冲突处理
│   ├── data/                     # drift 表定义、仓储实现、同步引擎
│   └── platform/                 # 通知/托盘/窗口等平台服务抽象
├── test/                         # 重点：调度器 + 计时状态机单测
├── supabase/                     # 云端：表结构迁移 + RLS 策略
├── android/ ios/ windows/ macos/
└── pubspec.yaml
```

## 8. 关键技术选型

| 职责 | 选型 |
|---|---|
| 状态管理 | Riverpod |
| 路由 | go_router |
| 本地数据库 | drift (SQLite) |
| 云端 | Supabase（Postgres + Auth + Realtime + RLS） |
| 本地通知 | flutter_local_notifications |
| 桌面托盘/窗口 | tray_manager + window_manager |
| 图表 | fl_chart |
| 模型 | freezed + json_serializable |
| 认证 | supabase_flutter（邮箱/第三方登录） |

## 9. 平台差异处理

| 能力 | Android | iOS | Windows | macOS |
|---|---|---|---|---|
| 计时后台 | 前台服务 | 后台模式+通知兜底 | 常驻进程 | 常驻进程 |
| 复习提醒 | 本地通知 | 本地通知 | 应用内+托盘 | 应用内+托盘 |
| 分发 | Play / APK | App Store / TestFlight | MS Store(MSIX) / Inno Setup | Mac App Store / DMG+公证 |

## 10. 测试策略

- **domain 层**（重点）：艾宾浩斯调度器边界用例（记得/忘记/回退/完成）、计时状态机、目标进度计算，覆盖率 ≥ 90%
- **同步引擎**：离线写入 → 上线合并的模拟测试
- Widget 测试：核心页面；集成测试：移动端关键流程

## 11. CI/CD（GitHub Actions）

- PR：`flutter analyze` + `flutter test`
- 合并后矩阵构建：Android(fastlane→Play) / iOS(fastlane→TestFlight) / Windows(MSIX) / macOS(签名+公证→DMG)
- Supabase 迁移文件纳入版本管理，`supabase db push` 走 CI

## 12. 里程碑

| 阶段 | 内容 | 周期 |
|---|---|---|
| M1 | 脚手架 + 领域模型 + 计时引擎 + 单端（Android）任务计时闭环 | 2 周 |
| M2 | 艾宾浩斯复习全流程（模板/调度/今日复习/提醒） | 1.5 周 |
| M3 | 分类、统计、设置、本地通知 | 1.5 周 |
| M4 | Supabase 同步 + 账号体系 + 多端互通验证 | 2 周 |
| M5 | 桌面端适配（托盘/窗口/快捷键）+ 四端打包流水线 | 2 周 |

## 13. 开发环境要求

| 平台 | 工具 |
|---|---|
| 全员 | Flutter SDK (stable) + Dart |
| Android | Android Studio + SDK |
| iOS / macOS | macOS + Xcode + CocoaPods |
| Windows | Visual Studio 2022（C++ 桌面工作负载） |
| 云端 | Supabase 项目 + Supabase CLI |
