extends Node
# 游戏管理器 - 全局单例
# 负责游戏状态、场景切换、存档管理等核心功能

signal game_started()
signal game_paused()
signal game_resumed()
signal raid_started(map_name)
signal raid_ended(success, loot_value)
signal player_spawned(position)

# 游戏状态枚举
enum GameState {
	MAIN_MENU,
	HIDEOUT,           # 藏身处/基地
	RAID_LOADING,      # 加载中
	RAID_IN_PROGRESS,  # 正在进行战局
	RAID_EXTRACTING,   # 正在撤离
	INVENTORY,         # 打开背包界面
	TRADING,           # 交易界面
	HEALING            # 治疗界面
}

var current_state: GameState = GameState.MAIN_MENU
var current_map: String = ""
var raid_timer: float = 0.0
var max_raid_time: float = 3600.0  # 1小时

# 玩家实例引用
var player_instance: Node = null

# 当前战局数据
var current_raid_data = {
	"map": "",
	"start_time": 0,
	"loot_found": [],
	"kills": 0,
	"deaths": 0,
	"extracted": false
}

func _ready():
	print("游戏管理器已加载")
	process_mode = Node.PROCESS_MODE_ALWAYS  # 暂停时也能运行

func _process(delta):
	if current_state == GameState.RAID_IN_PROGRESS:
		raid_timer += delta
		if raid_timer >= max_raid_time:
			force_end_raid()

# 开始新游戏
func start_new_game():
	PlayerData.reset_data()
	change_state(GameState.HIDEOUT)
	game_started.emit()
	print("开始新游戏")

# 加载游戏
func load_game():
	PlayerData.load_player_data()
	change_state(GameState.HIDEOUT)
	game_started.emit()
	print("加载游戏")

# 保存游戏
func save_game():
	PlayerData.save_player_data()
	print("游戏已保存")

# 开始战局（进入地图）
func start_raid(map_name: String):
	current_map = map_name
	current_raid_data = {
		"map": map_name,
		"start_time": Time.get_unix_time_from_system(),
		"loot_found": [],
		"kills": 0,
		"deaths": 0,
		"extracted": false
	}
	raid_timer = 0.0
	
	change_state(GameState.RAID_LOADING)
	
	# 加载地图场景
	var map_scene_path = "res://scenes/maps/" + map_name + ".tscn"
	if ResourceLoader.exists(map_scene_path):
		get_tree().change_scene_to_file(map_scene_path)
	else:
		print("地图不存在：", map_name)
		return
	
	change_state(GameState.RAID_IN_PROGRESS)
	raid_started.emit(map_name)
	print("开始战局：", map_name)

# 生成玩家
func spawn_player(spawn_position: Vector2):
	var player_scene = preload("res://scenes/player.tscn")
	player_instance = player_scene.instantiate()
	player_instance.position = spawn_position
	get_tree().current_scene.add_child(player_instance)
	player_spawned.emit(spawn_position)
	print("玩家在", spawn_position, "生成")

# 成功撤离
func extract(extract_point_name: String):
	if current_state != GameState.RAID_IN_PROGRESS:
		return
	
	change_state(GameState.RAID_EXTRACTING)
	
	# 计算战利品价值
	var total_loot_value = 0
	for item in current_raid_data.loot_found:
		total_loot_value += item.get("value", 0)
	
	current_raid_data.extracted = true
	
	# 给予经验和金钱奖励
	var exp_reward = calculate_exp_reward()
	PlayerData.gain_experience(exp_reward)
	
	# 转移战利品到仓库
	transfer_loot_to_stash()
	
	raid_ended.emit(true, total_loot_value)
	PlayerData.extraction_success.emit(total_loot_value)
	
	print("成功撤离！战利品价值：", total_loot_value)
	
	# 返回藏身处
	end_raid_and_return()

# 战局失败（死亡或超时）
func fail_raid(reason: String):
	if current_state != GameState.RAID_IN_PROGRESS:
		return
	
	change_state(GameState.RAID_EXTRACTING)
	
	# 失去带入的所有物品
	lose_all_raid_gear()
	
	current_raid_data.deaths += 1
	
	raid_ended.emit(false, 0)
	print("战局失败：", reason)
	
	# 返回藏身处
	end_raid_and_return()

# 强制结束战局（超时）
func force_end_raid():
	fail_raid("MIA - 未能在时间限制内撤离")

# 结束战局并返回
func end_raid_and_return():
	change_state(GameState.HIDEOUT)
	get_tree().change_scene_to_file("res://scenes/hideout.tscn")
	player_instance = null
	current_map = ""

# 计算经验奖励
func calculate_exp_reward() -> int:
	var base_exp = 100
	var kill_bonus = current_raid_data.kills * 50
	var loot_bonus = 0
	for item in current_raid_data.loot_found:
		loot_bonus += item.get("value", 0) / 1000
	
	var survival_bonus = 200 if current_raid_data.extracted else 0
	var headshot_bonus = 0  # TODO: 追踪爆头击杀
	
	return base_exp + kill_bonus + loot_bonus + survival_bonus + headshot_bonus

# 将战利品转移到仓库
func transfer_loot_to_stash():
	for item in current_raid_data.loot_found:
		# 尝试添加到仓库
		if not add_item_to_stash(item):
			print("仓库已满，无法存放：", item.get("name"))
			# TODO: 出售或丢弃

func add_item_to_stash(item: Dictionary) -> bool:
	# TODO: 实现仓库添加逻辑
	return true

# 失去所有战局装备
func lose_all_raid_gear():
	# 清除当前装备和背包中的所有物品
	InventoryManager.equipment = {
		"head": null,
		"face_cover": null,
		"ears": null,
		"body_armor": null,
		"backpack": null,
		"tactical_rig": null,
		"primary_weapon": null,
		"secondary_weapon": null,
		"holster": null,
		"scabbard": null,
		"pockets": [null, null, null, null],
	}
	InventoryManager.initialize_containers()
	print("失去了所有战局装备")

# 添加找到的战利品
func add_found_loot(item: Dictionary):
	current_raid_data.loot_found.append(item)
	print("找到战利品：", item.get("name"))

# 记录击杀
func record_kill(enemy_type: String, was_headshot: bool = false):
	current_raid_data.kills += 1
	var exp_gain = 100 if enemy_type == "pmc" else 50
	if was_headshot:
		exp_gain *= 1.5
	PlayerData.gain_experience(int(exp_gain))
	print("击杀：", enemy_type, " 经验+", exp_gain)

# 状态管理
func change_state(new_state: GameState):
	var old_state = current_state
	current_state = new_state
	
	match new_state:
		GameState.RAID_IN_PROGRESS:
			get_tree().paused = false
		GameState.INVENTORY, GameState.TRADING:
			get_tree().paused = true
			game_paused.emit()
		_:
			get_tree().paused = false
			if old_state == GameState.INVENTORY or old_state == GameState.TRADING:
				game_resumed.emit()
	
	print("游戏状态：", GameState.keys()[old_state], "->", GameState.keys()[new_state])

func pause_game():
	if current_state == GameState.RAID_IN_PROGRESS:
		get_tree().paused = true
		game_paused.emit()

func resume_game():
	if current_state == GameState.RAID_IN_PROGRESS:
		get_tree().paused = false
		game_resumed.emit()

# 退出游戏
func quit_game():
	save_game()
	get_tree().quit()
