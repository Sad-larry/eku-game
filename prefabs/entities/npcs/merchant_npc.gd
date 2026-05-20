# ==============================================================================
#   merchant_npc.gd
#   功能：商人 NPC 控制器。按 F 交互打开商店 UI。
# ==============================================================================
extends StaticBody2D
class_name MerchantNPC

@onready var interactable: InteractableArea = $InteractableArea
@onready var sprite: Sprite2D = $Sprite2D

## 商人所在的环数（由 Spawner 生成时设置）
var ring: int = 0

func _ready() -> void:
	interactable.prompt_text = "按 F 打开商店"
	interactable.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	var shop_ui := UIManager.open_ui("merchant_shop")
	if shop_ui and shop_ui.has_method("setup"):
		shop_ui.setup(ring, RunManager.current_layer)
