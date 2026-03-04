extends Node
# 任务系统 - 管理所有任务和进度

class_name QuestSystem

signal quest_started(quest_id)
signal quest_updated(quest_id, progress)
signal quest_completed(quest_id, rewards)
signal quest_failed(quest_id)

# 任务类型枚举
enum QuestType {
	KILL,           # 击杀敌人
	COLLECT,        # 收集物品
	EXTRACT,        # 撤离指定地图
	DELIVER,        # 交付物品给商人
	DISCOVER,       # 发现地点
	SURVIVE         # 在战局中存活一定时间
}

# 任务状态枚举
enum QuestStatus {
	LOCKED,         # 未解锁
	AVAILABLE,      # 可接受
	ACTIVE,         # 进行中
	COMPLETED,      # 已完成
	FAILED          # 已失败
}

# 任务数据库
var quest_database = {
	"quest_001": {
		"id": "quest_001",
		"title": "初次出击",
		"description": "进入任意地图并成功撤离",
		"type": QuestType.EXTRACT,
		"giver": "prapor",
		"requirements": {
			"map": "any",
			"extract_success": true
		},
		"rewards": {
			"exp": 500,
			"rubles": 5000,
			"items": [{"id": "ak74n", "count": 1}]
		},
		"unlock_requirements": [],
		"next_quests": ["quest_002"]
	},
	"quest_002": {
		"id": "quest_002",
		"title": "清理Scav",
		"description": "在任意地图击杀3名Scav",
		"type": QuestType.KILL,
		"giver": "prapor",
		"requirements": {
			"target_type": "scav",
			"count": 3
		},
		"rewards": {
			"exp": 800,
			"rubles": 8000,
			"trader_rep": {"prapor": 0.05}
		},
		"unlock_requirements": ["quest_001"],
		"next_quests": ["quest_003"]
	},
	"quest_003": {
		"id": "quest_003",
		"title": "医疗物资",
		"description": "找到并上交2个AI-2急救包给Therapist",
		"type": QuestType.DELIVER,
		"giver": "therapist",
		"requirements": {
			"items": [{"id": "ai2_medkit", "count": 2}]
		},
		"rewards": {
			"exp": 600,
			"rubles": 3000,
			"trader_rep": {"therapist": 0.08},
			"items": [{"id": "salewa_first_aid", "count": 1}]
		},
		"unlock_requirements": ["quest_001"],
		"next_quests": ["quest_004"]
	},
	"quest_004": {
		"id": "quest_004",
		"title": "PMC猎手",
		"description": "在战局中击杀1名PMC",
		"type": QuestType.KILL,
		"giver": "prapor",
		"requirements": {
			"target_type": "pmc",
			"count": 1
		},
		"rewards": {
			"exp": 1200,
			"rubles": 15000,
			"trader_rep": {"prapor": 0.1}
		},
		"unlock_requirements": ["quest_002"],
		"next_quests": ["quest_005"]
	},
	"quest_005": {
		"id": "quest_005",
		"title": "装备升级",
		"description": "找到一件等级2或以上的护甲",
		"type": QuestType.COLLECT,
		"giver": "ragman",
		"requirements": {
			"item_type": "armor",
			"min_armor_class": 2,
			"count": 1
		},
		"rewards": {
			"exp": 700,
			"rubles": 6000,
			"trader_rep": {"ragman": 0.06}
		},
		"unlock_requirements": ["quest_002"],
		"next_quests": []
	}
}

# 玩家任务数据
var player_quests = {}  # quest_id -> {status, progress, completed_at}
var active_quests: Array[String] = []
var completed_quests: Array[String] = []

func _ready():
	print("任务系统已加载")
	initialize_quests()

# 初始化任务状态
func initialize_quests():
	for quest_id in quest_database:
		if not player_quests.has(quest_id):
			var quest_data = quest_database[quest_id]
			var can_unlock = check_unlock_requirements(quest_data)
			
			player_quests[quest_id] = {
				"status": QuestStatus.AVAILABLE if can_unlock else QuestStatus.LOCKED,
				"progress": {},
				"completed_at": 0
			}

# 检查解锁条件
func check_unlock_requirements(quest_data: Dictionary) -> bool:
	var requirements = quest_data.get("unlock_requirements", [])
	if requirements.is_empty():
		return true
	
	for req_quest_id in requirements:
		if not completed_quests.has(req_quest_id):
			return false
	return true

# 接受任务
func accept_quest(quest_id: String) -> bool:
	if not quest_database.has(quest_id):
		print("任务不存在：", quest_id)
		return false
	
	var quest_state = player_quests[quest_id]
	if quest_state.status != QuestStatus.AVAILABLE:
		print("任务无法接受，当前状态：", quest_state.status)
		return false
	
	quest_state.status = QuestStatus.ACTIVE
	active_quests.append(quest_id)
	
	# 初始化进度
	var quest_data = quest_database[quest_id]
	match quest_data.type:
		QuestType.KILL:
			quest_state.progress = {
				"kills": 0,
				"target_type": quest_data.requirements.get("target_type", "any")
			}
		QuestType.COLLECT:
			quest_state.progress = {
				"collected": 0
			}
		QuestType.EXTRACT:
			quest_state.progress = {
				"extracted": false
			}
		QuestType.DELIVER:
			quest_state.progress = {
				"delivered": {}
			}
		QuestType.SURVIVE:
			quest_state.progress = {
				"time_survived": 0.0
			}
	
	quest_started.emit(quest_id)
	print("接受任务：", quest_data.title)
	return true

# 更新击杀进度
func record_kill(enemy_type: String):
	for quest_id in active_quests:
		var quest_data = quest_database[quest_id]
		var quest_state = player_quests[quest_id]
		
		if quest_data.type == QuestType.KILL:
			var target_type = quest_data.requirements.get("target_type", "any")
			if target_type == "any" or target_type == enemy_type:
				quest_state.progress.kills += 1
				check_quest_completion(quest_id)
				quest_updated.emit(quest_id, quest_state.progress)

# 更新收集进度
func record_item_collected(item_id: String, item_data: Dictionary = {}):
	for quest_id in active_quests:
		var quest_data = quest_database[quest_id]
		var quest_state = player_quests[quest_id]
		
		if quest_data.type == QuestType.COLLECT:
			var required_type = quest_data.requirements.get("item_type", "")
			var min_class = quest_data.requirements.get("min_armor_class", 0)
			
			if required_type == "" or item_data.get("type") == required_type:
				if min_class == 0 or item_data.get("armor_class", 0) >= min_class:
					quest_state.progress.collected += 1
					check_quest_completion(quest_id)
					quest_updated.emit(quest_id, quest_state.progress)

# 记录成功撤离
func record_extraction(map_name: String, success: bool):
	for quest_id in active_quests:
		var quest_data = quest_database[quest_id]
		var quest_state = player_quests[quest_id]
		
		if quest_data.type == QuestType.EXTRACT:
			var required_map = quest_data.requirements.get("map", "any")
			if required_map == "any" or required_map == map_name:
				if success:
					quest_state.progress.extracted = true
					check_quest_completion(quest_id)
					quest_updated.emit(quest_id, quest_state.progress)

# 检查任务完成
func check_quest_completion(quest_id: String):
	var quest_data = quest_database[quest_id]
	var quest_state = player_quests[quest_id]
	
	var completed = false
	
	match quest_data.type:
		QuestType.KILL:
			var required_kills = quest_data.requirements.get("count", 1)
			completed = quest_state.progress.kills >= required_kills
		
		QuestType.COLLECT:
			var required_count = quest_data.requirements.get("count", 1)
			completed = quest_state.progress.collected >= required_count
		
		QuestType.EXTRACT:
			completed = quest_state.progress.extracted
		
		QuestType.DELIVER:
			# 交付任务需要在商人界面手动处理
			pass
		
		QuestType.SURVIVE:
			var required_time = quest_data.requirements.get("time", 300)
			completed = quest_state.progress.time_survived >= required_time
	
	if completed:
		complete_quest(quest_id)

# 完成任务
func complete_quest(quest_id: String):
	var quest_data = quest_database[quest_id]
	var quest_state = player_quests[quest_id]
	
	quest_state.status = QuestStatus.COMPLETED
	quest_state.completed_at = Time.get_unix_time_from_system()
	
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	
	# 发放奖励
	give_rewards(quest_data.rewards)
	
	# 解锁后续任务
	for next_quest_id in quest_data.get("next_quests", []):
		if player_quests.has(next_quest_id):
			player_quests[next_quest_id].status = QuestStatus.AVAILABLE
	
	quest_completed.emit(quest_id, quest_data.rewards)
	print("任务完成：", quest_data.title)

# 发放奖励
func give_rewards(rewards: Dictionary):
	if rewards.has("exp"):
		PlayerData.gain_experience(rewards.exp)
	
	if rewards.has("rubles"):
		PlayerData.add_money("rubles", rewards.rubles)
	
	if rewards.has("dollars"):
		PlayerData.add_money("dollars", rewards.dollars)
	
	if rewards.has("euros"):
		PlayerData.add_money("euros", rewards.euros)
	
	if rewards.has("trader_rep"):
		for trader_id in rewards.trader_rep:
			var rep_amount = rewards.trader_rep[trader_id]
			increase_trader_reputation(trader_id, rep_amount)
	
	if rewards.has("items"):
		for item_reward in rewards.items:
			var item_id = item_reward.id
			var count = item_reward.get("count", 1)
			var item_data = LootSystem.item_database.get(item_id, {})
			if not item_data.is_empty():
				for i in range(count):
					InventoryManager.add_item_to_stash(item_data.duplicate())

# 增加商人声望
func increase_trader_reputation(trader_id: String, amount: float):
	if PlayerData.traders.has(trader_id):
		PlayerData.traders[trader_id].rep += amount
		
		# 检查升级
		var current_level = PlayerData.traders[trader_id].level
		var required_rep = current_level * 10.0
		
		if PlayerData.traders[trader_id].rep >= required_rep and current_level < 4:
			PlayerData.traders[trader_id].level += 1
			print("商人 %s 好感度提升到等级 %d!" % [trader_id, current_level + 1])

# 获取商人的可用任务
func get_available_quests_for_trader(trader_id: String) -> Array:
	var available = []
	for quest_id in quest_database:
		var quest_data = quest_database[quest_id]
		if quest_data.giver == trader_id:
			var quest_state = player_quests[quest_id]
			if quest_state.status == QuestStatus.AVAILABLE:
				available.append(quest_data)
	return available

# 获取进行中的任务
func get_active_quests() -> Array:
	var active = []
	for quest_id in active_quests:
		active.append(quest_database[quest_id])
	return active

# 获取任务进度文本
func get_quest_progress_text(quest_id: String) -> String:
	if not quest_database.has(quest_id):
		return ""
	
	var quest_data = quest_database[quest_id]
	var quest_state = player_quests[quest_id]
	
	match quest_data.type:
		QuestType.KILL:
			var current = quest_state.progress.get("kills", 0)
			var target = quest_data.requirements.get("count", 1)
			return "%d/%d 击杀" % [current, target]
		
		QuestType.COLLECT:
			var current = quest_state.progress.get("collected", 0)
			var target = quest_data.requirements.get("count", 1)
			return "%d/%d 收集" % [current, target]
		
		QuestType.EXTRACT:
			return "已撤离" if quest_state.progress.get("extracted", false) else "未撤离"
		
		QuestType.DELIVER:
			return "待交付"
		
		QuestType.SURVIVE:
			var current = quest_state.progress.get("time_survived", 0)
			var target = quest_data.requirements.get("time", 300)
			return "%d/%d 秒" % [int(current), target]
	
	return ""

# 保存任务数据
func save_quest_data() -> Dictionary:
	return {
		"player_quests": player_quests,
		"active_quests": active_quests,
		"completed_quests": completed_quests
	}

# 加载任务数据
func load_quest_data(data: Dictionary):
	if data.has("player_quests"):
		player_quests = data.player_quests
	if data.has("active_quests"):
		active_quests = data.active_quests
	if data.has("completed_quests"):
		completed_quests = data.completed_quests
