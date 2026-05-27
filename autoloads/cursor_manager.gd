# ==============================================================================
#   cursor_manager.gd
#   功能：鼠标图标管理器（Autoload 单例）。
#        统一管理鼠标图标的切换（默认/攻击/技能/交互等状态），
#        后续可扩展自定义鼠标图标纹理。
# ==============================================================================
extends Node

# ========================== 常量定义模块 ==========================
## 模块启用开关（后期系统，暂时禁用）
const ENABLED: bool = false

# ========================== 枚举定义模块 ==========================
## 鼠标模式枚举
enum CursorMode {
	DEFAULT,    # 默认鼠标
	ATTACK,     # 攻击模式（可攻击目标时）
	SKILL,      # 技能模式（释放技能时）
	INTERACT,   # 交互模式（靠近可交互物体时）
	DISABLED,   # 禁用模式（不可操作时）
}

# ========================== 变量定义模块 ==========================
## 当前鼠标模式
var _current_mode: CursorMode = CursorMode.DEFAULT

## 自定义鼠标图标纹理（后续可扩展）
## key = CursorMode, value = Texture2D
var _cursor_textures: Dictionary = {}

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	if not ENABLED:
		print("CursorManager: 已禁用")
		return
	_apply_cursor(CursorMode.DEFAULT)

# ========================== 公共 API 模块 ==========================
## 功能：设置鼠标模式
## 参数：mode (CursorMode) - 目标鼠标模式
func set_cursor_mode(mode: CursorMode) -> void:
	if mode == _current_mode:
		return
	_current_mode = mode
	_apply_cursor(mode)

## 功能：获取当前鼠标模式
## 返回值：CursorMode - 当前模式
func get_cursor_mode() -> CursorMode:
	return _current_mode

## 功能：注册自定义鼠标图标
## 参数：mode (CursorMode) - 对应模式；texture (Texture2D) - 图标纹理
func register_cursor_texture(mode: CursorMode, texture: Texture2D) -> void:
	_cursor_textures[mode] = texture

## 功能：重置为默认鼠标
func reset_to_default() -> void:
	set_cursor_mode(CursorMode.DEFAULT)

# ========================== 内部方法 ==========================
func _apply_cursor(mode: CursorMode) -> void:
	if _cursor_textures.has(mode):
		var texture: Texture2D = _cursor_textures[mode]
		Input.set_custom_mouse_cursor(texture, Input.CURSOR_ARROW, Vector2.ZERO)
	else:
		# 没有自定义纹理时使用系统默认
		Input.set_custom_mouse_cursor(null)
