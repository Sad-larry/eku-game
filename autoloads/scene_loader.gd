# autoloads/scene_loader.gd
## 场景加载器：异步加载场景 + 淡入淡出过渡 + 进度显示
extends Node

# ========================== 信号 ==========================
## 加载进度更新 (0.0 ~ 1.0)
signal loading_progress(progress: float)
## 场景加载完成（新场景已激活）
signal loading_completed()
## 加载失败（error_message 说明原因）
signal loading_failed(error_message: String)

# ========================== 常量 ==========================
## 调试模式
const DEBUG_MODE: bool = true

# 覆盖层场景
const TRANSITION_OVERLAY_SCENE = preload("uid://cyr13g8iathws")
# ========================== 变量 ==========================
## 当前是否正在加载中
var is_loading: bool = false

var _overlay: Node
var _target_path: String = ""
var _fade_duration: float = 0.3

## 加载失败标志，用于中断后续流程
var _load_failed: bool = false

# ========================== 公共 API ==========================
## 异步加载并切换到目标场景
## @param scene_path: 场景资源路径（如 "res://scenes/main.tscn"）
## @param fade_duration: 淡入/淡出时长（秒）
func change_scene(scene_path: String, fade_duration: float = 0.3) -> void:
	if is_loading:
		if DEBUG_MODE:
			print("SceneLoader: 当前已在加载中，忽略重复请求")
		return

	is_loading = true
	_load_failed = false
	_fade_duration = fade_duration
	_target_path = scene_path

	# 创建覆盖层
	_overlay = TRANSITION_OVERLAY_SCENE.instantiate()
	get_tree().root.add_child(_overlay)

	# 淡入黑色遮罩
	await _overlay.fade_in(_fade_duration)
	
	# 如果淡入过程中游戏退出或者其他原因导致加载被取消，检查标志
	if not is_loading:
		_cleanup_overlay()
		return
		
	# 启动异步加载
	_start_async_load()

## 取消当前加载
func cancel_loading() -> void:
	if not is_loading:
		return
	_load_failed = true
	is_loading = false
	_target_path = ""
	set_process(false)
	_cleanup_overlay()
	if DEBUG_MODE:
		print("SceneLoader: 加载已取消")
		
# ========================== 内部方法 ==========================
## 启动异步加载请求，进入 _process 轮询进度
func _start_async_load() -> void:
	var err := ResourceLoader.load_threaded_request(_target_path)
	if err != OK:
		_abort("SceneLoader: 无法启动异步加载 [%s] → 错误码 %d" % [_target_path, err])
		return

	set_process(true)


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
			# 更新覆盖层进度（如果覆盖层有 set_progress 方法）
			if _overlay and _overlay.has_method("set_progress"):
				_overlay.set_progress(p)
			loading_progress.emit(p)

		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			_on_load_complete()

		ResourceLoader.THREAD_LOAD_FAILED:
			set_process(false)
			_abort("SceneLoader: 异步加载失败 [%s]" % _target_path)


## 加载完成：切换场景 + 淡出
func _on_load_complete() -> void:
	# 1) 通知旧场景即将被卸载
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_method("on_before_scene_unload"):
		current_scene.on_before_scene_unload()

	# 2) 获取加载好的 PackedScene
	var packed := ResourceLoader.load_threaded_get(_target_path) as PackedScene
	if packed == null:
		_abort("加载的资源不是 PackedScene [%s]" % _target_path)
		return

	# 3) 切换场景
	var err = get_tree().change_scene_to_packed(packed)
	if err != OK:
		_abort("场景切换失败，错误码：%d" % err)
		return

	# 4) 等待新场景完成 _ready（至少一帧）
	await get_tree().process_frame

	# 5) 淡出覆盖层
	if _overlay and is_instance_valid(_overlay) and _overlay.has_method("fade_out"):
		await _overlay.fade_out(_fade_duration)
	else:
		# 防御：若覆盖层无效，直接清理
		_cleanup_overlay()

	# 6) 完成清理并发射信号
	_cleanup_overlay()
	is_loading = false
	_target_path = ""
	loading_completed.emit()
	if DEBUG_MODE:
		print("[SceneLoader] 场景加载完成 → ", get_tree().current_scene.name)


## 加载失败时的清理
func _abort(error_msg: String) -> void:
	push_error("SceneLoader: " + error_msg)
	loading_failed.emit(error_msg)
	_cleanup_overlay()
	is_loading = false
	_target_path = ""
	set_process(false)
	

## 清理覆盖层节点
func _cleanup_overlay() -> void:
	if _overlay and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null
