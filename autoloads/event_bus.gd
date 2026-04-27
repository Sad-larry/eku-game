# autoloads/events_bus.gd
# 全局单例：全局信号总线
extends Node

# ========================== 信号定义 ==========================
@warning_ignore_start("unused_signal")
# 健康值变化（通知型）
signal health_updated(new_health: int, new_max_health: int)
# 角色死亡（通知型）
signal player_died()
# 能量值变化（通知型）
signal energy_updated(new_energy: int, new_max_energy: int)
# 连击数变化（通知型）
signal combo_updated(new_combo: int)
# 请求造成技能伤害（请求型，期望接收方调用 apply_damage）
# TODO 新建资源类型来传递damage_data
signal skill_damage_requested(damage_data: Dictionary)
# 房间完成（通知型）
# 参数 room: 已完成房间的实例
signal room_completed(room: RoomBase)
@warning_ignore_restore("unused_signal")
