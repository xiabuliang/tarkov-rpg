extends Node
# 战利品系统 - 全局单例
# 负责生成地图上的战利品、容器、敌人装备等

signal loot_generated(position, items)
signal container_searched(container_type, items)

# 物品稀有度枚举
enum Rarity {
	COMMON = 0,      # 普通 - 60%
	UNCOMMON = 1,    #  uncommon - 25%
	RARE = 2,        # 稀有 - 10%
	EPIC = 3,        # 史诗 - 4%
	LEGENDARY = 4,   # 传说 - 1%
	SPECIAL = 5      # 特殊任务物品
}

# 物品数据库（简化版）
var item_database = {
	# 武器
	"ak74n": {
		"id": "ak74n",
		"name": "AK-74N",
		"type": "rifle",
		"rarity": Rarity.COMMON,
		"size": Vector2i(5, 2),
		"weight": 3.5,
		"value": 25000,
		"damage": 45,
		"ammo_type": "5.45x39",
		"mag_size": 30,
		"fire_rate": 600,
		"ergonomics": 55,
		"recoil_vertical": 85,
		"recoil_horizontal": 220
	},
	"m4a1": {
		"id": "m4a1",
		"name": "M4A1",
		"type": "rifle",
		"rarity": Rarity.UNCOMMON,
		"size": Vector2i(5, 2),
		"weight": 3.2,
		"value": 45000,
		"damage": 52,
		"ammo_type": "5.56x45",
		"mag_size": 30,
		"fire_rate": 800,
		"ergonomics": 70,
		"recoil_vertical": 75,
		"recoil_horizontal": 180
	},
	"mp5": {
		"id": "mp5",
		"name": "MP5",
		"type": "smg",
		"rarity": Rarity.COMMON,
		"size": Vector2i(4, 2),
		"weight": 2.5,
		"value": 18000,
		"damage": 35,
		"ammo_type": "9x19",
		"mag_size": 30,
		"fire_rate": 800,
		"ergonomics": 80,
		"recoil_vertical": 50,
		"recoil_horizontal": 120
	},
	"pm_pistol": {
		"id": "pm_pistol",
		"name": "PM (马卡洛夫)",
		"type": "pistol",
		"rarity": Rarity.COMMON,
		"size": Vector2i(2, 1),
		"weight": 0.73,
		"value": 3500,
		"damage": 28,
		"ammo_type": "9x18",
		"mag_size": 8,
		"fire_rate": 300,
		"ergonomics": 90,
		"recoil_vertical": 35,
		"recoil_horizontal": 60
	},
	
	# 护甲
	"6b2_armor": {
		"id": "6b2_armor",
		"name": "6B2 防弹衣",
		"type": "armor",
		"rarity": Rarity.COMMON,
		"size": Vector2i(3, 3),
		"weight": 4.2,
		"value": 12000,
		"armor_class": 2,
		"durability": 60,
		"protection_zones": ["chest", "stomach"]
	},
	"gen4_hmk": {
		"id": "gen4_hmk",
		"name": "Gen4 HMK",
		"type": "armor",
		"rarity": Rarity.RARE,
		"size": Vector2i(3, 3),
		"weight": 7.5,
		"value": 85000,
		"armor_class": 5,
		"durability": 85,
		"protection_zones": ["chest", "stomach", "arms"]
	},
	
	# 头盔
	"ssh68_helmet": {
		"id": "ssh68_helmet",
		"name": "SSH-68 钢盔",
		"type": "helmet",
		"rarity": Rarity.COMMON,
		"size": Vector2i(2, 2),
		"weight": 1.3,
		"value": 8000,
		"armor_class": 2,
		"durability": 40
	},
	"ulach_helmet": {
		"id": "ulach_helmet",
		"name": "ULACH IIIA",
		"type": "helmet",
		"rarity": Rarity.RARE,
		"size": Vector2i(2, 2),
		"weight": 1.1,
		"value": 55000,
		"armor_class": 3,
		"durability": 65
	},
	
	# 背包
	"mbss_backpack": {
		"id": "mbss_backpack",
		"name": "MBSS 背包",
		"type": "backpack",
		"rarity": Rarity.COMMON,
		"size": Vector2i(4, 4),
		"weight": 0.8,
		"value": 6500,
		"capacity": 16
	},
	"attack2_backpack": {
		"id": "attack2_backpack",
		"name": "Attack-2 战术背包",
		"type": "backpack",
		"rarity": Rarity.UNCOMMON,
		"size": Vector2i(5, 5),
		"weight": 1.8,
		"value": 28000,
		"capacity": 35
	},
	
	# 医疗物品
	"bandage": {
		"id": "bandage",
		"name": "绷带",
		"type": "medical",
		"rarity": Rarity.COMMON,
		"size": Vector2i(1, 1),
		"weight": 0.05,
		"value": 500,
		"heal_amount": 15,
		"use_time": 3.0
	},
	"ai2_medkit": {
		"id": "ai2_medkit",
		"name": "AI-2 急救包",
		"type": "medical",
		"rarity": Rarity.COMMON,
		"size": Vector2i(1, 1),
		"weight": 0.2,
		"value": 2500,
		"heal_amount": 50,
		"use_time": 5.0
	},
	"salewa_first_aid": {
		"id": "salewa_first_aid",
		"name": "Salewa 急救包",
		"type": "medical",
		"rarity": Rarity.UNCOMMON,
		"size": Vector2i(1, 2),
		"weight": 0.4,
		"value": 12000,
		"heal_amount": 85,
		"use_time": 4.0
	},
	"ifak_tactical": {
		"id": "ifak_tactical",
		"name": "IFAK 战术急救包",
		"type": "medical",
		"rarity": Rarity.RARE,
		"size": Vector2i(1, 1),
		"weight": 0.3,
		"value": 18000,
		"heal_amount": 100,
		"use_time": 3.0
	},
	
	# 弹药
	"ammo_545x39_ps": {
		"id": "ammo_545x39_ps",
		"name": "5.45x39 PS 弹药",
		"type": "ammo",
		"rarity": Rarity.COMMON,
		"size": Vector2i(1, 1),
		"weight": 0.01,
		"value": 150,
		"count": 30,
		"penetration": 25,
		"damage": 50
	},
	"ammo_556x45_m855": {
		"id": "ammo_556x45_m855",
		"name": "5.56x45 M855 弹药",
		"type": "ammo",
		"rarity": Rarity.UNCOMMON,
		"size": Vector2i(1, 1),
		"weight": 0.01,
		"value": 280,
		"count": 30,
		"penetration": 30,
		"damage": 54
	},
	"ammo_9x19_pst": {
		"id": "ammo_9x19_pst",
		"name": "9x19 PST 弹药",
		"type": "ammo",
		"rarity": Rarity.COMMON,
		"size": Vector2i(1, 1),
		"weight": 0.01,
		"value": 120,
		"count": 30,
		"penetration": 20,
		"damage": 54
	},
	
	# 食物和水
	"army_crackers": {
		"id": "army_crackers",
		"name": "军用饼干",
		"type": "food",
		"rarity": Rarity.COMMON,
		"size": Vector2i(1, 1),
		"weight": 0.1,
		"value": 800,
		"energy": 15
	},
	"water_bottle": {
		"id": "water_bottle",
		"name": "瓶装水",
		"type": "drink",
		"rarity": Rarity.COMMON,
		"size": Vector2i(1, 2),
		"weight": 0.5,
		"value": 600,
		"hydration": 25
	},
	
	# 贵重物品
	"gold_chain": {
		"id": "gold_chain",
		"name": "金链",
		"type": "valuable",
		"rarity": Rarity.RARE,
		"size": Vector2i(1, 1),
		"weight": 0.1,
		"value": 45000
	},
	"bitcoin": {
		"id": "bitcoin",
		"name": "比特币",
		"type": "valuable",
		"rarity": Rarity.LEGENDARY,
		"size": Vector2i(1, 1),
		"weight": 0.02,
		"value": 350000
	},
	"graphics_card": {
		"id": "graphics_card",
		"name": "显卡",
		"type": "valuable",
		"rarity": Rarity.EPIC,
		"size": Vector2i(2, 1),
		"weight": 0.8,
		"value": 180000
	}
}

# 容器类型及其战利品配置
var container_types = {
	"weapon_box": {
		"name": "武器箱",
		"slots": 10,
		"possible_items": ["ak74n", "m4a1", "mp5", "pm_pistol", "ammo_545x39_ps", "ammo_556x45_m855", "ammo_9x19_pst"],
		"min_items": 1,
		"max_items": 4
	},
	"medical_bag": {
		"name": "医疗包",
		"slots": 6,
		"possible_items": ["bandage", "ai2_medkit", "salewa_first_aid", "ifak_tactical"],
		"min_items": 1,
		"max_items": 3
	},
	"supply_crate": {
		"name": "补给箱",
		"slots": 12,
		"possible_items": ["bandage", "ai2_medkit", "army_crackers", "water_bottle", "ammo_545x39_ps", "ammo_9x19_pst", "mbss_backpack"],
		"min_items": 2,
		"max_items": 6
	},
	"pc_block": {
		"name": "电脑主机",
		"slots": 2,
		"possible_items": ["graphics_card", "bitcoin"],
		"min_items": 0,
		"max_items": 1
	},
	"safe": {
		"name": "保险箱",
		"slots": 4,
		"possible_items": ["gold_chain", "bitcoin", "graphics_card"],
		"min_items": 1,
		"max_items": 2
	},
	"jacket": {
		"name": "夹克",
		"slots": 2,
		"possible_items": ["bandage", "ai2_medkit", "pm_pistol", "gold_chain", "army_crackers"],
		"min_items": 0,
		"max_items": 1
	},
	"duffle_bag": {
		"name": "行李袋",
		"slots": 8,
		"possible_items": ["6b2_armor", "ssh68_helmet", "mbss_backpack", "attack2_backpack", "army_crackers", "water_bottle"],
		"min_items": 1,
		"max_items": 4
	}
}

func _ready():
	print("战利品系统已加载")

# 根据稀有度获取随机物品
func get_random_item_by_rarity(rarity: int) -> Dictionary:
	var items_of_rarity = []
	for item_id in item_database:
		if item_database[item_id].rarity == rarity:
			items_of_rarity.append(item_database[item_id])
	
	if items_of_rarity.is_empty():
		return {}
	
	return items_of_rarity[randi() % items_of_rarity.size()].duplicate()

# 根据权重获取随机稀有度
func get_random_rarity() -> int:
	var roll = randf()
	if roll < 0.01:
		return Rarity.LEGENDARY
	elif roll < 0.05:
		return Rarity.EPIC
	elif roll < 0.15:
		return Rarity.RARE
	elif roll < 0.40:
		return Rarity.UNCOMMON
	else:
		return Rarity.COMMON

# 生成容器内的战利品
func generate_container_loot(container_type: String) -> Array:
	if not container_types.has(container_type):
		return []
	
	var config = container_types[container_type]
	var num_items = randi_range(config.min_items, config.max_items)
	var generated_items = []
	
	for i in range(num_items):
		var item_id = config.possible_items[randi() % config.possible_items.size()]
		if item_database.has(item_id):
			var item = item_database[item_id].duplicate()
			item["uid"] = str(Time.get_unix_time_from_system()) + "_" + str(randi())
			generated_items.append(item)
	
	container_searched.emit(container_type, generated_items)
	return generated_items

# 生成地面随机战利品
func generate_ground_loot(position: Vector2, radius: float = 10.0) -> Array:
	var items = []
	var num_items = randi_range(0, 3)
	
	for i in range(num_items):
		var rarity = get_random_rarity()
		var item = get_random_item_by_rarity(rarity)
		if not item.is_empty():
			# 在范围内随机位置
			var offset = Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
			item["world_position"] = position + offset
			item["uid"] = str(Time.get_unix_time_from_system()) + "_" + str(randi())
			items.append(item)
	
	loot_generated.emit(position, items)
	return items

# 生成敌人的装备
func generate_enemy_loadout(difficulty: int = 1) -> Dictionary:
	var loadout = {
		"weapon": null,
		"armor": null,
		"helmet": null,
		"backpack": null,
		"inventory": []
	}
	
	# 根据难度选择装备
	match difficulty:
		1:  # 简单 -  scav
			loadout.weapon = item_database["pm_pistol"].duplicate()
			loadout.armor = null
			loadout.helmet = null
			loadout.inventory = [item_database["bandage"].duplicate()]
		2:  # 中等
			var weapons = ["ak74n", "mp5"]
			loadout.weapon = item_database[weapons[randi() % weapons.size()]].duplicate()
			loadout.armor = item_database["6b2_armor"].duplicate()
			loadout.helmet = item_database["ssh68_helmet"].duplicate()
			loadout.inventory = [
				item_database["ai2_medkit"].duplicate(),
				item_database["ammo_545x39_ps"].duplicate()
			]
		3:  # 困难 - PMC
			var pmc_weapons = ["ak74n", "m4a1"]
			loadout.weapon = item_database[pmc_weapons[randi() % pmc_weapons.size()]].duplicate()
			loadout.armor = item_database["gen4_hmk"].duplicate() if randf() < 0.3 else item_database["6b2_armor"].duplicate()
			loadout.helmet = item_database["ulach_helmet"].duplicate() if randf() < 0.3 else item_database["ssh68_helmet"].duplicate()
			loadout.backpack = item_database["attack2_backpack"].duplicate() if randf() < 0.5 else item_database["mbss_backpack"].duplicate()
			loadout.inventory = [
				item_database["salewa_first_aid"].duplicate(),
				item_database["ammo_556x45_m855"].duplicate(),
				item_database["army_crackers"].duplicate()
			]
	
	return loadout

# 辅助函数
func randi_range(min_val: int, max_val: int) -> int:
	return min_val + randi() % (max_val - min_val + 1)

func randf_range(min_val: float, max_val: float) -> float:
	return min_val + randf() * (max_val - min_val)
