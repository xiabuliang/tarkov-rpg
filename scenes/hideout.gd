extends Control
# 藏身处（主基地）界面

@onready var player_info_label: Label = $PlayerInfo/Label
@onready var start_raid_button: Button = $Actions/StartRaidButton
@onready var inventory_button: Button = $Actions/InventoryButton
@onready var traders_button: Button = $Actions/TradersButton
@onready var quests_button: Button = $Actions/QuestsButton
@onready var hideout_upgrade_button: Button = $Actions/HideoutUpgradeButton
@onready var heal_button: Button = $Actions/HealButton
@onready var map_list: ItemList = $MapSelection/MapList

var selected_map: String = ""
var available_maps = ["customs", "woods", "factory", "interchange", "reserve", "lighthouse", "streets"]

func _ready():
	start_raid_button.pressed.connect(_on_start_raid)
	inventory_button.pressed.connect(_on_open_inventory)
	traders_button.pressed.connect(_on_open_traders)
	quests_button.pressed.connect(_on_open_quests)
	hideout_upgrade_button.pressed.connect(_on_open_hideout_upgrade)
	heal_button.pressed.connect(_on_heal)
	map_list.item_selected.connect(_on_map_selected)
	
	update_player_info()
	populate_map_list()
	
	print("藏身处已加载")

func update_player_info():
	var info = "等级: %d\n" % PlayerData.level
	info += "经验: %d / %d\n" % [PlayerData.experience, PlayerData.exp_to_next_level]
	info += "卢布: ₽%d\n" % PlayerData.rubles
	info += "生命值: %.0f / %.0f\n" % [PlayerData.current_health, PlayerData.max_health]
	player_info_label.text = info
	
	# 更新治疗按钮状态
	heal_button.disabled = PlayerData.current_health >= PlayerData.max_health

func populate_map_list():
	map_list.clear()
	for map_name in available_maps:
		map_list.add_item(map_name.capitalize())

func _on_map_selected(index: int):
	selected_map = available_maps[index]
	print("选择地图:", selected_map)

func _on_start_raid():
	if selected_map == "":
		print("请先选择地图")
		return
	
	print("开始战局:", selected_map)
	GameManager.start_raid(selected_map)

func _on_open_inventory():
	print("打开仓库")
	GameManager.change_state(GameManager.GameState.INVENTORY)
	# TODO: 显示仓库UI

func _on_open_traders():
	print("打开商人界面")
	GameManager.change_state(GameManager.GameState.TRADING)
	# TODO: 显示商人交易UI

func _on_open_quests():
	print("打开任务面板")
	var quest_ui = get_node_or_null("/root/QuestUI")
	if quest_ui:
		quest_ui.toggle()
	else:
		print("任务UI未加载")

func _on_open_hideout_upgrade():
	print("打开藏身处升级")
	# TODO: 显示藏身处升级UI

func _on_heal():
	print("治疗玩家")
	var heal_cost = int((PlayerData.max_health - PlayerData.current_health) * 10)
	
	if PlayerData.remove_money("rubles", heal_cost):
		PlayerData.heal(PlayerData.max_health)
		update_player_info()
		print("治疗完成，花费 ₽", heal_cost)
	else:
		print("资金不足，需要 ₽", heal_cost)
