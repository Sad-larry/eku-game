# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 【重要】MCP Memory 使用规范

本项目已配置 `@modelcontextprotocol/server-memory`，提供 **9 个工具**用于知识图谱持久化。你必须严格按以下流程使用：

### 对话开始 – 加载记忆

1. 调用 `search_nodes` 查询与项目名/游戏类型相关的实体（如 `"Project_Context"`、`"Gameplay_Mechanics"`、`"Coding_Conventions"`）。
2. 若找到，调用 `open_nodes` 读取详细内容，恢复上次的编码规范、架构决策、待办清单。
3. 若无历史记忆，初始化核心实体：`create_entities` 创建 `Project_Context` 和 `Todo_List`。

### 编辑文件前

先 `search_nodes` 读取 `Coding_Conventions`，确保输出符合编码规范。

### 对话中 – 主动维护记忆

- **架构决策**：`create_entities` 或 `add_observations` 记录
- **用户偏好/反馈**：创建 `Preference` 或 `feedback` 类型实体
- **完成/新增任务**：`create_relations` 关联 `Todo_Item` 与 `Project_Context`

### 对话结束 – 保存记忆

1. `create_entities` 创建 `Session_YYYY-MM-DD` 实体，记录本次完成的功能、生成的文件、遇到的难点。
2. `add_observations` 更新 `Project_Context`。
3. 调用 `read_graph` 自检，确保所有待办事项已正确建模。

### 清理与维护

`delete_entities` / `delete_observations` / `delete_relations` 移除废弃或错误的信息。

**重要提醒**：记忆能力的核心是**主动**与**一致**。始终假设项目会持续数周甚至数月，你的记忆力必须通过 MCP 服务来保持连贯。

## Communication

- 永远使用简体中文进行思考和对话
- 【重要】每次回复时都叫我【阿库】

## Documentation

- 编写 .md 文档时，也要用中文

## Code Architecture

- 需要时刻关注优雅的架构设计，避免出现以下可能侵蚀我们代码质量的「坏味道」：
  - （1）僵化 (Rigidity): 系统难以变更，任何微小的改动都会引发一连串的连锁修改。
  - （2）冗余 (Redundancy): 同样的代码逻辑在多处重复出现，导致维护困难且容易产生不一致。
  - （3）循环依赖 (Circular Dependency): 两个或多个模块互相纠缠，形成无法解耦的"死结"，导致难以测试与复用。
  - （4）脆弱性 (Fragility): 对代码一处的修改，导致了系统中其他看似无关部分功能的意外损坏。
  - （5）晦涩性 (Obscurity): 代码意图不明，结构混乱，导致阅读者难以理解其功能和设计。
  - （6）数据泥团 (Data Clump): 多个数据项总是一起出现在不同方法的参数中，暗示着它们应该被组合成一个独立的对象。 
  - （7）不必要的复杂性 (Needless Complexity): 用"杀牛刀"去解决"杀鸡"的问题，过度设计使系统变得臃肿且难以理解。
- 【非常重要！！】无论是你自己编写代码，还是阅读或审核他人代码时，都要时刻关注优雅的架构设计。
- 【非常重要！！】无论何时，一旦你识别出那些可能侵蚀我们代码质量的「坏味道」，都应当立即询问用户是否需要优化，并给出合理的优化建议。 

## Run & Debug

- 必须首先在项目的 run_scripts/ 目录下，维护好 Run & Debug 需要用到的全部 .sh 脚本
- 对于所有 Run & Debug 操作，一律使用 scripts/ 目录下的 .sh 脚本进行启停。永远不要直接使用 npm、pnpm、uv、python 等等命令
- 如果 .sh 脚本执行失败，无论是 .sh 本身的问题还是其他代码问题，需要先紧急修复。然后仍然坚持用 .sh 脚本进行启停
- Run & Debug 之前，为所有项目配置 Logger with File Output，并统一输出到 logs/ 目录下

## Project Overview

这是一个面向 Godot 4.6 引擎的项目，项目名称为 EkuGame，是一款以技能构筑为核心的冒险类像素肉鸽游戏。玩家可通过携带不同技能进入大世界地图进行冒险。

## Development Environment

- **Engine**: Godot 4.6 with Forward+ rendering
- **Physics**: Jolt Physics engine
- **Rendering**: D3D12 on Windows
- **Window**: 1280×720 viewport with canvas_items stretch mode

## Architecture

项目目录如下：

```txt
├─assets                    # 原始资源文件（图片、音频、字体等）
├─autoloads                 # 自动加载的单例脚本
├─effects                   # 粒子特效、后处理等视觉特效
├─prefabs                   # 可动态实例化的预制体场景
│  ├─components             # 可复用功能组件
│  ├─entities               # 实体类预制体（玩家、敌人等）
│  ├─environment            # 环境物体预制体（障碍物、装饰物等）
│  ├─fx                     # 特效类预制体
│  └─objects                # 交互物体预制体（宝箱、道具等）
├─resources                 # 自定义资源文件（.tres, .res）
│  ├─configs                # 游戏配置资源
│  ├─data                   # 游戏数据资源（技能、实体属性、房间数据等）
│  └─themes                 # UI 样式主题
├─scenes                    # SceneTree 直接切换的主流程场景
│  ├─main                   # 游戏开始菜单
│  ├─game                   # 游戏冒险地图场景
│  ├─lobby                  # 游戏大厅场景
│  ├─transitions            # 场景过渡动画
│  └─ui                     # UI 全屏界面（设置、暂停菜单等）
├─scripts                   # 逻辑脚本（.gd）
│  ├─behaviors              # 行为类脚本（AI、状态机）
│  ├─components             # 可复用组件脚本
│  ├─systems                # 游戏系统（战斗、技能、事件、房间生成等）
│  └─utils                  # 通用工具函数
├─shaders                   # 着色器文件（.gdshader）
└─styles                    # 主题样式表（.tres）
```

Autoload 加载顺序（从先到后）：Global → EventBus → SaveManager → GameManager → InputManager → SkillLibrary → RoomManager → UIManager → AudioManager → CurrencyManager → RunManager → SkillUnlockManager → PlayerProgressionManager → WeaponManager → SkillUpgradeManager → SceneLoader → RelicManager → SynergyManager → AchievementManager → CodexManager → AnalyticsManager → SignalLens

## Focus Areas

### 核心开发目录（可读写）
- `autoloads/`、`prefabs/`、`resources/`、`scenes/`、`scripts/`、`shaders/`、`styles/`、`effects/`、`project.godot`

### 只读参考（不可修改）
- `assets/` — 原始美术资源

### 无需关注
- `run_scripts/`、`logs/`、`addons/`
