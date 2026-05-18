# ==============================================================================
#   currency_manager.gd
#   功能：货币存储管理器（Autoload 单例），管理冒险中的当前货币、永久积累货币、
#        累计获得货币三个维度的货币数据。与 SaveManager 协作持久化数据。
#   自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 CurrencyManager
# ==============================================================================
extends Node

# ========================== 信号声明模块 ==========================
## 触发时机：货币数量变化时（当前持有、永久积累任一发生变化）
## 参数：current (int) - 当前持有量，permanent (int) - 永久积累量
signal coin_changed(current: int, permanent: int)

## 触发时机：收集到掉落货币时（由 CoinPickup 拾取时调用）
## 参数：amount (int) - 收集的数量
signal coin_collected(amount: int)

# ========================== 内部变量模块 ==========================
## 当前持有的货币数量（冒险中获得，冒险结束后可转为永久积累）
var _current_coin: int = 0
## 永久积累的货币数量（大厅中可消费的货币）
var _permanent_coin: int = 0
## 累计获得的总货币数量（统计数据，不可消费）
var _lifetime_coin: int = 0

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	SaveManager.data_loaded.connect(_on_save_data_loaded)
	print("CurrencyManager: 货币管理器初始化完成")

# ========================== 存档集成模块 ==========================
## 功能：SaveManager 数据加载后读取货币数据
func _on_save_data_loaded() -> void:
	var currency: Dictionary = SaveManager.get_section("currency", SaveManager.DEFAULT_SECTIONS["currency"])
	_permanent_coin = currency.get("permanent_coin", 0)
	var statistics: Dictionary = SaveManager.get_section("statistics", SaveManager.DEFAULT_SECTIONS["statistics"])
	_lifetime_coin = statistics.get("lifetime_coin", 0)
	print("[CurrencyManager] 永久货币: ", _permanent_coin, " | 累计货币: ", _lifetime_coin)

## 功能：将当前货币数据同步到 SaveManager 并保存
func _sync_to_save() -> void:
	SaveManager.set_section("currency", {
		"permanent_coin": _permanent_coin
	})
	# lifetime_coin 属于 statistics 段
	var stats: Dictionary = SaveManager.get_section("statistics", SaveManager.DEFAULT_SECTIONS["statistics"])
	stats["lifetime_coin"] = _lifetime_coin
	SaveManager.set_section("statistics", stats)
	SaveManager.save_immediately()

# ========================== 公共 API 模块 ==========================
## 功能：增加当前持有货币（冒险中拾取时调用）
## 参数：amount (int) - 增加的数量
func add_coin(amount: int) -> void:
	if amount <= 0:
		return
	_current_coin += amount
	_lifetime_coin += amount
	coin_changed.emit(_current_coin, _permanent_coin)
	coin_collected.emit(amount)

## 功能：从永久积累中消耗货币（大厅中购买/升级时调用）
## 参数：amount (int) - 消耗的数量
## 返回值：bool - true 表示消耗成功，false 表示余额不足
func spend_coin(amount: int) -> bool:
	if amount <= 0:
		return true
	if _permanent_coin < amount:
		return false
	_permanent_coin -= amount
	coin_changed.emit(_current_coin, _permanent_coin)
	_sync_to_save()
	return true

## 功能：获取当前持有的货币数量
## 返回值：int - 当前持有量
func get_current_coin() -> int:
	return _current_coin

## 功能：从冒险货币中消耗（冒险中商店购买时调用）
## 参数：amount (int) - 消耗的数量
## 返回值：bool - true 表示消耗成功，false 表示余额不足
func spend_run_coin(amount: int) -> bool:
	if amount <= 0:
		return true
	if _current_coin < amount:
		return false
	_current_coin -= amount
	coin_changed.emit(_current_coin, _permanent_coin)
	return true

## 功能：获取永久积累的货币数量
## 返回值：int - 永久积累量
func get_permanent_coin() -> int:
	return _permanent_coin

## 功能：将当前持有的货币转为永久积累（冒险结束时调用）
func transfer_to_permanent() -> void:
	if _current_coin <= 0:
		return
	_permanent_coin += _current_coin
	_current_coin = 0
	coin_changed.emit(_current_coin, _permanent_coin)
	_sync_to_save()
	print("[CurrencyManager] 货币已转为永久积累: ", _permanent_coin)

## 功能：重置当前持有的货币为 0（新冒险开始时调用）
func reset_current() -> void:
	_current_coin = 0
	coin_changed.emit(_current_coin, _permanent_coin)
