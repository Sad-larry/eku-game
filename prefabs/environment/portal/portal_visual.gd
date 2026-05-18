# 传送门光圈视觉组件
extends Node2D

@export var radius: float = 35.0
@export var color_inner: Color = Color(0.8, 0.3, 1.0, 0.5)
@export var color_outer: Color = Color(0.6, 0.2, 0.9, 0.7)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color_inner)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, color_outer, 2.5)
	draw_arc(Vector2.ZERO, radius * 0.6, 0, TAU, 64, color_outer.lightened(0.3), 1.5)
