extends CharacterBody2D
# 敌人AI控制器
# 支持巡逻、警戒、追击、攻击等行为

class_name EnemyAI

enum AIState {
	PATROL,      # 巡逻
	ALERT,       # 警戒（听到声音或看到可疑情况）
	INVESTIGATE, # 调查
	CHASE,       # 追击
	ATTACK,      # 攻击
	SEARCH,      # 搜索（丢失目标后）
	RETREAT,     # 撤退/找掩体
	DEAD         # 死亡
}

signal died()
signal spotted_player()

@export var patrol_points: Array[Marker2D] = []
@export var detection_range: float = 400.0
@export var attack_range: float = 300.0
@export var lose_sight_range: float = 600.0
@export var field_of_view: float = 120.0  # 视野角度

@export var walk_speed: float = 80.0
@export var run_speed: float = 180.0

var current_state: AIState = AIState.PATROL
var current_patrol_index: int = 0
var target_position: Vector2 = Vector2.ZERO
var last_known_player_position: Vector2 = Vector2.ZERO
var player_reference: Node2D = null

var health: float = 100.0
var max_health: float = 100.0
var is_armed: bool = true
var can_see_player: bool = false
var time_since_last_sight: float = 0.0
var alert_level: float = 0.0  # 警觉度 0-100

var loadout: Dictionary = {}
var current_weapon: Dictionary = {}
var ammo_count: int = 30

@onready var sprite: Sprite2D = $Sprite2D
@onready var vision_ray: RayCast2D = $VisionRay
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_timer: Timer = $StateTimer
@onready var shoot_timer: Timer = $ShootTimer
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	add_to_group("enemy")
	state_timer.timeout.connect(_on_state_timer_timeout)
	shoot_timer.timeout.connect(_on_shoot)
	
	# 生成装备
	generate_loadout()
	
	if not patrol_points.is_empty():
		target_position = patrol_points[0].global_position
	
	print("敌人AI已初始化")

func generate_loadout():
	var difficulty = randi() % 3 + 1  # 1-3
	loadout = LootSystem.generate_enemy_loadout(difficulty)
	
	if not loadout.weapon.is_empty():
		current_weapon = loadout.weapon
		ammo_count = current_weapon.get("mag_size", 30)
	
	# 应用护甲属性
	if loadout.armor != null:
		max_health += loadout.armor.get("armor_class", 1) * 20
		health = max_health

func _physics_process(delta):
	match current_state:
		AIState.PATROL:
			process_patrol(delta)
		AIState.ALERT:
			process_alert(delta)
		AIState.INVESTIGATE:
			process_investigate(delta)
		AIState.CHASE:
			process_chase(delta)
		AIState.ATTACK:
			process_attack(delta)
		AIState.SEARCH:
			process_search(delta)
		AIState.RETREAT:
			process_retreat(delta)
		AIState.DEAD:
			return
	
	# 检测玩家
	check_for_player()
	
	move_and_slide()

func check_for_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		can_see_player = false
		return
	
	var player = players[0]
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > lose_sight_range:
		can_see_player = false
		if current_state == AIState.CHASE or current_state == AIState.ATTACK:
			transition_to_state(AIState.SEARCH)
		return
	
	# 检查是否在视野范围内
	var direction_to_player = (player.global_position - global_position).normalized()
	var forward_direction = Vector2.RIGHT.rotated(rotation)
	var angle_to_player = rad_to_deg(forward_direction.angle_to(direction_to_player))
	
	if abs(angle_to_player) > field_of_view / 2 and distance_to_player > detection_range * 0.5:
		can_see_player = false
		return
	
	# 射线检测是否有遮挡
	vision_ray.target_position = to_local(player.global_position)
	vision_ray.force_raycast_update()
	
	if vision_ray.is_colliding() and vision_ray.get_collider() == player:
		can_see_player = true
		last_known_player_position = player.global_position
		player_reference = player
		time_since_last_sight = 0.0
		
		if current_state == AIState.PATROL or current_state == ALERT:
			spotted_player.emit()
			transition_to_state(AIState.CHASE)
	elif can_see_player:
		can_see_player = false
		time_since_last_sight = 0.0

func transition_to_state(new_state: AIState):
	if current_state == new_state:
		return
	
	print("AI状态:", AIState.keys()[current_state], "->", AIState.keys()[new_state])
	current_state = new_state
	
	match new_state:
		AIState.PATROL:
			state_timer.start(randf_range(5.0, 10.0))
		AIState.ALERT:
			alert_level = 50.0
			state_timer.start(3.0)
		AIState.INVESTIGATE:
			state_timer.start(10.0)
		AIState.CHASE:
			alert_level = 100.0
		AIState.ATTACK:
			start_attacking()
		AIState.SEARCH:
			state_timer.start(15.0)
		AIState.RETREAT:
			find_cover()

func process_patrol(delta):
	if patrol_points.is_empty():
		velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)
		return
	
	var target = patrol_points[current_patrol_index].global_position
	var direction = (target - global_position).normalized()
	
	if global_position.distance_to(target) < 20:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		target_position = patrol_points[current_patrol_index].global_position
	else:
		velocity = direction * walk_speed
		look_at(target)

func process_alert(delta):
	velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)
	# 四处张望的动画
	rotation += sin(Time.get_time_dict_from_system().second) * 0.5 * delta

func process_investigate(delta):
	if target_position != Vector2.ZERO:
		var direction = (target_position - global_position).normalized()
		velocity = direction * walk_speed
		look_at(target_position)
		
		if global_position.distance_to(target_position) < 20:
			transition_to_state(AIState.SEARCH)

func process_chase(delta):
	if player_reference == null:
		transition_to_state(AIState.SEARCH)
		return
	
	var distance_to_player = global_position.distance_to(player_reference.global_position)
	
	if distance_to_player <= attack_range and can_see_player:
		transition_to_state(AIState.ATTACK)
		return
	
	# 追击
	var direction = (last_known_player_position - global_position).normalized()
	velocity = direction * run_speed
	look_at(last_known_player_position)

func process_attack(delta):
	if player_reference == null:
		transition_to_state(AIState.SEARCH)
		return
	
	var distance_to_player = global_position.distance_to(player_reference.global_position)
	
	if distance_to_player > attack_range * 1.2:
		transition_to_state(AIState.CHASE)
		return
	
	if not can_see_player:
		transition_to_state(AIState.SEARCH)
		return
	
	# 面向玩家
	look_at(player_reference.global_position)
	velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)
	
	# 射击逻辑在 shoot_timer 中处理

func start_attacking():
	if is_armed and not current_weapon.is_empty():
		var fire_rate = current_weapon.get("fire_rate", 600)
		shoot_timer.wait_time = 60.0 / fire_rate
		shoot_timer.start()

func _on_shoot():
	if current_state != AIState.ATTACK or player_reference == null:
		return
	
	if ammo_count <= 0:
		reload()
		return
	
	ammo_count -= 1
	
	# 发射子弹
	var bullet_scene = preload("res://scenes/bullet.tscn")
	var bullet = bullet_scene.instantiate()
	
	# 计算射击方向（加入散布）
	var base_direction = (player_reference.global_position - global_position).normalized()
	var spread = 0.15  # AI散布更大
	var random_angle = randf_range(-spread, spread)
	bullet.direction = base_direction.rotated(random_angle)
	
	bullet.global_position = global_position + bullet.direction * 30
	bullet.damage = current_weapon.get("damage", 30) * randf_range(0.8, 1.2)
	bullet.penetration = 25
	bullet.shooter = self
	
	get_tree().current_scene.add_child(bullet)
	
	# 播放射击动画
	animation_player.play("shoot")

func reload():
	shoot_timer.stop()
	animation_player.play("reload")
	await get_tree().create_timer(2.5).timeout
	ammo_count = current_weapon.get("mag_size", 30)
	
	if current_state == AIState.ATTACK:
		shoot_timer.start()

func process_search(delta):
	# 在最后一次看到玩家的位置附近搜索
	if target_position == Vector2.ZERO:
		target_position = last_known_player_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
	
	var direction = (target_position - global_position).normalized()
	velocity = direction * walk_speed
	look_at(target_position)
	
	if global_position.distance_to(target_position) < 20:
		target_position = Vector2.ZERO
		# 随机选择新搜索点或返回巡逻
		if randf() < 0.3:
			transition_to_state(AIState.PATROL)
		else:
			target_position = last_known_player_position + Vector2(randf_range(-150, 150), randf_range(-150, 150))

func process_retreat(delta):
	# 向掩体移动
	if target_position != Vector2.ZERO:
		var direction = (target_position - global_position).normalized()
		velocity = direction * run_speed
		look_at(target_position)

func find_cover():
	# TODO: 实现寻找最近掩体的逻辑
	target_position = global_position + Vector2(randf_range(-200, 200), randf_range(-200, 200))

func _on_state_timer_timeout():
	match current_state:
		AIState.ALERT:
			transition_to_state(AIState.PATROL)
		AIState.SEARCH:
			transition_to_state(AIState.PATROL)

func take_damage(damage: float, body_part: String, penetration: int = 0):
	# 护甲减伤
	if loadout.armor != null:
		var armor_class = loadout.armor.get("armor_class", 1)
		if penetration < armor_class * 10:
			damage *= 0.3
			loadout.armor.durability -= damage * 0.5
	
	health -= damage
	
	if health <= 0:
		die()
	else:
		# 受伤反应
		if current_state == AIState.PATROL or current_state == AIState.ALERT:
			transition_to_state(AIState.INVESTIGATE)
			target_position = last_known_player_position

func die():
	current_state = AIState.DEAD
	shoot_timer.stop()
	animation_player.play("die")
	
	# 掉落战利品
	drop_loot()
	
	GameManager.record_kill("scav" if loadout.get("difficulty", 1) < 3 else "pmc")
	died.emit()
	
	await get_tree().create_timer(5.0).timeout
	queue_free()

func drop_loot():
	# 创建尸体容器
	var corpse = preload("res://scenes/lootable_corpse.tscn").instantiate()
	corpse.global_position = global_position
	corpse.enemy_loadout = loadout
	corpse.inventory_items = loadout.get("inventory", [])
	get_tree().current_scene.add_child(corpse)
