# ==============================================================================
#   EnemyBoss.gd
#   功能：Boss 类型敌人，继承自基础 Enemy 类，用于扩展 Boss 特有的行为逻辑
#        （如多阶段战斗、特殊技能、更复杂的 AI 等）。
# ==============================================================================
extends Enemy
class_name EnemyBoss

# 注意：当前文件仅为占位实现，实际 Boss 特有逻辑（如阶段转换、特殊攻击模式等）
# 可在此类中添加，例如：
#
# ========================== 导出变量模块（示例）==========================
# ## Boss 阶段数量
# @export var phases: int = 3
#
# ========================== 重写方法模块（示例）==========================
# ## 功能：重写受击逻辑，添加阶段转换判断
# func _on_hurtbox_component_damaged(hitbox: HitboxComponent) -> void:
#     super._on_hurtbox_component_damaged(hitbox)
#     _check_phase_transition()
#
# ## 功能：检查是否进入下一阶段
# func _check_phase_transition() -> void:
#     # 具体阶段转换逻辑
#     pass
