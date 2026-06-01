# ==============================================================================
#   axis_indicator.gd
#   功能：轴状态指示器，显示当前活跃轴（X/Y）和方向。
#        轴切换时播放过渡动画。
# ==============================================================================
# [重构注释] 2.5D等距地图相关代码已暂时禁用
# extends Control
# class_name AxisIndicator
#
# # ========================== 节点引用模块 ==========================
# @onready var axis_label: Label = $Label
# @onready var arrow: TextureRect = $Arrow
#
# # ========================== 生命周期模块 ==========================
# func _ready() -> void:
# 	RoomNavigationManager.axis_changed.connect(_on_axis_changed)
# 	_update_display()
#
# # ========================== 显示更新 ==========================
# func _update_display() -> void:
# 	if not axis_label:
# 		return
# 	var axis := RoomNavigationManager.active_axis
# 	if axis == "x":
# 		axis_label.text = "X轴"
# 		axis_label.modulate = Color.CYAN
# 		if arrow:
# 			arrow.rotation_degrees = 0  # 水平箭头
# 	else:
# 		axis_label.text = "Y轴"
# 		axis_label.modulate = Color.YELLOW
# 		if arrow:
# 			arrow.rotation_degrees = 90  # 垂直箭头
#
# func _play_switch_animation() -> void:
# 	var tween := create_tween()
# 	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
# 	tween.tween_property(self, "scale", Vector2.ONE, 0.15)
#
# # ========================== 信号回调 ==========================
# func _on_axis_changed(_new_axis: String) -> void:
# 	_update_display()
# 	_play_switch_animation()
