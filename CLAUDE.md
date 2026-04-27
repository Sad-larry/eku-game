# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Communication

- 永远使用简体中文进行思考和对话

## Documentation

- 编写 .md 文档时，也要用中文

## Code Architecture

- 编写代码的硬性指标，包括以下原则： 
  - （1）对于GDScript 等动态语言，尽可能确保每个代码文件不要超过 300 行
  - （2）每层文件夹中的文件，尽可能不超过 8 个。如有超过，需要规划为多层子文件夹
- 除了硬性指标以外，还需要时刻关注优雅的架构设计，避免出现以下可能侵蚀我们代码质量的「坏味道」：
  - （1）僵化 (Rigidity): 系统难以变更，任何微小的改动都会引发一连串的连锁修改。
  - （2）冗余 (Redundancy): 同样的代码逻辑在多处重复出现，导致维护困难且容易产生不一致。
  - （3）循环依赖 (Circular Dependency): 两个或多个模块互相纠缠，形成无法解耦的“死结”，导致难以测试与复用。
  - （4）脆弱性 (Fragility): 对代码一处的修改，导致了系统中其他看似无关部分功能的意外损坏。
  - （5）晦涩性 (Obscurity): 代码意图不明，结构混乱，导致阅读者难以理解其功能和设计。
  - （6）数据泥团 (Data Clump): 多个数据项总是一起出现在不同方法的参数中，暗示着它们应该被组合成一个独立的对象。 
  - （7）不必要的复杂性 (Needless Complexity): 用“杀牛刀”去解决“杀鸡”的问题，过度设计使系统变得臃肿且难以理解。
- 【非常重要！！】无论是你自己编写代码，还是阅读或审核他人代码时，都要严格遵守上述硬性指标，以及时刻关注优雅的架构设计。
- 【非常重要！！】无论何时，一旦你识别出那些可能侵蚀我们代码质量的「坏味道」，都应当立即询问用户是否需要优化，并给出合理的优化建议。 

## Run & Debug

- 必须首先在项目的 run_scripts/ 目录下，维护好 Run & Debug 需要用到的全部 .sh 脚本
- 对于所有 Run & Debug 操作，一律使用 scripts/ 目录下的 .sh 脚本进行启停。永远不要直接使用 npm、pnpm、uv、python 等等命令
-  如果 .sh 脚本执行失败，无论是 .sh 本身的问题还是其他代码问题，需要先紧急修复。然后仍然坚持用 .sh 脚本进行启停
-  Run & Debug 之前，为所有项目配置 Logger with File Output，并统一输出到 logs/ 目录下

## Project Overview

这是一个面向 Godot 4.6 引擎的项目，项目名称为 EkuGame，是一款以技能构筑为核心的动作类像素肉鸽游戏。游戏主打快节奏战斗，玩家可通过攻击衔接各类技能，打出连续连招。

## Development Environment

- **Engine**: Godot 4.6 with Forward+ rendering
- **Physics**: Jolt Physics engine
- **Rendering**: D3D12 on Windows
- **Window**: 1280×720 viewport with canvas_items stretch mode

## Running the Project

在 Godot 编辑器中打开项目，或通过命令行运行：
```bash
godot --path .
```

主场景在`project.godot`文件中进行配置  (`run/main_scene="uid://bv7ni74an015u"`).

## Architecture

项目目录如下：

```txt
D:.
├─assets                             # 存放所有原始资源文件（图片、音频、字体等）
├─autoloads                          # 存放自动加载的单例脚本（Global, GameManager, InputManager等）
├─effects                            # 存放粒子特效、后处理等视觉特效相关的场景或资源
├─prefabs                            # 存放可动态实例化的预制体场景
│  ├─components                      # 存放可复用的功能组件预制体（如血条、能量条等）
│  ├─entities                        # 存放实体类预制体（玩家、敌人等）
│  ├─environment                     # 存放环境物体预制体（障碍物、装饰物等）
│  ├─fx                              # 存放特效类预制体（爆炸、命中特效等）
│  └─objects                         # 存放交互物体预制体（宝箱、道具等）
├─resources                          # 存放非场景类的自定义资源文件（.tres, .res）
│  ├─configs                         # 存放游戏配置资源（输入映射、音频设置等）
│  ├─data                            # 存放游戏数据资源（实体属性、关卡数据等）
│  │  ├─entities                     # 实体数据资源（玩家属性数据、敌人属性数据）
│  │  ├─rooms                        # 房间布局/生成数据
│  │  ├─skills                       # 技能数据资源
│  │  │  ├─control                   # 控制技数据
│  │  │  ├─finisher                  # 终结技数据
│  │  │  ├─initiator                 # 起手技数据
│  │  │  └─survial                   # 生存技数据
│  │  └─waves                        # 怪物波次数据
│  └─themes                          # 主题/皮肤资源（UI样式、配色方案等）
├─scenes                             # 存放通过 SceneTree 直接切换的主流程场景
│  ├─main                            # 游戏开始菜单
│  ├─game                            # 游戏冒险地图场景（GameWorld等）
│  ├─lobby                           # 游戏大厅场景
│  ├─transitions                     # 场景过渡动画场景
│  └─ui                              # UI全屏界面场景（设置、暂停菜单等）
├─scripts                            # 存放所有逻辑脚本（.gd）
│  ├─behaviors                       # 行为类脚本（敌人AI行为等）
│  ├─components                      # 可复用的组件脚本（生命值、伤害处理等）
│  ├─systems                         # 游戏系统脚本
│  │  ├─combat                       # 战斗系统
│  │  ├─events                       # 事件系统
│  │  ├─loot                         # 掉落系统
│  │  ├─room_generation              # 房间生成系统
│  │  └─skills                       # 技能系统
│  └─utils                           # 通用工具函数脚本
├─shaders                            # 存放着色器文件（.gdshader）
└─styles                             # 存放主题样式表（.tres, 如 Theme 资源）
```

该项目采用数据驱动架构，实现了清晰的关注点分离，部分目录：

### 1. Autoloads (`autoloads/`)

启动时加载的全局单例管理器：
- `global.gd`：通用枚举、工具函数（如数学运算、类型转换），所有单例均可访问
- `game_manager.gd`：管理游戏全局状态（主菜单/游戏中/暂停/设置），提供状态切换与状态栈，发射状态变更信号
- `audio_manager.gd`：统一管理音效与背景音乐播放（该模块建议后期实现）
- `save_manager.gd`：处理玩家存档的读写、自动保存、配置管理，提供基础存档数据接口。
- `input_manager.gd`：封装输入映射、输入缓冲队列、动作检测
- `skill_library.gd`：全局技能池管理器
- `ui_Manager.gd`：管理模态UI栈（暂停菜单、设置界面等），统一处理UI的推送/弹出，并配合GameManager维护游戏状态。
- `event_bus.gd`：全局信号总线
- `room_manager.gd`：房间管理
- `scene_loader.gd`：场景加载器

### 2. Scenes (`scenes/`)
游戏流程与界面场景：
- `main/`: 游戏启动菜单模块（包括开始游戏、系统设置、退出游戏等交互界面）
- `lobby/`: 游戏主页主模块（包括主城初始房间、游戏入口与基础 UI 布局）
- `game/`: 游戏核心游玩根目录（包括战斗场景、首领关卡、商店房间等游戏场景模板与世界逻辑资源）
- `ui/`: HUD、暂停菜单、设置界面、游戏结束界面

### 3. Scripts (`scripts/`)
纯GDScript系统与工具：
- `systems/`: 战斗、技能、房间生成、战利品、事件
- `behaviors/`: 敌人AI行为、抛射物逻辑
- `utils/`: 辅助函数、数学工具、场景加载器

### 4. Visual Effects (`effects/`, `shaders/`)
- `effects/`: 材质资源与粒子系统
- `shaders/`: 自定义着色器代码（闪光、溶解、轮廓、像素对齐等）

## Conventions

- **命名规范**：所有文件与标识符均使用蛇形命名法
- **技能系统**：技能为数据驱动型资源，存放于 resources/data/skills/ 目录下，并按类型分类

## Focus Areas

工作时应优先关注以下路径：

### 核心开发目录（可读写） 

- `autoloads/` — 全局单例脚本
- `effects/` — 材质与粒子
- `prefabs/` — 预制体场景
-  `resources/` — 数据配置资源（.tres）
- `scenes/` — 场景文件（.tscn）
- `scripts/` — 所有 GDScript 系统逻辑
- `shaders/` — 着色器代码
- `styles/` — UI 主题样式（.tres / .theme）
- `project.godot` — 项目配置

### 只读参考目录（不可修改）
- `assets/` — 原始美术资源

### 不需要关注的目录
- `run_scripts/` — 仅通过该目录下的脚本启停项目
- `logs/` — 运行时日志输出
- `addons/` — 第三方插件

## Notes

- 该项目仍处于开发初期，许多目录初始状态下为空