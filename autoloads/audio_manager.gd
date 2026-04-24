# autoloads/audio_manager.gd
# 音频管理器：管理音效、背景音乐、音量设置
# 自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 AudioManager
extends Node

# ========================== 常量定义 ==========================
# 音频总线索引（根据项目设置调整）
const BUS_MASTER: int = 0
const BUS_MUSIC: int = 1
const BUS_SFX: int = 2
const BUS_UI: int = 3

# 默认音量（0.0 - 1.0）
const DEFAULT_MASTER_VOLUME: float = 1.0
const DEFAULT_MUSIC_VOLUME: float = 0.8
const DEFAULT_SFX_VOLUME: float = 0.9
const DEFAULT_UI_VOLUME: float = 0.8

# ========================== 节点引用 ==========================
@onready var music_player: AudioStreamPlayer
@onready var sfx_players: Array[AudioStreamPlayer] = []
@onready var ui_sfx_player: AudioStreamPlayer

# ========================== 变量定义 ==========================
var current_music_path: String = ""
var is_music_paused: bool = false
var sfx_player_index: int = 0
const MAX_SFX_PLAYERS: int = 8  # 最大同时音效数量

# 音量设置（持久化）
var master_volume: float = DEFAULT_MASTER_VOLUME
var music_volume: float = DEFAULT_MUSIC_VOLUME
var sfx_volume: float = DEFAULT_SFX_VOLUME
var ui_volume: float = DEFAULT_UI_VOLUME

# ========================== 初始化 ==========================
func _ready() -> void:
	# 创建SFX播放器池
	#_create_sfx_player_pool()
	# 加载音量设置
	#_load_volume_settings()
	# 应用初始音量
	#_apply_volume_settings()
	# 监听游戏状态变化（用于暂停/恢复音乐）
	#if GameManager and GameManager.has_signal("game_state_changed"):
		#GameManager.game_state_changed.connect(_on_game_state_changed)
	#print("AudioManager: 音频管理器初始化完成")
	pass

## 创建SFX播放器池
func _create_sfx_player_pool() -> void:
	for i in range(MAX_SFX_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % i
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

# ========================== 音量管理 ==========================
## 加载音量设置（从ConfigFile）
func _load_volume_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://audio_settings.cfg")

	if err == OK:
		master_volume = config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)
		music_volume = config.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME)
		sfx_volume = config.get_value("audio", "sfx_volume", DEFAULT_SFX_VOLUME)
		ui_volume = config.get_value("audio", "ui_volume", DEFAULT_UI_VOLUME)
	else:
		# 使用默认值
		_save_volume_settings()

## 保存音量设置
func _save_volume_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "ui_volume", ui_volume)
	config.save("user://audio_settings.cfg")

## 应用音量设置到音频总线
func _apply_volume_settings() -> void:
	# 主音量
	AudioServer.set_bus_volume_db(BUS_MASTER, linear_to_db(master_volume))
	AudioServer.set_bus_mute(BUS_MASTER, master_volume <= 0.01)

	# 音乐音量
	AudioServer.set_bus_volume_db(BUS_MUSIC, linear_to_db(music_volume))
	AudioServer.set_bus_mute(BUS_MUSIC, music_volume <= 0.01)

	# 音效音量
	AudioServer.set_bus_volume_db(BUS_SFX, linear_to_db(sfx_volume))
	AudioServer.set_bus_mute(BUS_SFX, sfx_volume <= 0.01)

	# UI音效音量
	AudioServer.set_bus_volume_db(BUS_UI, linear_to_db(ui_volume))
	AudioServer.set_bus_mute(BUS_UI, ui_volume <= 0.01)

## 线性音量转分贝
func linear_to_db(linear: float) -> float:
	if linear <= 0:
		return -80.0  # 静音
	return log(linear) * 8.685889638065036  # 20 * log10(linear)

# ========================== 公共接口：音量控制 ==========================
## 设置主音量
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	_apply_volume_settings()
	_save_volume_settings()

## 设置音乐音量
func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	_apply_volume_settings()
	_save_volume_settings()

## 设置音效音量
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	_apply_volume_settings()
	_save_volume_settings()

## 设置UI音效音量
func set_ui_volume(volume: float) -> void:
	ui_volume = clamp(volume, 0.0, 1.0)
	_apply_volume_settings()
	_save_volume_settings()

## 获取当前音量设置
func get_volume_settings() -> Dictionary:
	return {
		"master": master_volume,
		"music": music_volume,
		"sfx": sfx_volume,
		"ui": ui_volume
	}

# ========================== 公共接口：音乐控制 ==========================
## 播放背景音乐
func play_music(music_path: String, fade_in: float = 0.5) -> void:
	if current_music_path == music_path and music_player.playing:
		return  # 已经在播放同一首音乐

	current_music_path = music_path

	var stream = load(music_path)
	if not stream:
		push_warning("AudioManager: 无法加载音乐文件: ", music_path)
		return

	music_player.stream = stream
	music_player.play()

	# 淡入效果（简化版）
	if fade_in > 0:
		music_player.volume_db = -30.0
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), fade_in)

## 停止背景音乐
func stop_music(fade_out: float = 0.5) -> void:
	if fade_out > 0 and music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -30.0, fade_out)
		tween.tween_callback(music_player.stop)
	else:
		music_player.stop()

	current_music_path = ""

## 暂停/恢复背景音乐
func pause_music(pause: bool) -> void:
	if pause:
		music_player.stream_paused = true
		is_music_paused = true
	else:
		music_player.stream_paused = false
		is_music_paused = false

## 切换音乐（带淡出淡入）
func crossfade_music(new_music_path: String, fade_duration: float = 1.0) -> void:
	if current_music_path == new_music_path:
		return

	# 淡出当前音乐
	if music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -30.0, fade_duration * 0.5)
		tween.tween_callback(func():
			music_player.stop()
			play_music(new_music_path, fade_duration * 0.5)
		)
	else:
		play_music(new_music_path, fade_duration)

# ========================== 公共接口：音效控制 ==========================
## 播放音效
func play_sfx(sfx_path: String, volume_scale: float = 1.0, pitch_scale: float = 1.0) -> void:
	var stream = load(sfx_path)
	if not stream:
		push_warning("AudioManager: 无法加载音效文件: ", sfx_path)
		return

	# 获取可用的SFX播放器
	var player = _get_available_sfx_player()
	if not player:
		return  # 所有播放器都在使用中

	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume * volume_scale)
	player.pitch_scale = pitch_scale
	player.play()

## 播放UI音效
func play_ui_sfx(sfx_path: String, volume_scale: float = 1.0) -> void:
	var stream = load(sfx_path)
	if not stream:
		push_warning("AudioManager: 无法加载UI音效文件: ", sfx_path)
		return

	ui_sfx_player.stream = stream
	ui_sfx_player.volume_db = linear_to_db(ui_volume * volume_scale)
	ui_sfx_player.play()

## 停止所有音效
func stop_all_sfx() -> void:
	for player in sfx_players:
		player.stop()
	ui_sfx_player.stop()

## 获取可用的SFX播放器
func _get_available_sfx_player() -> AudioStreamPlayer:
	# 轮询查找空闲播放器
	for i in range(MAX_SFX_PLAYERS):
		var index = (sfx_player_index + i) % MAX_SFX_PLAYERS
		var sfx_player = sfx_players[index]
		if not sfx_player.playing:
			sfx_player_index = (index + 1) % MAX_SFX_PLAYERS
			return sfx_player

	# 所有播放器都在使用，强制使用下一个
	var player = sfx_players[sfx_player_index]
	sfx_player_index = (sfx_player_index + 1) % MAX_SFX_PLAYERS
	player.stop()  # 停止当前播放
	return player

# ========================== 游戏状态回调 ==========================
func _on_game_state_changed(new_state: GameManager.GameState, _old_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.PAUSED:
			# 暂停音乐（但不停止）
			pause_music(true)
		GameManager.GameState.IN_GAME:
			# 恢复音乐
			if is_music_paused:
				pause_music(false)
		_:
			pass

# ========================== 调试与工具函数 ==========================
## 打印音频状态
func print_audio_status() -> void:
	print("=== 音频状态 ===")
	print("当前音乐: ", current_music_path if current_music_path else "无")
	print("音乐播放中: ", music_player.playing)
	print("音乐暂停: ", music_player.stream_paused)
	print("活跃SFX播放器: ", _count_active_sfx_players())
	print("音量设置: ", get_volume_settings())
	print("================")

## 统计活跃的SFX播放器数量
func _count_active_sfx_players() -> int:
	var count = 0
	for player in sfx_players:
		if player.playing:
			count += 1
	return count

## 重置音频设置到默认值
func reset_to_defaults() -> void:
	master_volume = DEFAULT_MASTER_VOLUME
	music_volume = DEFAULT_MUSIC_VOLUME
	sfx_volume = DEFAULT_SFX_VOLUME
	ui_volume = DEFAULT_UI_VOLUME

	_apply_volume_settings()
	_save_volume_settings()
	print("AudioManager: 音频设置已重置为默认值")
