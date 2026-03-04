extends Node2D
# 测试地图

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var enemy_spawns: Node = $EnemySpawns
@onready var loot_containers: Node = $LootContainers
@onready var extraction_points: Node = $ExtractionPoints

func _ready():
	print("测试地图已加载")
	
	# 生成玩家
	GameManager.spawn_player(player_spawn.global_position)
	
	# 生成敌人
	spawn_enemies()
	
	# 生成战利品容器
	spawn_loot_containers()
	
	# 激活撤离点
	setup_extraction_points()

func spawn_enemies():
	var enemy_scene = preload("res://scenes/enemy.tscn")
	
	for spawn_point in enemy_spawns.get_children():
		if randf() < 0.7:  # 70%概率生成敌人
			var enemy = enemy_scene.instantiate()
			enemy.global_position = spawn_point.global_position
			
			# 设置巡逻点
			if spawn_point.has_method("get_patrol_points"):
				enemy.patrol_points = spawn_point.get_patrol_points()
			
			add_child(enemy)
			print("生成敌人于:", spawn_point.global_position)

func spawn_loot_containers():
	var container_scenes = {
		"weapon_box": preload("res://scenes/containers/weapon_box.tscn"),
		"medical_bag": preload("res://scenes/containers/medical_bag.tscn"),
		"supply_crate": preload("res://scenes/containers/supply_crate.tscn"),
		"duffle_bag": preload("res://scenes/containers/duffle_bag.tscn")
	}
	
	for container_point in loot_containers.get_children():
		var container_type = container_point.get_meta("container_type", "supply_crate")
		
		if container_scenes.has(container_type):
			var container = container_scenes[container_type].instantiate()
			container.global_position = container_point.global_position
			container.rotation = container_point.rotation
			add_child(container)
			print("生成容器 [", container_type, "] 于:", container_point.global_position)

func setup_extraction_points():
	for extract_point in extraction_points.get_children():
		extract_point.extraction_completed.connect(_on_extraction_completed)
		print("设置撤离点:", extract_point.extraction_name)

func _on_extraction_completed():
	print("有玩家成功撤离")
