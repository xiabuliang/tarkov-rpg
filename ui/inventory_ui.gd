extends Control
# 背包/仓库界面

class_name InventoryUI

@onready var inventory_grid: GridContainer = $Panel/VBoxContainer/HBoxContainer/InventorySection/InventoryGrid
@onready var equipment_slots: VBoxContainer = $Panel/VBoxContainer/HBoxContainer/EquipmentSection/EquipmentSlots
@onready var stash_grid: GridContainer = $Panel/VBoxContainer/HBoxContainer/StashSection/StashGrid
@onready var item_info_panel: Panel = $ItemInfoPanel
@onready var item_name_label: Label = $ItemInfoPanel/VBoxContainer/ItemName
@onready var item_stats_label: Label = $ItemInfoPanel/VBoxContainer/ItemStats
@onready var weight_label: Label = $Panel/VBoxContainer/WeightLabel
@onready var money_label: Label = $Panel/VBoxContainer/MoneyLabel
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

var is_visible: bool = false
var selected_item: Dictionary = {}
var dragged_item: Dictionary = {}
var drag_source: String = ""  # "inventory", "equipment", "stash"

func _ready():
	close_button.pressed.connect(close_inventory)
	visible = false
	print("背包UI已加载")

func toggle():
	if visible:
		close_inventory()
	else:
		open_inventory()

func open_inventory():
	visible = true
	is_visible = true
	GameManager.change_state(GameManager.GameState.INVENTORY)
	refresh_ui()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_inventory():
	visible = false
	is_visible = false
	GameManager.change_state(GameManager.GameState.RAID_IN_PROGRESS)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func refresh_ui():
	update_inventory_grid()
	update_equipment_slots()
	update_stash_grid()
	update_weight_and_money()

func update_inventory_grid():
	# 清除旧格子
	for child in inventory_grid.get_children():
		child.queue_free()
	
	# 创建背包格子
	for y in range(InventoryManager.INVENTORY_HEIGHT):
		for x in range(InventoryManager.INVENTORY_WIDTH):
			var slot = create_slot(x, y, "inventory")
			var item = InventoryManager.current_container[y][x]
			
			if item != null:
				# 只在物品左上角显示
				var pos = item.get("position", Vector2i(x, y))
				if pos.x == x and pos.y == y:
					slot.set_item(item)
			
			inventory_grid.add_child(slot)

func update_equipment_slots():
	# 清除旧槽位
	for child in equipment_slots.get_children():
		child.queue_free()
	
	# 创建装备槽位
	var slots = [
		{"name": "head", "label": "头盔"},
		{"name": "face_cover", "label": "面罩"},
		{"name": "ears", "label": "耳机"},
		{"name": "body_armor", "label": "护甲"},
		{"name": "backpack", "label": "背包"},
		{"name": "tactical_rig", "label": "胸挂"},
		{"name": "primary_weapon", "label": "主武器"},
		{"name": "secondary_weapon", "label": "副武器"}
	]
	
	for slot_data in slots:
		var slot = create_equipment_slot(slot_data.name, slot_data.label)
		var item = InventoryManager.equipment.get(slot_data.name)
		if item != null:
			slot.set_item(item)
		equipment_slots.add_child(slot)

func update_stash_grid():
	# 清除旧格子
	for child in stash_grid.get_children():
		child.queue_free()
	
	# 创建仓库格子
	for y in range(InventoryManager.STASH_HEIGHT):
		for x in range(InventoryManager.STASH_WIDTH):
			var slot = create_slot(x, y, "stash")
			var item = InventoryManager.stash_container[y][x]
			
			if item != null:
				var pos = item.get("position", Vector2i(x, y))
				if pos.x == x and pos.y == y:
					slot.set_item(item)
			
			stash_grid.add_child(slot)

func create_slot(x: int, y: int, container_type: String) -> Panel:
	var slot = Panel.new()
	slot.custom_minimum_size = Vector2(50, 50)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# 样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.4, 0.4, 1.0)
	slot.add_theme_stylebox_override("panel", style)
	
	# 存储坐标信息
	slot.set_meta("grid_pos", Vector2i(x, y))
	slot.set_meta("container", container_type)
	
	# 连接信号
	slot.gui_input.connect(_on_slot_gui_input.bind(slot))
	slot.mouse_entered.connect(_on_slot_hover.bind(slot))
	
	return slot

func create_equipment_slot(slot_name: String, label_text: String) -> VBoxContainer:
	var container = VBoxContainer.new()
	
	var label = Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(label)
	
	var slot = Panel.new()
	slot.custom_minimum_size = Vector2(80, 80)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.6, 0.6, 0.6, 1.0)
	slot.add_theme_stylebox_override("panel", style)
	
	slot.set_meta("slot_name", slot_name)
	slot.set_meta("container", "equipment")
	slot.gui_input.connect(_on_slot_gui_input.bind(slot))
	slot.mouse_entered.connect(_on_slot_hover.bind(slot))
	
	container.add_child(slot)
	
	return container

func set_item_in_slot(slot: Panel, item: Dictionary):
	# 清除旧内容
	for child in slot.get_children():
		child.queue_free()
	
	if item.is_empty():
		return
	
	# 创建物品图标
	var texture_rect = TextureRect.new()
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_SIZE_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# TODO: 加载物品图标
	# texture_rect.texture = load(item.get("icon_path", "res://assets/icons/default.png"))
	
	# 显示物品名称作为临时替代
	var name_label = Label.new()
	name_label.text = item.get("name", "?")[0]  # 只显示第一个字符
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	
	slot.add_child(name_label)
	
	# 如果是多格物品，设置大小
	var size = item.get("size", Vector2i(1, 1))
	if size.x > 1 or size.y > 1:
		slot.custom_minimum_size = Vector2(50 * size.x, 50 * size.y)
		slot.size = Vector2(50 * size.x, 50 * size.y)

func _on_slot_gui_input(event: InputEvent, slot: Panel):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_slot_click(slot)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			handle_slot_right_click(slot)

func handle_slot_click(slot: Panel):
	var container = slot.get_meta("container")
	
	if dragged_item.is_empty():
		# 拿起物品
		pick_up_item(slot, container)
	else:
		// 放下物品
		place_item(slot, container)

func pick_up_item(slot: Panel, container: String):
	var item = get_item_at_slot(slot, container)
	if item != null:
		dragged_item = item
		drag_source = container
		remove_item_from_container(item, container)
		refresh_ui()

func place_item(slot: Panel, container: String):
	var grid_pos = slot.get_meta("grid_pos", Vector2i(-1, -1))
	
	if can_place_item(grid_pos, dragged_item, container):
		add_item_to_container(grid_pos, dragged_item, container)
		dragged_item = {}
		drag_source = ""
		refresh_ui()
	else:
		# 无法放置，返回原处
		return_item_to_source()

func return_item_to_source():
	if dragged_item.is_empty():
		return
	
	# 尝试放回原来的位置
	match drag_source:
		"inventory":
			InventoryManager.add_item_to_inventory(dragged_item)
		"stash":
			# TODO: 实现仓库添加
			pass
		"equipment":
			# TODO: 重新装备
			pass
	
	dragged_item = {}
	drag_source = ""
	refresh_ui()

func get_item_at_slot(slot: Panel, container: String) -> Dictionary:
	var grid_pos = slot.get_meta("grid_pos", Vector2i(-1, -1))
	
	match container:
		"inventory":
			if grid_pos.x >= 0 and grid_pos.y >= 0:
				return InventoryManager.current_container[grid_pos.y][grid_pos.x]
		"stash":
			if grid_pos.x >= 0 and grid_pos.y >= 0:
				return InventoryManager.stash_container[grid_pos.y][grid_pos.x]
		"equipment":
			var slot_name = slot.get_meta("slot_name", "")
			return InventoryManager.equipment.get(slot_name, {})
	
	return {}

func remove_item_from_container(item: Dictionary, container: String):
	match container:
		"inventory":
			var pos = item.get("position", Vector2i(0, 0))
			InventoryManager.remove_item_from_inventory(pos.x, pos.y)
		"equipment":
			var slot_name = ""
			for key in InventoryManager.equipment:
				if InventoryManager.equipment[key] == item:
					slot_name = key
					break
			if slot_name != "":
				InventoryManager.unequip_item(slot_name)

func can_place_item(grid_pos: Vector2i, item: Dictionary, container: String) -> bool:
	var size = item.get("size", Vector2i(1, 1))
	
	match container:
		"inventory":
			return InventoryManager.can_place_item(grid_pos.x, grid_pos.y, size, InventoryManager.current_container)
		"stash":
			return InventoryManager.can_place_item(grid_pos.x, grid_pos.y, size, InventoryManager.stash_container)
		"equipment":
			var slot_name = ""
			# TODO: 获取槽位名称并检查兼容性
			return true
	
	return false

func add_item_to_container(grid_pos: Vector2i, item: Dictionary, container: String):
	item["position"] = grid_pos
	
	match container:
		"inventory":
			InventoryManager.place_item(grid_pos.x, grid_pos.y, item, InventoryManager.current_container)
		"stash":
			InventoryManager.place_item(grid_pos.x, grid_pos.y, item, InventoryManager.stash_container)
		"equipment":
			var slot_name = ""  # TODO: 从slot获取
			InventoryManager.equip_item(slot_name, item)

func handle_slot_right_click(slot: Panel):
	var item = get_item_at_slot(slot, slot.get_meta("container"))
	if not item.is_empty():
		show_context_menu(slot, item)

func show_context_menu(slot: Panel, item: Dictionary):
	# TODO: 显示右键菜单（丢弃、使用、检查等）
	print("显示物品菜单:", item.get("name"))

func _on_slot_hover(slot: Panel):
	var item = get_item_at_slot(slot, slot.get_meta("container"))
	if not item.is_empty():
		show_item_info(item)
	else:
		hide_item_info()

func show_item_info(item: Dictionary):
	item_info_panel.visible = true
	item_name_label.text = item.get("name", "未知物品")
	
	var stats_text = ""
	stats_text += "类型: %s\n" % item.get("type", "未知")
	stats_text += "重量: %.2f kg\n" % item.get("weight", 0)
	stats_text += "价值: ₽%d\n" % item.get("value", 0)
	
	if item.has("damage"):
		stats_text += "伤害: %.0f\n" % item.get("damage")
	if item.has("armor_class"):
		stats_text += "护甲等级: %d\n" % item.get("armor_class")
	if item.has("durability"):
		stats_text += "耐久度: %.0f\n" % item.get("durability")
	
	item_stats_label.text = stats_text

func hide_item_info():
	item_info_panel.visible = false

func update_weight_and_money():
	var current = InventoryManager.get_inventory_weight()
	var max_w = InventoryManager.get_max_carry_weight()
	weight_label.text = "重量: %.1f / %.1f kg" % [current, max_w]
	
	money_label.text = "₽%d | $%d | €%d" % [PlayerData.rubles, PlayerData.dollars, PlayerData.euros]
