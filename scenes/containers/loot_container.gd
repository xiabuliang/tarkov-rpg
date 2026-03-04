extends StaticBody2D
# 可搜刮的容器（武器箱、医疗包等）

class_name LootContainer

signal opened()
signal loot_taken(item)

@export var container_type: String = "supply_crate"
@export var is_looted: bool = false
@export var respawn_time: float = 300.0  # 5分钟后重新生成物品

var contained_items: Array = []
var is_open: bool = false

@onready var interaction_area: Area2D = $InteractionArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var respawn_timer: Timer = $RespawnTimer

func _ready():
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	respawn_timer.timeout.connect(_on_respawn)
	respawn_timer.wait_time = respawn_time
	
	label.visible = false
	generate_loot()

func generate_loot():
	contained_items = LootSystem.generate_container_loot(container_type)
	is_looted = false
	update_appearance()

func _on_body_entered(body: Node2D):
	if body.is_in_group("player") and not is_looted:
		label.visible = true
		body.nearby_interactables.append(self)

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		label.visible = false
		body.nearby_interactables.erase(self)
		if is_open:
			close_container()

func interact(player: Node2D):
	if is_looted:
		return
	
	if is_open:
		close_container()
	else:
		open_container(player)

func open_container(player: Node2D):
	is_open = true
	opened.emit()
	label.text = "[已打开]"
	
	# 显示容器内的物品UI
	show_loot_ui()

func close_container():
	is_open = false
	hide_loot_ui()
	
	if contained_items.is_empty():
		mark_as_looted()
	else:
		label.text = "按 F 搜刮"

func show_loot_ui():
	print("容器 [", container_type, "] 内容:")
	for i in range(contained_items.size()):
		var item = contained_items[i]
		print("[%d] %s (价值: %d)" % [i, item.get("name", "未知"), item.get("value", 0)])
	
	# TODO: 显示物品选择UI，让玩家选择拿取哪些物品
	# 简化处理：自动将所有物品添加到玩家背包
	for item in contained_items.duplicate():
		if InventoryManager.add_item_to_inventory(item):
			GameManager.add_found_loot(item)
			contained_items.erase(item)
			loot_taken.emit(item)
			print("拾取:", item.get("name"))
		else:
			print("背包已满，无法拾取:", item.get("name"))
	
	if contained_items.is_empty():
		mark_as_looted()

func hide_loot_ui():
	pass  # UI关闭逻辑

func mark_as_looted():
	is_looted = true
	is_open = false
	label.text = "[已搜刮]"
	update_appearance()
	
	# 启动重生计时器
	respawn_timer.start()

func update_appearance():
	# 改变外观表示已被搜刮
	if is_looted:
		sprite.modulate = Color(0.5, 0.5, 0.5, 1.0)  # 变灰
	else:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)  # 正常

func _on_respawn():
	print("容器 [", container_type, "] 重新生成战利品")
	generate_loot()
