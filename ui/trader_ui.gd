extends Control
# 商人交易界面

class_name TraderUI

@onready var trader_list: ItemList = $Panel/VBoxContainer/HBoxContainer/TraderList
@onready var item_list: ItemList = $Panel/VBoxContainer/HBoxContainer/ItemListSection/ItemList
@onready var item_details: VBoxContainer = $Panel/VBoxContainer/HBoxContainer/DetailsSection
@onready var buy_button: Button = $Panel/VBoxContainer/HBoxContainer/DetailsSection/BuyButton
@onready var sell_button: Button = $Panel/VBoxContainer/HBoxContainer/DetailsSection/SellButton
@onready var money_label: Label = $Panel/VBoxContainer/MoneyLabel
@onready var reputation_label: Label = $Panel/VBoxContainer/ReputationLabel
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

var current_trader: String = ""
var selected_item: Dictionary = {}
var trader_items: Array = []

# 商人物品数据库（简化版）
var trader_catalogs = {
	"prapor": {
		"name": "Prapor",
		"currency": "rubles",
		"items": [
			{"id": "ak74n", "price": 25000, "level_required": 1},
			{"id": "ammo_545x39_ps", "price": 150, "level_required": 1},
			{"id": "6b2_armor", "price": 12000, "level_required": 1},
			{"id": "ssh68_helmet", "price": 8000, "level_required": 1},
			{"id": "pm_pistol", "price": 3500, "level_required": 1},
			{"id": "bandage", "price": 500, "level_required": 1}
		]
	},
	"therapist": {
		"name": "Therapist",
		"currency": "rubles",
		"items": [
			{"id": "ai2_medkit", "price": 2500, "level_required": 1},
			{"id": "salewa_first_aid", "price": 12000, "level_required": 2},
			{"id": "ifak_tactical", "price": 18000, "level_required": 3},
			{"id": "water_bottle", "price": 600, "level_required": 1},
			{"id": "army_crackers", "price": 800, "level_required": 1}
		]
	},
	"skier": {
		"name": "Skier",
		"currency": "dollars",
		"items": [
			{"id": "mbss_backpack", "price": 50, "level_required": 1},
			{"id": "attack2_backpack", "price": 200, "level_required": 2},
			{"id": "mp5", "price": 300, "level_required": 2}
		]
	},
	"peacekeeper": {
		"name": "Peacekeeper",
		"currency": "dollars",
		"items": [
			{"id": "m4a1", "price": 600, "level_required": 2},
			{"id": "ammo_556x45_m855", "price": 3, "level_required": 2},
			{"id": "gen4_hmk", "price": 900, "level_required": 3}
		]
	},
	"mechanic": {
		"name": "Mechanic",
		"currency": "euros",
		"items": [
			{"id": "ulach_helmet", "price": 400, "level_required": 3},
			{"id": "graphics_card", "price": 1500, "level_required": 2}
		]
	},
	"ragman": {
		"name": "Ragman",
		"currency": "rubles",
		"items": [
			{"id": "face_cover", "price": 5000, "level_required": 1},
			{"id": "ears", "price": 15000, "level_required": 2}
		]
	},
	"jaeger": {
		"name": "Jaeger",
		"currency": "rubles",
		"items": [
			{"id": "special_ammo", "price": 500, "level_required": 2}
		]
	}
}

func _ready():
	close_button.pressed.connect(close_trader)
	trader_list.item_selected.connect(_on_trader_selected)
	item_list.item_selected.connect(_on_item_selected)
	buy_button.pressed.connect(_on_buy_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	
	populate_trader_list()
	visible = false
	print("商人UI已加载")

func toggle():
	if visible:
		close_trader()
	else:
		open_trader()

func open_trader():
	visible = true
	GameManager.change_state(GameManager.GameState.TRADING)
	update_money_display()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_trader():
	visible = false
	GameManager.change_state(GameManager.GameState.HIDEOUT)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func populate_trader_list():
	trader_list.clear()
	for trader_id in trader_catalogs:
		var trader_data = trader_catalogs[trader_id]
		var player_trader = PlayerData.traders.get(trader_id, {"level": 1})
		var display_text = "%s (Lv.%d)" % [trader_data.name, player_trader.level]
		trader_list.add_item(display_text)
		trader_list.set_item_metadata(trader_list.item_count - 1, trader_id)

func _on_trader_selected(index: int):
	current_trader = trader_list.get_item_metadata(index)
	update_reputation_display()
	populate_item_list()

func populate_item_list():
	item_list.clear()
	trader_items.clear()
	
	if current_trader == "" or not trader_catalogs.has(current_trader):
		return
	
	var catalog = trader_catalogs[current_trader]
	var player_trader = PlayerData.traders.get(current_trader, {"level": 1})
	
	for item_entry in catalog.items:
		if player_trader.level >= item_entry.level_required:
			var item_data = LootSystem.item_database.get(item_entry.id, {})
			if not item_data.is_empty():
				var display_text = "%s - %s%d" % [
					item_data.get("name", "未知"),
					get_currency_symbol(catalog.currency),
					item_entry.price
				]
				item_list.add_item(display_text)
				
				var full_data = item_data.duplicate()
				full_data["trader_price"] = item_entry.price
				full_data["currency"] = catalog.currency
				trader_items.append(full_data)

func get_currency_symbol(currency: String) -> String:
	match currency:
		"rubles": return "₽"
		"dollars": return "$"
		"euros": return "€"
		_: return "₽"

func _on_item_selected(index: int):
	if index < 0 or index >= trader_items.size():
		return
	
	selected_item = trader_items[index]
	show_item_details(selected_item)

func show_item_details(item: Dictionary):
	# 清除旧内容
	for child in item_details.get_children():
		if child != buy_button and child != sell_button:
			child.queue_free()
	
	# 物品名称
	var name_label = Label.new()
	name_label.text = item.get("name", "未知物品")
	name_label.add_theme_font_size_override("font_size", 20)
	item_details.add_child(name_label)
	
	# 物品信息
	var info_label = Label.new()
	var info_text = "类型: %s\n" % item.get("type", "未知")
	info_text += "重量: %.2f kg\n" % item.get("weight", 0)
	info_text += "价格: %s%d\n" % [get_currency_symbol(item.get("currency", "rubles")), item.get("trader_price", 0)]
	
	if item.has("damage"):
		info_text += "伤害: %.0f\n" % item.get("damage")
	if item.has("armor_class"):
		info_text += "护甲等级: %d\n" % item.get("armor_class")
	
	info_label.text = info_text
	item_details.add_child(info_label)
	
	# 移动按钮到底部
	item_details.move_child(buy_button, -1)
	item_details.move_child(sell_button, -1)
	
	buy_button.visible = true
	sell_button.visible = false

func _on_buy_pressed():
	if selected_item.is_empty():
		return
	
	var price = selected_item.get("trader_price", 0)
	var currency = selected_item.get("currency", "rubles")
	
	if PlayerData.remove_money(currency, price):
		# 创建物品实例
		var new_item = selected_item.duplicate()
		new_item.erase("trader_price")
		new_item.erase("currency")
		
		# 添加到仓库
		if InventoryManager.add_item_to_inventory(new_item):
			print("购买成功:", new_item.get("name"))
			update_money_display()
			
			# 增加商人经验
			increase_trader_rep(current_trader, price / 10000.0)
		else:
			# 背包满了，退款
			PlayerData.add_money(currency, price)
			print("背包已满，无法购买")
	else:
		print("资金不足")

func _on_sell_pressed():
	# TODO: 实现出售功能
	pass

func increase_trader_rep(trader_id: String, amount: float):
	if PlayerData.traders.has(trader_id):
		PlayerData.traders[trader_id].rep += amount
		
		# 检查升级
		var current_level = PlayerData.traders[trader_id].level
		var required_rep = current_level * 10.0
		
		if PlayerData.traders[trader_id].rep >= required_rep and current_level < 4:
			PlayerData.traders[trader_id].level += 1
			print("商人 %s 好感度提升到等级 %d!" % [trader_catalogs[trader_id].name, current_level + 1])
			populate_trader_list()  # 刷新列表显示新物品

func update_money_display():
	money_label.text = "₽%d | $%d | €%d" % [PlayerData.rubles, PlayerData.dollars, PlayerData.euros]

func update_reputation_display():
	if current_trader == "":
		reputation_label.text = ""
		return
	
	var trader_data = PlayerData.traders.get(current_trader, {"level": 1, "rep": 0.0})
	var trader_info = trader_catalogs[current_trader]
	reputation_label.text = "%s - 等级 %d (声望: %.1f)" % [
		trader_info.name,
		trader_data.level,
		trader_data.rep
	]
