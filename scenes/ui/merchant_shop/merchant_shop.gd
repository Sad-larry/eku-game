# ==============================================================================
#   merchant_shop.gd
#   功能：冒险中商人商店 UI。显示商品列表，点击购买。
# ==============================================================================
extends CanvasLayer
class_name MerchantShop

signal shop_closed

var _items: Array[MerchantPool.MerchantItem] = []
var _sold_indices: Array[int] = []

@onready var item_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ItemList
@onready var coin_label: Label = $Panel/MarginContainer/VBoxContainer/Header/CoinLabel
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/Header/CloseButton

func _ready() -> void:
	close_button.pressed.connect(_close)
	_update_coin_display()

func setup(ring: int, layer: int) -> void:
	var pool := MerchantPool.new()
	_items = pool.roll_items(4, ring, layer)
	_sold_indices.clear()
	_refresh_list()

func _refresh_list() -> void:
	for child in item_list.get_children():
		child.queue_free()

	for i in _items.size():
		var item: MerchantPool.MerchantItem = _items[i]
		var is_sold := i in _sold_indices
		_create_item_card(item, i, is_sold)

func _create_item_card(item: MerchantPool.MerchantItem, index: int, is_sold: bool) -> void:
	var card := HBoxContainer.new()

	var name_label := Label.new()
	name_label.text = item.display_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(name_label)

	var price_label := Label.new()
	price_label.text = "%d 金币" % item.base_price
	card.add_child(price_label)

	if is_sold:
		var sold_label := Label.new()
		sold_label.text = "已售出"
		sold_label.modulate = Color(0.5, 0.5, 0.5)
		card.add_child(sold_label)
	else:
		var buy_button := Button.new()
		buy_button.text = "购买"
		buy_button.pressed.connect(_on_buy_pressed.bind(index))
		card.add_child(buy_button)

	item_list.add_child(card)

func _on_buy_pressed(index: int) -> void:
	if index in _sold_indices:
		return

	var item: MerchantPool.MerchantItem = _items[index]
	var current_coin: int = CurrencyManager.get_current_coin()

	if current_coin < item.base_price:
		UIManager.show_message("金币不足！")
		return

	CurrencyManager.spend_run_coin(item.base_price)
	_apply_item_effect(item)
	_sold_indices.append(index)
	_refresh_list()
	_update_coin_display()
	EventBus.shop_item_purchased.emit(item.display_name, item.base_price)

func _apply_item_effect(item: MerchantPool.MerchantItem) -> void:
	var player := Global.player
	if player == null:
		return

	match item.item_type:
		MerchantPool.ItemType.HEAL:
			var heal_amount := int(player.health_component.max_health * item.effect_value / 100.0)
			player.health_component.heal(heal_amount)
			UIManager.show_message("回复了 %d 生命值" % heal_amount)
		MerchantPool.ItemType.ENERGY:
			if player.energy_component:
				player.energy_component.restore(item.effect_value)
				UIManager.show_message("回复了 %d 能量" % item.effect_value)
		MerchantPool.ItemType.BUFF:
			UIManager.show_message("获得增益: %s" % item.display_name)
		MerchantPool.ItemType.RELIC:
			UIManager.show_message("获得遗物: %s" % item.display_name)

func _update_coin_display() -> void:
	if coin_label:
		coin_label.text = "金币: %d" % CurrencyManager.get_current_coin()

func _close() -> void:
	shop_closed.emit()
	queue_free()

func get_blocked_input_prefixes() -> Array[String]:
	return ["skill_", "attack"]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		_close()
		get_viewport().set_input_as_handled()
