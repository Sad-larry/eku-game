# ==============================================================================
#   pip_viewport_controller.gd
#   功能：画中画视口控制器，管理 SubViewport 的渲染、PiP 窗口的显示/隐藏、
#        放大到全屏的过渡动画。扩展 CanvasLayer 以确保 PiP 绘制在最顶层。
#   挂载位置：作为 LobbyWorld 的子节点（CanvasLayer）。
#   期望场景结构：
#     PiPViewportController (CanvasLayer, layer=10)
#       ├─ SubViewportContainer      ← Control 节点，PiP 可视窗口
#       │   └─ SubViewport           ← 独立渲染目标场景
#       │       └─ PiPCamera (Camera2D)  ← 目标场景专用摄像机
# ==============================================================================
extends CanvasLayer
class_name PiPViewportController


# ========================== 导出变量模块 ==========================
## PiP 窗口初始尺寸（像素）
@export var pip_size: Vector2 = Vector2(320, 180)

## PiP 窗口距屏幕边缘的间距（像素）
@export var pip_margin: float = 16.0

## PiP 放大到全屏的动画时长（秒）
@export var expand_duration: float = 0.5

## PiP 中摄像机缩放倍数（与主摄像机一致，读取后缓存）
@export var default_zoom: Vector2 = Vector2(2.5, 2.5)


# ========================== 节点引用模块 ==========================
@onready var container: SubViewportContainer = $SubViewportContainer
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var pip_camera: Camera2D = $SubViewportContainer/SubViewport/PiPCamera


# ========================== 变量定义模块 ==========================
## PiP 窗口在右上角的锚定位置
var _pip_position: Vector2 = Vector2.ZERO

## 全屏尺寸（读取视口实际分辨率）
var _fullscreen_size: Vector2 = Vector2(1280, 720)

## 主摄像机缩放（show_pip 时读取并缓存）
var _main_camera_zoom: Vector2 = Vector2(2.5, 2.5)

## 是否正在执行放大动画
var _is_expanding: bool = false

## 当前活跃的放大 Tween 引用，用于 hide_pip 时中断
var _expand_tween: Tween = null


# ========================== 生命周期模块 ==========================
func _ready() -> void:
	_init_pip_position()
	_fullscreen_size = get_viewport().get_visible_rect().size

	# PiP 初始状态：隐藏，不渲染
	container.hide()
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED

	# 缓存主摄像机缩放倍数
	var main_cam := get_tree().get_first_node_in_group("isometric_camera") as Camera2D
	if main_cam:
		_main_camera_zoom = main_cam.zoom


## 计算 PiP 在屏幕右上角的初始位置
func _init_pip_position() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_pip_position = Vector2(
		viewport_size.x - pip_size.x - pip_margin,
		pip_margin
	)


# ========================== 公共 API：LobbyPortalManager 调用 ==========================
## 功能：显示 PiP 窗口，将 PiP 摄像机置于目标场景的指定位置
## 参数：target_pos (Vector2) - 目标传送方块附近的世界坐标
func show_pip(target_pos: Vector2) -> void:
	# 重置容器布局
	container.position = _pip_position
	container.size = pip_size
	container.modulate = Color(1.0, 1.0, 1.0, 0.0)

	# 配置 SubViewport 渲染分辨率
	sub_viewport.size = Vector2i(pip_size)
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# 将 PiP 摄像机置于目标位置，使用与主摄像机一致的缩放
	pip_camera.global_position = target_pos
	pip_camera.zoom = _main_camera_zoom

	# 显示 PiP 并淡入
	sub_viewport.world_2d = get_viewport().world_2d
	container.show()
	var fade_in := create_tween()
	fade_in.tween_property(container, "modulate", Color.WHITE, 0.15)
	fade_in.play()


## 功能：实时更新 PiP 摄像机位置（跟随玩家在目标场景中的映射位置）
## 参数：target_pos (Vector2) - 目标场景中对应的世界坐标
func update_pip_camera(target_pos: Vector2) -> void:
	pip_camera.global_position = target_pos


## 功能：执行 PiP 放大到全屏的过渡动画
## 返回值：Signal - await 此信号以等待动画完成
func expand_to_fullscreen() -> void:
	if _is_expanding:
		return

	_is_expanding = true

	# 更新 SubViewport 渲染分辨率为全屏
	sub_viewport.size = Vector2i(_fullscreen_size)

	# 执行放大 Tween
	_expand_tween = create_tween()
	_expand_tween.set_ease(Tween.EASE_IN_OUT)
	_expand_tween.set_trans(Tween.TRANS_SINE)
	# 窗口从右上角移动到 (0,0) 并放大到全屏
	_expand_tween.parallel().tween_property(container, "position", Vector2.ZERO, expand_duration)
	_expand_tween.parallel().tween_property(container, "size", _fullscreen_size, expand_duration)
	# 同时将 PiP 摄像机缩放逐渐匹配主摄像机
	_expand_tween.parallel().tween_property(pip_camera, "zoom", _main_camera_zoom, expand_duration)

	await _expand_tween.finished
	_is_expanding = false
	_expand_tween = null


## 功能：隐藏并停用 PiP 窗口
func hide_pip() -> void:
	# 中断进行中的放大动画
	if _is_expanding and _expand_tween:
		if _expand_tween.is_valid():
			_expand_tween.kill()
		_expand_tween = null
	_is_expanding = false

	# 隐藏窗口
	container.hide()

	# 停用 SubViewport 渲染以节省性能
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


## 功能：查询 PiP 是否正在播放放大动画
func is_expanding() -> bool:
	return _is_expanding
