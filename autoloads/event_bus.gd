# ==============================================================================
#   event_bus.gd
#   功能：全局信号总线（Autoload 单例），提供跨场景、跨组件的松耦合通信机制。
#        所有信号均在此声明，任何模块均可连接或发射这些信号。
#   自动加载配置：在 Project -> Project Settings -> Autoload 中添加，命名为 EventBus
# ==============================================================================
extends Node

# ========================== 信号声明模块 ==========================
# 使用 @warning_ignore 抑制"信号未使用"的警告（因为信号仅在此声明，在其他模块中使用）
@warning_ignore_start("unused_signal")

## 触发时机：请求推入临时游戏状态（UIManager 打开模态 UI 时发出，GameManager 监听并执行 push_state）
## 参数：state (int) - GameState 枚举值
signal game_state_push_requested(state: int)

## 触发时机：请求弹出临时游戏状态（UIManager 关闭模态 UI 时发出，GameManager 监听并执行 pop_state）
signal game_state_pop_requested()

## 触发时机：请求全局重置返回主菜单（如暂停菜单中点击"返回主菜单"或"退出游戏"时发出）
## GameManager 监听后清空状态栈并切到 MAIN_MENU，UIManager 监听后清空所有 UI 实例和模态栈
signal return_to_main_menu_requested()

## 触发时机：玩家实体初始化完成时
signal player_ready()

## 触发时机：角色的健康值发生变化时（受伤、治疗等）
## 参数：new_health (int) - 当前生命值，new_max_health (int) - 最大生命值
signal health_updated(new_health: int, new_max_health: int)

## 触发时机：玩家角色死亡时
signal player_died()

## 触发时机：角色的能量值发生变化时（消耗、恢复等）
## 参数：new_energy (int) - 当前能量值，new_max_energy (int) - 最大能量值
signal energy_updated(new_energy: int, new_max_energy: int)

## 触发时机：连击数发生变化时（攻击命中、连击中断等）
## 参数：new_combo (int) - 当前连击数
signal combo_updated(new_combo: int)

## 触发时机：需要造成技能伤害时（请求型信号）
## 说明：期望接收方响应信号并调用伤害应用逻辑（如 apply_damage）
## 参数：damage_data (Dictionary) - 伤害数据字典，包含伤害值、来源、目标等信息
## TODO: 新建资源类型（如 DamageData）来替代 Dictionary 传递伤害数据
signal skill_damage_requested(damage_data: Dictionary)

## 触发时机：技能命中目标并计算出伤害时
## 参数：info (DamageInfo) - 类型安全的伤害数据对象
signal damage_dealt(info: DamageInfo)

## 触发时机：玩家收集到硬币时
## 参数：amount (int) - 本次收集的硬币数量
signal coin_collected(amount: int)

## 触发时机：玩家更改了技能槽技能（请求型信号）
## 参数：slot_index (int) - 技能槽索引（0~3）
signal skill_slot_changed(slot_index: int)

## 触发时机：玩家通过鼠标点击了某个技能槽（请求型信号）
## 参数：slot_index (int) - 技能槽索引（0~3）
signal skill_slot_clicked(slot_index: int)

## 触发时机：技能冷却进度更新（供 UI 更新冷却遮罩和 CD 文本）
## 参数：slot_index (int) - 技能槽索引；remaining (float) - 剩余冷却秒数；total (float) - 总冷却秒数
signal skill_cooldown_updated(slot_index: int, remaining: float, total: float)

## 触发时机：技能冷却结束（供 UI 隐藏冷却遮罩）
## 参数：slot_index (int) - 技能槽索引
signal skill_cooldown_finished(slot_index: int)

## 触发时机：请求打开暂停菜单时
signal pause_menu_requested()

## 触发时机：请求打开设置菜单时
signal settings_menu_requested()

## 触发时机：请求打开游戏结束界面时
signal game_over_requested()

## 触发时机：请求打开技能选择界面时
signal skill_selection_requested()

## 触发时机：当前 UI 栈的输入屏蔽规则发生变化
## 参数：blocked_prefixes (Array[String]) - 需要屏蔽的输入动作前缀列表
signal input_blocking_updated(blocked_prefixes: Array[String])

# ========================== S6 Roguelite 循环信号 ==========================
## 触发时机：新运行开始时
## 参数：seed (int) - 世界种子；layer (int) - 起始层数
signal run_started(seed: int, layer: int)

## 触发时机：运行结束时（死亡或主动放弃）
## 参数：stats (Dictionary) - 本次运行统计
signal run_ended(stats: Dictionary)

## 触发时机：Boss 被击败时
## 参数：coord (Vector2i) - Boss 房间坐标；layer (int) - 当前层数
signal boss_defeated(coord: Vector2i, layer: int)

## 触发时机：层数推进时
## 参数：new_layer (int) - 新层数
signal layer_advanced(new_layer: int)

## 触发时机：敌人被击杀时（用于统计追踪）
## 参数：enemy_type (String) - 敌人类型；coord (Vector2i) - 所在房间坐标
signal enemy_killed(enemy_type: String, coord: Vector2i)

## 触发时机：运行检查点保存时
signal checkpoint_saved()

# ========================== S7 状态效果信号 ==========================
## 触发时机：状态效果被施加时
## 参数：target (Node2D) - 被施加效果的实体；effect (StatusEffectInstance) - 效果实例
signal status_effect_applied(target: Node2D, effect: StatusEffectInstance)

## 触发时机：状态效果被移除时
## 参数：target (Node2D) - 实体；effect (StatusEffectInstance) - 效果实例
signal status_effect_removed(target: Node2D, effect: StatusEffectInstance)

## 触发时机：状态效果 Tick 时
## 参数：target (Node2D) - 实体；effect (StatusEffectInstance) - 效果实例
signal status_effect_ticked(target: Node2D, effect: StatusEffectInstance)

# ========================== S7 房间内容信号 ==========================
## 触发时机：隐藏房间被揭露时
## 参数：coord (Vector2i) - 房间坐标
signal hidden_room_revealed(coord: Vector2i)

## 触发时机：房间内容生成完成时
## 参数：coord (Vector2i) - 房间坐标；content_type (String) - 内容类型
signal room_content_generated(coord: Vector2i, content_type: String)

# ========================== S7 对话系统信号 ==========================
## 触发时机：对话开始时
signal dialog_started()

## 触发时机：对话结束时
signal dialog_ended()

## 触发时机：对话选项被选择时
## 参数：choice_index (int) - 选项索引
signal dialog_choice_made(choice_index: int)

# ========================== S7 商店信号 ==========================
## 触发时机：商品被购买时
## 参数：item_id (String) - 商品 ID；price (int) - 价格
signal shop_item_purchased(item_id: String, price: int)

# ========================== S7 遗物信号 ==========================
## 触发时机：遗物被获取时
## 参数：relic_id (String) - 遗物 ID
signal relic_acquired(relic_id: String)

## 触发时机：遗物被移除时
## 参数：relic_id (String) - 遗物 ID
signal relic_lost(relic_id: String)

## 触发时机：请求打开遗物选择界面时
signal relic_selection_requested

# ========================== S8 协同系统信号 ==========================
## 触发时机：技能协同时
## 参数：rule_id (String) - 协同规则ID；context (Dictionary) - 上下文信息
signal synergy_triggered(rule_id: String, context: Dictionary)

## 触发时机：武器技能协同时
## 参数：synergy_id (String) - 协同ID；weapon_id (String) - 武器ID；skill_id (String) - 技能ID
signal weapon_skill_synergy_triggered(synergy_id: String, weapon_id: String, skill_id: String)

# ========================== S8 BOSS系统信号 ==========================
## 触发时机：BOSS阶段变化时
## 参数：coord (Vector2i) - BOSS房间坐标；new_phase (int) - 新阶段索引
signal boss_phase_changed(coord: Vector2i, new_phase: int)

## 触发时机：BOSS技能掉落时
## 参数：boss_id (String) - BOSS ID；skill_id (String) - 技能ID
signal boss_skill_dropped(boss_id: String, skill_id: String)

# ========================== S8 武器系统信号 ==========================
## 触发时机：武器装备时
## 参数：weapon_id (String) - 武器ID
signal weapon_equipped(weapon_id: String)

## 触发时机：武器卸下时
## 参数：weapon_id (String) - 武器ID
signal weapon_unequipped(weapon_id: String)

## 触发时机：武器升级时
## 参数：weapon_id (String) - 武器ID；new_level (int) - 新等级
signal weapon_upgraded(weapon_id: String, new_level: int)

## 触发时机：武器附魔时
## 参数：weapon_id (String) - 武器ID；enchant_id (String) - 附魔ID
signal weapon_enchanted(weapon_id: String, enchant_id: String)

## 触发时机：武器技能使用时
## 参数：weapon_id (String) - 武器ID
signal weapon_skill_used(weapon_id: String)

# ========================== S8 成就系统信号 ==========================
## 触发时机：成就解锁时
## 参数：achievement_id (String) - 成就ID
signal achievement_unlocked(achievement_id: String)

# ========================== S8 图鉴系统信号 ==========================
## 触发时机：图鉴条目解锁时
## 参数：entry_id (String) - 图鉴条目ID
signal codex_entry_unlocked(entry_id: String)

# ========================== S8 随机事件信号 ==========================
## 触发时机：随机事件触发时
## 参数：event_id (String) - 事件ID；coord (Vector2i) - 房间坐标
signal random_event_triggered(event_id: String, coord: Vector2i)

@warning_ignore_restore("unused_signal")
