extends Control
# 任务界面 - 显示和管理任务

class_name QuestUI

@onready var quest_list: ItemList = $Panel/VBoxContainer/HBoxContainer/QuestListSection/QuestList
@onready var quest_details: VBoxContainer = $Panel/VBoxContainer/HBoxContainer/DetailsSection
@onready var accept_button: Button = $Panel/VBoxContainer/HBoxContainer/DetailsSection/AcceptButton
@onready var abandon_button: Button = $Panel/VBoxContainer/HBoxContainer/DetailsSection/AbandonButton
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton
@onready var trader_selector: OptionButton = $Panel/VBoxContainer/TraderSelector

var selected_quest_id: String = ""
var current_filter: String = "all"  # all, active, available, completed

func _ready():
	close_button.pressed.connect(close_quest_ui)
	accept_button.pressed.connect(_on_accept_pressed)
	abandon_button.pressed.connect(_on_abandon_pressed)
	quest_list.item_selected.connect(_on_quest_selected)
	trader_selector.item_selected.connect(_on_trader_changed)
	
	populate_trader_selector()
	visible = false
	print("任务UI已加载")

func toggle():
	if visible:
		close_quest_ui()
	else:
		open_quest_ui()

func open_quest_ui():
	visible = true
	GameManager.change_state(GameManager.GameState.TRADING)
	refresh_quest_list()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_quest_ui():
	visible = false
	GameManager.change_state(GameManager.GameState.HIDEOUT)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func populate_trader_selector():
	trader_selector.clear()
	trader_selector.add_item("所有商人", 0)
	trader_selector.set_item_metadata(0, "all")
	
	# 从任务数据库中提取所有商人
	var traders_found = {}
	for quest_id in QuestSystem.quest_database:
		var quest_data = QuestSystem.quest_database[quest_id]
		var giver_id = quest_data.get("giver", "")
		if not giver_id.is_empty() and not traders_found.has(giver_id):
			traders_found[giver_id] = get_trader_display_name(giver_id)
	
	var index = 1
	for trader_id in traders_found:
		trader_selector.add_item(traders_found[trader_id], index)
		trader_selector.set_item_metadata(index, trader_id)
		index += 1

func get_trader_display_name(trader_id: String) -> String:
	var trader_names = {
		"prapor": "Prapor",
		"therapist": "Therapist",
		"skier": "Skier",
		"peacekeeper": "Peacekeeper",
		"mechanic": "Mechanic",
		"ragman": "Ragman",
		"jaeger": "Jaeger"
	}
	return trader_names.get(trader_id, trader_id)

func _on_trader_changed(index: int):
	current_filter = trader_selector.get_item_metadata(index)
	refresh_quest_list()

func refresh_quest_list():
	quest_list.clear()
	
	for quest_id in QuestSystem.player_quests:
		var quest_data = QuestSystem.quest_database[quest_id]
		var quest_state = QuestSystem.player_quests[quest_id]
		
		# 根据商人筛选
		if current_filter != "all" and quest_data.giver != current_filter:
			continue
		
		# 只显示可用和进行中的任务
		if quest_state.status == QuestSystem.QuestStatus.AVAILABLE or \
		   quest_state.status == QuestSystem.QuestStatus.ACTIVE:
			var display_text = quest_data.title
			if quest_state.status == QuestSystem.QuestStatus.ACTIVE:
				display_text += " [进行中]"
				var progress_text = QuestSystem.get_quest_progress_text(quest_id)
				if not progress_text.is_empty():
					display_text += " - " + progress_text
			
			quest_list.add_item(display_text)
			quest_list.set_item_metadata(quest_list.item_count - 1, quest_id)

func _on_quest_selected(index: int):
	selected_quest_id = quest_list.get_item_metadata(index)
	show_quest_details(selected_quest_id)

func show_quest_details(quest_id: String):
	if not QuestSystem.quest_database.has(quest_id):
		return
	
	var quest_data = QuestSystem.quest_database[quest_id]
	var quest_state = QuestSystem.player_quests[quest_id]
	
	# 清除旧内容
	for child in quest_details.get_children():
		if child != accept_button and child != abandon_button:
			child.queue_free()
	
	# 任务标题
	var title_label = Label.new()
	title_label.text = quest_data.title
	title_label.add_theme_font_size_override("font_size", 24)
	quest_details.add_child(title_label)
	
	# 任务发布者
	var giver_label = Label.new()
	var giver_name = QuestSystem.trader_catalogs.get(quest_data.giver, {}).get("name", "未知")
	giver_label.text = "发布者: " + giver_name
	quest_details.add_child(giver_label)
	
	# 任务描述
	var desc_label = Label.new()
	desc_label.text = quest_data.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_details.add_child(desc_label)
	
	# 分隔线
	var separator = HSeparator.new()
	quest_details.add_child(separator)
	
	# 任务目标
	var objective_title = Label.new()
	objective_title.text = "目标:"
	objective_title.add_theme_font_size_override("font_size", 18)
	quest_details.add_child(objective_title)
	
	var objective_label = Label.new()
	objective_label.text = get_objective_text(quest_data)
	quest_details.add_child(objective_label)
	
	# 当前进度
	if quest_state.status == QuestSystem.QuestStatus.ACTIVE:
		var progress_title = Label.new()
		progress_title.text = "进度:"
		progress_title.add_theme_font_size_override("font_size", 18)
		quest_details.add_child(progress_title)
		
		var progress_label = Label.new()
		progress_label.text = QuestSystem.get_quest_progress_text(quest_id)
		quest_details.add_child(progress_label)
	
	# 奖励
	var reward_title = Label.new()
	reward_title.text = "奖励:"
	reward_title.add_theme_font_size_override("font_size", 18)
	quest_details.add_child(reward_title)
	
	var reward_label = Label.new()
	reward_label.text = get_reward_text(quest_data.rewards)
	quest_details.add_child(reward_label)
	
	# 移动按钮到底部
	quest_details.move_child(accept_button, -1)
	quest_details.move_child(abandon_button, -1)
	
	# 更新按钮状态
	if quest_state.status == QuestSystem.QuestStatus.AVAILABLE:
		accept_button.visible = true
		accept_button.disabled = false
		abandon_button.visible = false
	elif quest_state.status == QuestSystem.QuestStatus.ACTIVE:
		accept_button.visible = false
		abandon_button.visible = true
	else:
		accept_button.visible = false
		abandon_button.visible = false

func get_objective_text(quest_data: Dictionary) -> String:
	match quest_data.type:
		QuestSystem.QuestType.KILL:
			var target = quest_data.requirements.get("target_type", "敌人")
			var count = quest_data.requirements.get("count", 1)
			return "击杀 %d 名%s" % [count, target]
		
		QuestSystem.QuestType.COLLECT:
			var count = quest_data.requirements.get("count", 1)
			return "收集 %d 个物品" % count
		
		QuestSystem.QuestType.EXTRACT:
			var map = quest_data.requirements.get("map", "任意")
			if map == "any":
				return "从任意地图成功撤离"
			else:
				return "从 %s 成功撤离" % map
		
		QuestSystem.QuestType.DELIVER:
			var items = quest_data.requirements.get("items", [])
			var item_text = ""
			for item_req in items:
				var item_data = LootSystem.item_database.get(item_req.id, {})
				var item_name = item_data.get("name", item_req.id)
				item_text += "%d个%s " % [item_req.count, item_name]
			return "交付: " + item_text
		
		QuestSystem.QuestType.SURVIVE:
			var time = quest_data.requirements.get("time", 300)
			return "在战局中存活 %d 秒" % time
	
	return "未知目标"

func get_reward_text(rewards: Dictionary) -> String:
	var text = ""
	
	if rewards.has("exp"):
		text += "经验: %d\n" % rewards.exp
	
	if rewards.has("rubles"):
		text += "卢布: ₽%d\n" % rewards.rubles
	
	if rewards.has("dollars"):
		text += "美元: $%d\n" % rewards.dollars
	
	if rewards.has("euros"):
		text += "欧元: €%d\n" % rewards.euros
	
	if rewards.has("trader_rep"):
		text += "商人声望提升\n"
	
	if rewards.has("items"):
		text += "物品奖励:\n"
		for item_reward in rewards.items:
			var item_data = LootSystem.item_database.get(item_reward.id, {})
			var item_name = item_data.get("name", item_reward.id)
			text += "  - %s x%d\n" % [item_name, item_reward.get("count", 1)]
	
	return text if not text.is_empty() else "无"

func _on_accept_pressed():
	if selected_quest_id.is_empty():
		return
	
	if QuestSystem.accept_quest(selected_quest_id):
		refresh_quest_list()
		show_quest_details(selected_quest_id)

func _on_abandon_pressed():
	if selected_quest_id.is_empty():
		return
	
	# TODO: 实现放弃任务功能
	print("放弃任务功能待实现")
