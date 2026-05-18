# ==============================================================================
#   relic_icon.gd
#   功能：遗物图标组件，用于 HUD 遗物栏显示单个遗物的图标和稀有度边框。
# ==============================================================================
extends PanelContainer
class_name RelicIcon

# ========================== 节点引用 ==========================
@onready var _icon_rect: TextureRect = $IconRect

# ========================== 公共 API ==========================
## 功能：设置遗物数据显示
func setup(relic: RelicData) -> void:
	if relic == null:
		return
	# 设置图标
	if _icon_rect:
		_icon_rect.texture = relic.icon
	# 设置稀有度边框颜色
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.7)
	style.border_color = _get_rarity_color(relic.rarity)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 2
	style.content_margin_right = 2
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	add_theme_stylebox_override("panel", style)
	# 工具提示
	tooltip_text = "%s\n%s" % [relic.display_name, relic.description]

func _get_rarity_color(rarity: RelicData.Rarity) -> Color:
	match rarity:
		RelicData.Rarity.COMMON: return Color(0.6, 0.6, 0.6)
		RelicData.Rarity.UNCOMMON: return Color(0.2, 0.8, 0.2)
		RelicData.Rarity.RARE: return Color(0.3, 0.5, 1.0)
		RelicData.Rarity.EPIC: return Color(0.7, 0.3, 1.0)
		RelicData.Rarity.LEGENDARY: return Color(1.0, 0.8, 0.2)
		_: return Color(0.5, 0.5, 0.5)
