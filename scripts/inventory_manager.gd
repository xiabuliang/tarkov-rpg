extends Node
# 背包管理器 - 全局单例
# 管理玩家的装备和物品栏

signal inventory_changed()
signal item_added(item, slot)
signal item_removed(item, slot)
signal equipment_changed(slot, item)

# 背包大小
const INVENTORY_WIDTH = 10
const INVENTORY_HEIGHT = 6
const STASH_WIDTH = 10
const STASH_HEIGHT = 20

# 当前使用的容器（战斗中用背包，藏身处用仓库）
var current_container: Array = []
var stash_container: Array = []

# 装备槽位
var equipment = {
	"head": null,           # 头盔/帽子
	"face_cover": null,     # 面罩/面具
	"ears": null,           # 耳机
	"body_armor": null,     # 护甲
	"backpack": null,       # 背包
	"tactical_rig": null,   # 胸挂/战术背心
	"primary_weapon": null, # 主武器
	"secondary_weapon": null, # 副武器/手枪
	"holster": null,        # 枪套
	"scabbard": null,       # 近战武器
	"pockets": [null, null, null, null],  # 4个口袋
}

# 快速访问栏
var quick_slots = [null, null, null, null, null, null, null]

func _ready():
	print("背包管理器已加载")
	initialize_containers()

func initialize_containers():
	# 初始化背包格子
	current_container.clear()
	for y in range(INVENTORY_HEIGHT):
		var row = []
		for x in range(INVENTORY_WIDTH):
			row.append(null)
		current_container.append(row)
	
	# 初始化仓库格子
	stash_container.clear()
	for y in range(STASH_HEIGHT):
		var row = []
		for x in range(STASH_WIDTH):
			row.append(null)
		stash_container.append(row)

# 添加物品到背包
func add_item_to_inventory(item_data: Dictionary) -> bool:
	var item_size = item_data.get("size", Vector2i(1, 1))
	
	# 寻找空位
	for y in range(INVENTORY_HEIGHT - item_size.y + 1):
		for x in range(INVENTORY_WIDTH - item_size.x + 1):
			if can_place_item(x, y, item_size, current_container):
				place_item(x, y, item_data, current_container)
				item_added.emit(item_data, Vector2i(x, y))
				inventory_changed.emit()
				return true
	
	print("背包已满，无法添加物品：", item_data.get("name", "未知"))
	return false

# 检查是否可以放置物品
func can_place_item(x: int, y: int, size: Vector2i, container: Array) -> bool:
	if y + size.y > container.size() or x + size.x > container[0].size():
		return false
	
	for dy in range(size.y):
		for dx in range(size.x):
			if container[y + dy][x + dx] != null:
				return false
	return true

# 放置物品
func place_item(x: int, y: int, item_data: Dictionary, container: Array):
	var size = item_data.get("size", Vector2i(1, 1))
	item_data["position"] = Vector2i(x, y)
	
	for dy in range(size.y):
		for dx in range(size.x):
			container[y + dy][x + dx] = item_data

# 从背包移除物品
func remove_item_from_inventory(x: int, y: int) -> Dictionary:
	var item = current_container[y][x]
	if item == null:
		return {}
	
	var pos = item.get("position", Vector2i(x, y))
	var size = item.get("size", Vector2i(1, 1))
	
	# 清除所有占用的格子
	for dy in range(size.y):
		for dx in range(size.x):
			current_container[pos.y + dy][pos.x + dx] = null
	
	item_removed.emit(item, pos)
	inventory_changed.emit()
	return item

# 装备物品
func equip_item(slot: String, item_data: Dictionary) -> bool:
	if not equipment.has(slot):
		print("无效的装备槽位：", slot)
		return false
	
	# 检查槽位类型是否匹配
	var item_type = item_data.get("type", "")
	if not is_slot_compatible(slot, item_type):
		print("物品类型不匹配槽位")
		return false
	
	# 如果有已装备的物品，先卸下
	if equipment[slot] != null:
		unequip_item(slot)
	
	equipment[slot] = item_data
	equipment_changed.emit(slot, item_data)
	inventory_changed.emit()
	print("已装备：", item_data.get("name", "未知"), "到", slot)
	return true

# 卸下装备
func unequip_item(slot: String) -> Dictionary:
	if not equipment.has(slot) or equipment[slot] == null:
		return {}
	
	var item = equipment[slot]
	equipment[slot] = null
	equipment_changed.emit(slot, null)
	inventory_changed.emit()
	
	# 尝试将卸下的物品放回背包
	if not add_item_to_inventory(item):
		print("背包已满，物品掉落到地面")
		# TODO: 生成地面物品
	
	return item

# 检查槽位兼容性
func is_slot_compatible(slot: String, item_type: String) -> bool:
	var compatibility = {
		"head": ["helmet", "hat", "headwear"],
		"face_cover": ["mask", "face_shield", "glasses"],
		"ears": ["headset", "ear_protection"],
		"body_armor": ["armor", "vest", "chest_rig"],
		"backpack": ["backpack"],
		"tactical_rig": ["tactical_rig", "chest_rig"],
		"primary_weapon": ["rifle", "shotgun", "smg", "sniper_rifle"],
		"secondary_weapon": ["pistol"],
		"holster": ["pistol"],
		"scabbard": ["melee", "knife"]
	}
	
	if compatibility.has(slot):
		return item_type in compatibility[slot]
	return false

# 获取背包重量
func get_inventory_weight() -> float:
	var total_weight = 0.0
	var checked_items = []
	
	for row in current_container:
		for item in row:
			if item != null and not item in checked_items:
				total_weight += item.get("weight", 0.0)
				checked_items.append(item)
	
	return total_weight

# 获取最大承重
func get_max_carry_weight() -> float:
	var base_weight = 40.0  # 基础负重
	
	# 根据力量技能增加负重
	var strength_level = PlayerData.skills.get("strength", 1)
	base_weight += strength_level * 2
	
	# 背包提供的额外空间
	if equipment["backpack"] != null:
		base_weight += equipment["backpack"].get("capacity", 0)
	
	return base_weight

# 检查是否超重
func is_overweight() -> bool:
	return get_inventory_weight() > get_max_carry_weight()

# 获取移动速度惩罚
func get_movement_penalty() -> float:
	var weight = get_inventory_weight()
	var max_weight = get_max_carry_weight()
	var ratio = weight / max_weight
	
	if ratio < 0.5:
		return 1.0  # 无惩罚
	elif ratio < 0.75:
		return 0.9  # 轻微减速
	elif ratio < 0.9:
		return 0.75  # 明显减速
	elif ratio < 1.0:
		return 0.5  # 严重减速
	else:
		return 0.25  # 超重，几乎无法移动

# 使用物品
func use_item(x: int, y: int) -> bool:
	var item = current_container[y][x]
	if item == null:
		return false
	
	var item_type = item.get("type", "")
	var item_name = item.get("name", "")
	
	match item_type:
		"medical":
			use_medical_item(item)
			remove_item_from_inventory(x, y)
			return true
		"food":
			use_food_item(item)
			remove_item_from_inventory(x, y)
			return true
		"drink":
			use_drink_item(item)
			remove_item_from_inventory(x, y)
			return true
		"ammo":
			# 弹药在装填时使用
			return false
		_:
			print("无法直接使用此物品：", item_name)
			return false

func use_medical_item(item: Dictionary):
	var heal_amount = item.get("heal_amount", 20)
	PlayerData.heal(heal_amount)
	print("使用了医疗物品，恢复", heal_amount, "生命值")

func use_food_item(item: Dictionary):
	var energy = item.get("energy", 10)
	# TODO: 增加能量系统
	print("食用了", item.get("name"), "恢复", energy, "能量")

func use_drink_item(item: Dictionary):
	var hydration = item.get("hydration", 15)
	# TODO: 增加水分系统
	print("饮用了", item.get("name"), "恢复", hydration, "水分")

# 丢弃物品
func discard_item(x: int, y: int):
	var item = remove_item_from_inventory(x, y)
	if not item.is_empty():
		print("丢弃了：", item.get("name"))
		# TODO: 在地面上生成物品实体
