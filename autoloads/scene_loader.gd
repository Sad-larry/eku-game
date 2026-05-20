# ==============================================================================
#   scene_loader.gd
#   功能：场景加载器（Autoload 单例），提供异步加载场景 + 淡入淡出过渡动画 +
#        加载进度显示 + 等距相机自动迁移（跨场景复用相机实例）。
#   自动加载配置：Project -> Project Settings -> Autoloads 中添加，命名为 SceneLoader
# ==============================================================================
extends Node

# ========================== 信号声明模块 ==========================
## 触发时机：加载进度更新时（异步加载过程中）
## 参数：progress (float) - 加载进度，范围 0.0 ~ 1.0
signal loading_progress(progress: float)

## 触发时机：场景加载完成且新场景已激活时
signal loading_completed()

## 触发时机：场景加载失败时
## 参数：error_message (String) - 错误描述信息
signal loading_failed(error_message: String)

# ========================== 常量定义模块 ==========================
## 调试模式开关（开启后输出更多调试信息）
const DEBUG_MODE: bool = true
## 过渡覆盖层场景（负责淡入淡出动画和进度显示）
const TRANSITION_OVERLAY_SCENE = preload("uid://cyr13g8iathws")

# ========================== 变量定义模块 ==========================
## 当前是否正在加载中（防止重复加载）
var is_loading: bool = false
## 过渡覆盖层实例节点
var _overlay: Node
## 目标场景路径（待加载的资源路径）
var _target_path: String = ""
## 淡入/淡出动画时长（秒）
var _fade_duration: float = 0.3
## 加载失败标志（用于中断后续流程）
var _load_failed: bool = false
## 等距相机引用（用于场景间迁移，避免每个场景重复放置相机）
var _camera: IsometricCamera = null

# ========================== 公共 API 模块 ==========================
## 功能：异步加载并切换到目标场景（带淡入淡出过渡）
## 参数：scene_path (String) - 场景资源路径（如 "res://scenes/main.tscn"）；
##       fade_duration (float) - 淡入/淡出时长（秒），默认 0.3
func change_scene(scene_path: String, fade_duration: float = 0.3) -> void:
	if is_loading:
		if DEBUG_MODE:
			print("SceneLoader: 当前已在加载中，忽略重复请求")
		return

	is_loading = true
	_load_failed = false
	_fade_duration = fade_duration
	_target_path = scene_path

	# 锁定输入，防止转场期间玩家操作
	InputManager.set_input_lock(true)

	# 创建并添加过渡覆盖层
	_overlay = TRANSITION_OVERLAY_SCENE.instantiate()
	get_tree().root.add_child(_overlay)

	# 淡入黑色遮罩
	await _overlay.fade_in(_fade_duration)

	# 若淡入过程中加载被取消，则清理覆盖层
	if not is_loading:
		_cleanup_overlay()
		return

	# 启动异步加载
	_start_async_load()

## 功能：取消当前正在进行的加载
func cancel_loading() -> void:
	if not is_loading:
		return
	_load_failed = true
	is_loading = false
	_target_path = ""
	set_process(false)
	_cleanup_overlay()
	InputManager.set_input_lock(false)
	if DEBUG_MODE:
		print("SceneLoader: 加载已取消")

# ========================== 内部方法模块 ==========================
## 功能：启动异步加载请求，进入 _process 轮询进度
func _start_async_load() -> void:
	var err := ResourceLoader.load_threaded_request(_target_path)
	if err != OK:
		_abort("SceneLoader: 无法启动异步加载 [%s] -> 错误码 %d" % [_target_path, err])
		return

	set_process(true)

## 功能：每帧轮询异步加载进度（仅在加载中有效）
func _process(_delta: float) -> void:
	if _target_path.is_empty():
		return

	var progress: Array[float] = []
	var status := ResourceLoader.load_threaded_get_status(_target_path, progress)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var p: float = 0.0
			if progress.size() > 0:
				p = progress[0]
			# 更新覆盖层进度显示（若覆盖层支持 set_progress 方法）
			if _overlay and _overlay.has_method("set_progress"):
				_overlay.set_progress(p)
			loading_progress.emit(p)

		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			_on_load_complete()

		ResourceLoader.THREAD_LOAD_FAILED:
			set_process(false)
			_abort("SceneLoader: 异步加载失败 [%s]" % _target_path)

## 功能：加载完成后切换场景并执行淡出
func _on_load_complete() -> void:
	# 1) 通知旧场景即将被卸载（用于清理工作）
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_method("on_before_scene_unload"):
		current_scene.on_before_scene_unload()

	# 2) 摘除相机：从当前场景迁移到 SceneLoader（autoload 跨场景存活）
	_detach_camera()

	# 3) 获取已加载完成的 PackedScene 资源
	var packed := ResourceLoader.load_threaded_get(_target_path) as PackedScene
	if packed == null:
		_abort("加载的资源不是 PackedScene [%s]" % _target_path)
		return

	# 4) 切换场景（旧场景被销毁，但相机已安全挂在 SceneLoader 下）
	var err = get_tree().change_scene_to_packed(packed)
	if err != OK:
		_abort("场景切换失败，错误码：%d" % err)
		return

	# 5) 等待新场景完成 _ready（至少一帧，确保节点树稳定）
	await get_tree().process_frame

	# 6) 将暂存的相机挂载到新场景根节点下
	_attach_camera_to_new_scene()

	# 7) 淡出覆盖层（完成后才解锁输入）
	await _fade_out_overlay()

	# 8) 解锁输入，允许玩家操作
	InputManager.set_input_lock(false)

	# 9) 完成清理并发射完成信号
	_cleanup_overlay()
	is_loading = false
	_target_path = ""
	loading_completed.emit()
	if DEBUG_MODE:
		print("[SceneLoader] 场景加载完成 -> ", get_tree().current_scene.name)

## 功能：淡出覆盖层
func _fade_out_overlay() -> void:
	if not _overlay or not is_instance_valid(_overlay):
		return
	if _overlay.has_method("hide_progress"):
		_overlay.hide_progress()
	if _overlay.has_method("fade_out"):
		await _overlay.fade_out(_fade_duration)

## 功能：加载失败时的错误处理与清理
## 参数：error_msg (String) - 错误描述信息
func _abort(error_msg: String) -> void:
	push_error("SceneLoader: " + error_msg)
	loading_failed.emit(error_msg)
	_cleanup_overlay()
	InputManager.set_input_lock(false)
	is_loading = false
	_target_path = ""
	set_process(false)

## 功能：清理覆盖层节点
func _cleanup_overlay() -> void:
	if _overlay and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null

# ========================== 相机迁移模块 ==========================
## 功能：从当前场景树中查找等距相机，摘除并暂存到 SceneLoader 下
## 说明：若未找到（如主菜单等无相机场景），_camera 保持 null，跳过迁移
func _detach_camera() -> void:
	# 优先使用已有缓存引用
	if _camera and is_instance_valid(_camera):
		if _camera.is_inside_tree():
			_camera.reparent(self)
			if DEBUG_MODE:
				print("SceneLoader: 相机已迁入 SceneLoader（缓存引用）")
		# 引用有效但不在场景树中（已被摘除过），不需要再处理
		return

	# 无缓存，在场景树中按组（"isometric_camera"）查找
	var found := get_tree().get_first_node_in_group("isometric_camera") as IsometricCamera
	if found:
		_camera = found
		_camera.reparent(self)
		if DEBUG_MODE:
			print("SceneLoader: 发现相机并迁入 SceneLoader")
	else:
		_camera = null
		if DEBUG_MODE:
			print("SceneLoader: 场景中无等距相机，跳过迁移")

## 功能：将暂存的相机挂载到新场景的根节点下
func _attach_camera_to_new_scene() -> void:
	if not _camera or not is_instance_valid(_camera):
		return

	var new_root: Node = get_tree().current_scene
	if not new_root:
		push_warning("SceneLoader: 新场景根节点为空，相机保持挂在 SceneLoader 下")
		return

	_camera.reparent(new_root)
	if DEBUG_MODE:
		print("SceneLoader: 相机已迁入新场景: ", new_root.name)
