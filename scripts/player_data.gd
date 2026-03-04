extends Node
# 玩家数据管理器 - 全局单例
# 负责管理玩家的持久化数据、装备、仓库等

signal health_changed(new_health, max_health)
signal stamina_changed(new_stamina, max_stamina)
signal experience_changed(new_exp, level)
signal player_died()
signal extraction_success(loot_value)

# 基础属性
var max_health: float = 100.0
var current_health: float = 100.0
var max_stamina: float = 100.0
var current_stamina: float = 100.0

# 等级系统
var level: int = 1
var experience: int = 0
var exp_to_next_level: int = 1000

# 金钱
var rubles: int = 50000  # 卢布
var dollars: int = 0
var euros: int = 0

# 技能等级
var skills = {
	"strength": 1,
	"endurance": 1,
	"vitality": 1,
	"health": 1,
	"stress_resistance": 1,
	"metabolism": 1,
	"immunity": 1,
	"perception": 1,
	"intellect": 1,
	"attention": 1,
	"memory": 1,
	"charisma": 1,
	"mag_drills": 1,
	"surgery": 1,
	"covert_movement": 1,
	"search": 1,
	"sniping": 1,
	"recoil_control": 1,
	"troubleshooting": 1,
	"throwables": 1,
	"prone_movement": 1,
	"first_aid": 1,
	"field_medicine": 1,
	"light_vests": 1,
	"heavy_vests": 1,
	"weapon_modding": 1
}

# 藏身处（基地）数据
var hideout = {
	"air_filtering_unit": {"level": 0, "active": false},
	"bitcoin_farm": {"level": 0, "bitcoins": 0},
	"booze_generator": {"level": 0},
	"generator": {"level": 1, "fuel": 0},
	"heating": {"level": 1},
	"illumination": {"level": 1},
	"intelligence_center": {"level": 0},
	"lavatory": {"level": 1},
	"library": {"level": 0},
	"medstation": {"level": 0},
	"nutrition_unit": {"level": 0},
	"rest_space": {"level": 1},
	"scav_case": {"level": 0},
	"security": {"level": 0},
	"shooting_range": {"level": 0},
	"solar_power": {"level": 0},
	"stash": {"level": 1},
	"ventilation": {"level": 0},
	"water_collector": {"level": 0},
	"workbench": {"level": 1}
}

# 商人好感度
var traders = {
	"prapor": {"level": 1, "rep": 0.0},
	"therapist": {"level": 1, "rep": 0.0},
	"fence": {"level": 1, "rep": 0.0},
	"skier": {"level": 1, "rep": 0.0},
	"peacekeeper": {"level": 1, "rep": 0.0},
	"mechanic": {"level": 1, "rep": 0.0},
	"ragman": {"level": 1, "rep": 0.0},
	"jaeger": {"level": 1, "rep": 0.0}
}

func _ready():
	print("玩家数据管理器已加载")
	load_player_data()

func take_damage(amount: float):
	current_health -= amount
	if current_health <= 0:
		current_health = 0
		die()
	health_changed.emit(current_health, max_health)

func heal(amount: float):
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	health_changed.emit(current_health, max_health)

func use_stamina(amount: float):
	current_stamina -= amount
	if current_stamina < 0:
		current_stamina = 0
	stamina_changed.emit(current_stamina, max_stamina)

func recover_stamina(amount: float):
	current_stamina += amount
	if current_stamina > max_stamina:
		current_stamina = max_stamina
	stamina_changed.emit(current_stamina, max_stamina)

func gain_experience(amount: int):
	experience += amount
	if experience >= exp_to_next_level:
		level_up()
	experience_changed.emit(experience, level)

func level_up():
	level += 1
	experience -= exp_to_next_level
	exp_to_next_level = int(exp_to_next_level * 1.5)
	max_health += 5
	max_stamina += 5
	current_health = max_health
	current_stamina = max_stamina
	print("升级！当前等级：", level)

func die():
	player_died.emit()
	print("玩家死亡")

func add_money(currency: String, amount: int):
	match currency.to_lower():
		"rubles", "ruble", "rub":
			rubles += amount
		"dollars", "dollar", "usd":
			dollars += amount
		"euros", "euro", "eur":
			euros += amount

func remove_money(currency: String, amount: int) -> bool:
	match currency.to_lower():
		"rubles", "ruble", "rub":
			if rubles >= amount:
				rubles -= amount
				return true
		"dollars", "dollar", "usd":
			if dollars >= amount:
				dollars -= amount
				return true
		"euros", "euro", "eur":
			if euros >= amount:
				euros -= amount
				return true
	return false

func save_player_data():
	var save_data = {
		"health": current_health,
		"stamina": current_stamina,
		"level": level,
		"experience": experience,
		"rubles": rubles,
		"dollars": dollars,
		"euros": euros,
		"skills": skills,
		"hideout": hideout,
		"traders": traders
	}
	
	var file = FileAccess.open("user://player_save.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("玩家数据已保存")

func load_player_data():
	if not FileAccess.file_exists("user://player_save.json"):
		print("没有找到存档，使用默认数据")
		return
	
	var file = FileAccess.open("user://player_save.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.data
			current_health = data.get("health", 100.0)
			current_stamina = data.get("stamina", 100.0)
			level = data.get("level", 1)
			experience = data.get("experience", 0)
			rubles = data.get("rubles", 50000)
			dollars = data.get("dollars", 0)
			euros = data.get("euros", 0)
			skills = data.get("skills", skills)
			hideout = data.get("hideout", hideout)
			traders = data.get("traders", traders)
			print("玩家数据已加载")
