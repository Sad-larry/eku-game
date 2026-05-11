class_name OccluderComponent
extends Area2D

## 树被遮挡时的透明度（0.0=完全透明，1.0=完全不透明）
@export var occluded_alpha: float = 0.3

## 玩家被遮挡时的透视效果透明度
@export var player_ghost_alpha: float = 0.5

## 透明度过渡时长（秒）
@export var fade_duration: float = 0.2

## 碰撞框尺寸（未手动添加 CollisionShape2D 时生效）
@export var shape_size: Vector2 = Vector2(32, 32)


var _parent_canvas: CanvasItem
var _player_sprite: Sprite2D = null


func _ready() -> void:
	_parent_canvas = get_parent() as CanvasItem
	assert(_parent_canvas != null, "OccluderComponent: 父节点必须是 CanvasItem")

	# 仅检测模式，不影响现有物理碰撞
	collision_layer = 0
	collision_mask = 1  # 检测玩家所在的默认 Layer 1
	monitorable = false

	# 查找或自动创建碰撞形状
	var cs := _find_or_create_shape()
	if cs and cs.shape == null:
		cs.shape = RectangleShape2D.new()
		(cs.shape as RectangleShape2D).size = shape_size

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _find_or_create_shape() -> CollisionShape2D:
	for child in get_children():
		if child is CollisionShape2D:
			return child
	var new_cs := CollisionShape2D.new()
	add_child(new_cs)
	return new_cs


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_sprite = _find_player_sprite(body)
	_apply_fade_to(_parent_canvas, occluded_alpha, "_tween_item")
	if _player_sprite:
		_apply_fade_to(_player_sprite, player_ghost_alpha, "_tween_player")


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_apply_fade_to(_parent_canvas, 1.0, "_tween_item")
	if _player_sprite:
		_apply_fade_to(_player_sprite, 1.0, "_tween_player")
	_player_sprite = null


## 在玩家子节点中查找 Sprite2D
func _find_player_sprite(player: Node) -> Sprite2D:
	for child in player.get_children():
		if child is Sprite2D:
			return child
	return null

func _apply_fade_to(target: CanvasItem, alpha: float, tween_var: String) -> void:
	var current_tween: Tween = get(tween_var)
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	var new_tween := create_tween()
	new_tween.tween_property(target, "modulate:a", alpha, fade_duration)
	set(tween_var, new_tween)
