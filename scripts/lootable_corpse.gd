extends StaticBody2D
# 可搜刮的尸体（敌人或玩家）

class_name LootableCorpse

signal looting_started()
signal looting_finished()

var enemy_loadout: Dictionary = {}
var inventory_items: Array = []
var is_being_looted: bool = false
var looting_player: Node2D = null

@onready var interaction_area: Area2D = $InteractionArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

func _ready():
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	label.visible = false
	label.text = "按 F 搜刮"

func _on_body_entered(body: Node2D):
	if body.is_in_group("player") and not is_being_looted:
		label.visible = true
		body.nearby_interactables.append(self)

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		label.visible = false
		body.nearby_interactables.erase(self)
		if looting_player == body:
			stop_looting()

func interact(player: Node2D):
	if is_being_looted:
		return
	
	start_looting(player)

func start_looting(player: Node2D):
	is_being_looted = true
	looting_player = player
	looting_started.emit()
	
	label.text = "搜刮中..."
	
	# 打开搜刮UI
	# TODO: 显示尸体装备和物品的UI界面
	show_loot_ui()

func stop_looting():
	is_being_looted = false
	looting_player = null
	label.text = "按 F 搜刮"
	looting_finished.emit()
	
	# 关闭搜刮UI
	hide_loot_ui()

func show_loot_ui():
	print("显示尸体搜刮界面")
	print("装备:", enemy_loadout)
	print("物品:", inventory_items)
	
	# TODO: 实例化并显示搜刮UI
	# 这里应该创建一个UI来显示：
	# - 头盔、护甲、武器等装备
	# - 背包内的物品
	# 玩家可以点击物品将其转移到自己的背包

func hide_loot_ui():
	print("关闭尸体搜刮界面")
	# TODO: 隐藏搜刮UI

func take_item(item_index: int) -> Dictionary:
	if item_index < 0 or item_index >= inventory_items.size():
		return {}
	
	var item = inventory_items[item_index]
	inventory_items.remove_at(item_index)
	
	# 添加到玩家背包
	if InventoryManager.add_item_to_inventory(item):
		GameManager.add_found_loot(item)
		return item
	else:
		# 背包满了，归还物品
		inventory_items.insert(item_index, item)
		return {}

func take_equipment(slot: String) -> Dictionary:
	if not enemy_loadout.has(slot) or enemy_loadout[slot] == null:
		return {}
	
	var item = enemy_loadout[slot]
	enemy_loadout[slot] = null
	
	if InventoryManager.add_item_to_inventory(item):
		GameManager.add_found_loot(item)
		return item
	else:
		enemy_loadout[slot] = item
		return {}
