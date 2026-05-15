# ==============================================================================
#   AudioManager.gd
#   功能：音频管理器，管理音效、背景音乐、音量设置，支持音量持久化、音效池、
#        音乐淡入淡出、跨场景自动加载（通过 Autoload 系统）。
#   自动加载配置：在 Project -> Project Settings -> Autoload 中添加，命名为 AudioManager
# ==============================================================================
extends Node

# ========================== 常量定义模块 ==========================
## 音频总线索引（需根据项目实际总线顺序调整）
const BUS_MASTER: int = 0   ## 主音量总线索引
const BUS_MUSIC: int  = 1   ## 音乐总线索引
const BUS_SFX: int    = 2   ## 音效总线索引
const BUS_UI: int     = 3   ## UI 音效总线索引

## 默认音量（范围 0.0 - 1.0）
const DEFAULT_MASTER_VOLUME: float = 1.0  ## 默认主音量
const DEFAULT_MUSIC_VOLUME:  float = 0.8  ## 默认音乐音量
const DEFAULT_SFX_VOLUME:    float = 0.9  ## 默认音效音量
const DEFAULT_UI_VOLUME:     float = 0.8  ## 默认 UI 音效音量

## 20/ln(10)
const DB_CONVERSION_FACTOR: float = 20.0 / log(10.0)

# ========================== 节点引用模块 ==========================
## 背景音乐播放器（需在场景中创建或动态生成）
var music_player: AudioStreamPlayer
## 音效播放器池（数组存储多个 AudioStreamPlayer）
var sfx_players: Array[AudioStreamPlayer] = []
## UI 音效专用播放器（避免与普通音效干扰）
var ui_sfx_player: AudioStreamPlayer

# ========================== 内部变量模块 ==========================
## 当前正在播放的背景音乐资源路径
var current_music_path: String = ""
## 音乐是否处于暂停状态
var is_music_paused: bool = false
## 音效播放器轮询索引（用于分配播放器）
var sfx_player_index: int = 0
## 最大同时音效数量（决定音效池大小）
const MAX_SFX_PLAYERS: int = 8

## 主音量（0.0 - 1.0），会持久化存储
var master_volume: float = DEFAULT_MASTER_VOLUME
## 音乐音量（0.0 - 1.0），会持久化存储
var music_volume: float = DEFAULT_MUSIC_VOLUME
## 音效音量（0.0 - 1.0），会持久化存储
var sfx_volume: float = DEFAULT_SFX_VOLUME
## UI 音效音量（0.0 - 1.0），会持久化存储
var ui_volume: float = DEFAULT_UI_VOLUME

# ========================== 生命周期模块 ==========================
## 功能：节点初始化，创建音效池、加载音量设置、连接游戏状态信号
func _ready() -> void:
	# TODO: 项目最后才处理音频管理，因此，现在把初始化方法全部注释掉
	# 创建 SFX 播放器池
	#_create_sfx_player_pool()
	## 加载音量设置
	#_load_volume_settings()
	## 应用初始音量
	#_apply_volume_settings()
	# 监听游戏状态变化（用于暂停/恢复音乐）
	# TODO: 取消注释并确保 GameManager 存在且包含 game_state_changed 信号
	#if GameManager and GameManager.has_signal("game_state_changed"):
		#GameManager.game_state_changed.connect(_on_game_state_changed)
	print("AudioManager: 音频管理器初始化完成")

## 功能：创建 SFX 播放器池
## 说明：生成 MAX_SFX_PLAYERS 个 AudioStreamPlayer 子节点，用于同时播放多个音效
func _create_sfx_player_pool() -> void:
	for i in range(MAX_SFX_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % i
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

# ========================== 音量管理模块 ==========================
## 功能：从配置文件加载音量设置
## 说明：从 user://audio_settings.cfg 读取，若文件不存在则保存默认值
func _load_volume_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://audio_settings.cfg")

	if err == OK:
		master_volume = config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)
		music_volume  = config.get_value("audio", "music_volume",  DEFAULT_MUSIC_VOLUME)
		sfx_volume    = config.get_value("audio", "sfx_volume",    DEFAULT_SFX_VOLUME)
		ui_volume     = config.get_value("audio", "ui_volume",     DEFAULT_UI_VOLUME)
	else:
		# 配置文件不存在，使用默认值并保存
		_save_volume_settings()

## 功能：保存音量设置到配置文件
## 说明：写入 user://audio_settings.cfg，用于跨会话持久化
func _save_volume_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume",  music_volume)
	config.set_value("audio", "sfx_volume",    sfx_volume)
	config.set_value("audio", "ui_volume",     ui_volume)
	config.save("user://audio_settings.cfg")

## 功能：应用当前音量设置到音频总线
## 说明：将线性音量值转换为分贝并设置到对应的 AudioServer 总线
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

	# UI 音效音量
	AudioServer.set_bus_volume_db(BUS_UI, linear_to_db(ui_volume))
	AudioServer.set_bus_mute(BUS_UI, ui_volume <= 0.01)

## 功能：将线性音量值转换为分贝（dB）
## 参数：linear (float) - 线性音量，范围 0.0 - 1.0
## 返回值：float - 对应的分贝值，静音时返回 -80.0 dB
func linear_to_db(linear: float) -> float:
	if linear <= 0:
		return -80.0  # 静音，Godot 最小有效值为 -80 dB
	return log(linear) * DB_CONVERSION_FACTOR  # 20 * log10(linear)

# ========================== 公共接口：音量控制模块 ==========================
## 功能：设置主音量
## 参数：volume (float) - 目标音量，范围 0.0 - 1.0
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	_apply_volume_settings()
	_save_volume_settings()

## 功能：设置音乐音量
## 参数：volume (float) - 目标音量，范围 0.0 - 1.0
func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	_apply_volume_settings()
	_save_volume_settings()

## 功能：设置音效音量
## 参数：volume (float) - 目标音量，范围 0.0 - 1.0
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	_apply_volume_settings()
	_save_volume_settings()

## 功能：设置 UI 音效音量
## 参数：volume (float) - 目标音量，范围 0.0 - 1.0
func set_ui_volume(volume: float) -> void:
	ui_volume = clamp(volume, 0.0, 1.0)
	_apply_volume_settings()
	_save_volume_settings()

## 功能：获取当前所有音量设置
## 返回值：Dictionary - 包含 master、music、sfx、ui 四个音量的字典
func get_volume_settings() -> Dictionary:
	return {
		"master": master_volume,
		"music":  music_volume,
		"sfx":    sfx_volume,
		"ui":     ui_volume
	}

# ========================== 公共接口：音乐控制模块 ==========================
## 功能：播放背景音乐
## 参数：music_path (String) - 音乐资源路径；fade_in (float) - 淡入时间（秒），默认 0.5
func play_music(music_path: String, fade_in: float = 0.5) -> void:
	if current_music_path == music_path and music_player.playing:
		return  # 已经在播放同一首音乐，避免重复加载

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

## 功能：停止背景音乐
## 参数：fade_out (float) - 淡出时间（秒），默认 0.5
func stop_music(fade_out: float = 0.5) -> void:
	if fade_out > 0 and music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -30.0, fade_out)
		tween.tween_callback(music_player.stop)
	else:
		music_player.stop()

	current_music_path = ""

## 功能：暂停或恢复背景音乐
## 参数：pause (bool) - true 表示暂停，false 表示恢复
func pause_music(pause: bool) -> void:
	if pause:
		music_player.stream_paused = true
		is_music_paused = true
	else:
		music_player.stream_paused = false
		is_music_paused = false

## 功能：切换音乐（带淡出淡入交叉淡变）
## 参数：new_music_path (String) - 新音乐资源路径；fade_duration (float) - 淡变总时长（秒），默认 1.0
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

# ========================== 公共接口：音效控制模块 ==========================
## 功能：播放一个普通音效（从音效池中分配播放器）
## 参数：sfx_path (String) - 音效资源路径；volume_scale (float) - 音量缩放系数，默认 1.0；pitch_scale (float) - 音高缩放系数，默认 1.0
func play_sfx(sfx_path: String, volume_scale: float = 1.0, pitch_scale: float = 1.0) -> void:
	var stream = load(sfx_path)
	if not stream:
		push_warning("AudioManager: 无法加载音效文件: ", sfx_path)
		return

	# 获取可用的 SFX 播放器
	var player = _get_available_sfx_player()
	if not player:
		return  # 所有播放器都在使用中（理论上总会返回一个）

	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume * volume_scale)
	player.pitch_scale = pitch_scale
	player.play()

## 功能：播放 UI 专用音效（使用独立播放器，避免与普通音效互相干扰）
## 参数：sfx_path (String) - UI 音效资源路径；volume_scale (float) - 音量缩放系数，默认 1.0
func play_ui_sfx(sfx_path: String, volume_scale: float = 1.0) -> void:
	var stream = load(sfx_path)
	if not stream:
		push_warning("AudioManager: 无法加载UI音效文件: ", sfx_path)
		return

	ui_sfx_player.stream = stream
	ui_sfx_player.volume_db = linear_to_db(ui_volume * volume_scale)
	ui_sfx_player.play()

## 功能：停止所有正在播放的音效（包括普通音效和 UI 音效）
func stop_all_sfx() -> void:
	for player in sfx_players:
		player.stop()
	ui_sfx_player.stop()

## 功能：获取一个可用的 SFX 播放器（从池中轮询分配）
## 返回值：AudioStreamPlayer - 可用的播放器实例
func _get_available_sfx_player() -> AudioStreamPlayer:
	# 轮询查找空闲播放器
	for i in range(MAX_SFX_PLAYERS):
		var index = (sfx_player_index + i) % MAX_SFX_PLAYERS
		var sfx_player = sfx_players[index]
		if not sfx_player.playing:
			sfx_player_index = (index + 1) % MAX_SFX_PLAYERS
			return sfx_player

	# 所有播放器都在使用中，强制复用下一个（会打断最旧的音效）
	var player = sfx_players[sfx_player_index]
	sfx_player_index = (sfx_player_index + 1) % MAX_SFX_PLAYERS
	player.stop()  # 停止当前播放，强制复用
	return player

# ========================== 游戏状态回调模块 ==========================
## 功能：游戏状态变化时的回调，用于自动暂停/恢复音乐
## 参数：new_state (GameManager.GameState) - 新状态；_old_state - 旧状态（未使用）
## TODO: 需要 GameManager 存在并定义 GameState 枚举及 game_state_changed 信号
func _on_game_state_changed(new_state: GameManager.GameState, _old_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.PAUSED:
			# 游戏暂停时，暂停音乐（但不停止，便于恢复）
			pause_music(true)
		GameManager.GameState.IN_GAME:
			# 恢复游戏时，恢复音乐播放
			if is_music_paused:
				pause_music(false)
		_:
			pass

# ========================== 调试与工具函数模块 ==========================
## 功能：打印当前音频系统状态（调试用）
func print_audio_status() -> void:
	print("=== 音频状态 ===")
	print("当前音乐: ", current_music_path if current_music_path else "无")
	print("音乐播放中: ", music_player.playing)
	print("音乐暂停: ", music_player.stream_paused)
	print("活跃SFX播放器: ", _count_active_sfx_players())
	print("音量设置: ", get_volume_settings())
	print("================")

## 功能：统计当前正在播放的 SFX 播放器数量
## 返回值：int - 活跃的音效播放器数量
func _count_active_sfx_players() -> int:
	var count = 0
	for player in sfx_players:
		if player.playing:
			count += 1
	return count

## 功能：将所有音量重置为项目默认值
func reset_to_defaults() -> void:
	master_volume = DEFAULT_MASTER_VOLUME
	music_volume  = DEFAULT_MUSIC_VOLUME
	sfx_volume    = DEFAULT_SFX_VOLUME
	ui_volume     = DEFAULT_UI_VOLUME

	_apply_volume_settings()
	_save_volume_settings()
	print("AudioManager: 音频设置已重置为默认值")
