extends CharacterBody2D
# 玩家控制器
# 负责移动、射击、交互等核心玩法

class_name PlayerController

signal health_changed(current, max_health)
signal stamina_changed(current, max_stamina)
signal weapon_changed(weapon_data)
signal ammo_changed(current_ammo, reserve_ammo)
signal died()

# 移动参数
@export var walk_speed: float = 150.0
@export var sprint_speed: float = 280.0
@export var crouch_speed: float = 80.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0

# 体力参数
@export var max_stamina: float = 100.0
@export var stamina_regen_rate: float = 15.0
@export var sprint_stamina_cost: float = 25.0
@export var jump_stamina_cost: float = 20.0

var current_stamina: float = max_stamina
var is_sprinting: bool = false
var is_crouching: bool = false

# 健康系统
var max_health: float = 100.0
var current_health: float = 100.0

# 身体部位伤害（塔科夫特色）
var body_parts = {
	"head": {"health": 35, "max": 35},
	"thorax": {"health": 85, "max": 85},
	"stomach": {"health": 70, "max": 70},
	"left_arm": {"health": 60, "max": 60},
	"right_arm": {"health": 60, "max": 60},
	"left_leg": {"health": 65, "max": 65},
	"right_leg": {"health": 65, "max": 65}
}

# 武器系统
var current_weapon: Dictionary = {}
var primary_weapon: Dictionary = {}
var secondary_weapon: Dictionary = {}
var current_ammo: int = 0
var reserve_ammo: int = 0
var is_reloading: bool = false
var can_shoot: bool = true

# 瞄准
var is_aiming: bool = false
@export var aim_zoom: float = 0.8
var normal_zoom: float = 1.0

# 交互
var interact_range: float = 100.0
var nearby_interactables: Array = []

# 组件引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var muzzle_position: Marker2D = $WeaponPivot/MuzzlePosition
@onready var interaction_ray: RayCast2D = $InteractionRay
@onready var camera: Camera2D = $Camera2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var reload_timer: Timer = $ReloadTimer
@onready var shoot_cooldown: Timer = $ShootCooldown

func _ready():
	add_to_group("player")
	current_health = max_health
	current_stamina = max_stamina
	update_body_part_health()
	
	# 连接信号
	reload_timer.timeout.connect(_on_reload_finished)
	shoot_cooldown.timeout.connect(_on_shoot_cooldown_finished)
	
	print("玩家控制器已初始化")

func _physics_process(delta):
	handle_movement(delta)
	handle_stamina(delta)
	handle_aiming()
	handle_interaction_detection()
	move_and_slide()

func _process(delta):
	handle_input()
	update_animation()

func handle_input():
	# 射击
	if Input.is_action_pressed("shoot") and can_shoot and not is_reloading:
		shoot()
	
	# 瞄准
	is_aiming = Input.is_action_pressed("aim")
	
	# 换弹
	if Input.is_action_just_pressed("reload") and not is_reloading:
		start_reload()
	
	# 交互
	if Input.is_action_just_pressed("interact"):
		interact()
	
	# 切换武器
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory()
	
	# 冲刺
	is_sprinting = Input.is_action_pressed("sprint") and current_stamina > 0 and not is_crouching
	
	# 蹲伏
	if Input.is_action_just_pressed("crouch"):
		toggle_crouch()

func handle_movement(delta):
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# 根据状态确定速度
	var target_speed = walk_speed
	if is_crouching:
		target_speed = crouch_speed
	elif is_sprinting and current_stamina > 0:
		target_speed = sprint_speed
		use_stamina(sprint_stamina_cost * delta)
	
	# 应用重量惩罚
	target_speed *= InventoryManager.get_movement_penalty()
	
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * target_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# 朝向鼠标方向
	look_at(get_global_mouse_position())

func handle_stamina(delta):
	if is_sprinting:
		use_stamina(sprint_stamina_cost * delta)
	else:
		recover_stamina(stamina_regen_rate * delta)

func use_stamina(amount: float):
	current_stamina -= amount
	if current_stamina < 0:
		current_stamina = 0
		is_sprinting = false
	stamina_changed.emit(current_stamina, max_stamina)

func recover_stamina(amount: float):
	current_stamina += amount
	if current_stamina > max_stamina:
		current_stamina = max_stamina
	stamina_changed.emit(current_stamina, max_stamina)

func handle_aiming():
	if is_aiming:
		camera.zoom = lerp(camera.zoom, Vector2(aim_zoom, aim_zoom), 0.1)
		# 减少移动速度
		walk_speed = 100.0
	else:
		camera.zoom = lerp(camera.zoom, Vector2(normal_zoom, normal_zoom), 0.1)
		walk_speed = 150.0

func shoot():
	if current_weapon.is_empty():
		return
	
	if current_ammo <= 0:
		start_reload()
		return
	
	# 消耗弹药
	current_ammo -= 1
	ammo_changed.emit(current_ammo, reserve_ammo)
	
	# 计算射击精度（根据移动状态、瞄准状态、技能）
	var accuracy = calculate_accuracy()
	
	# 发射子弹
	fire_bullet(accuracy)
	
	# 后坐力
	apply_recoil()
	
	# 设置射击冷却
	can_shoot = false
	var fire_rate = current_weapon.get("fire_rate", 600)
	shoot_cooldown.wait_time = 60.0 / fire_rate
	shoot_cooldown.start()
	
	# 播放动画和音效
	animation_player.play("shoot")
	# TODO: 播放枪声音效

func fire_bullet(accuracy: float):
	var bullet_scene = preload("res://scenes/bullet.tscn")
	var bullet = bullet_scene.instantiate()
	
	# 计算射击方向（加入散布）
	var base_direction = (get_global_mouse_position() - muzzle_position.global_position).normalized()
	var spread_angle = (1.0 - accuracy) * 0.3  # 最大30度散布
	var random_angle = randf_range(-spread_angle, spread_angle)
	var final_direction = base_direction.rotated(random_angle)
	
	bullet.global_position = muzzle_position.global_position
	bullet.direction = final_direction
	bullet.damage = current_weapon.get("damage", 30)
	bullet.penetration = get_current_ammo_penetration()
	bullet.shooter = self
	
	get_tree().current_scene.add_child(bullet)

func calculate_accuracy() -> float:
	var base_accuracy = 0.8
	
	# 瞄准加成
	if is_aiming:
		base_accuracy += 0.15
	
	# 移动惩罚
	if velocity.length() > 10:
		base_accuracy -= 0.2
	
	# 蹲伏加成
	if is_crouching:
		base_accuracy += 0.05
	
	# 武器人机工效
	if not current_weapon.is_empty():
		var ergonomics = current_weapon.get("ergonomics", 50)
		base_accuracy += (ergonomics - 50) / 1000.0
	
	# 技能加成
	var sniping_level = PlayerData.skills.get("sniping", 1)
	base_accuracy += sniping_level * 0.01
	
	return clamp(base_accuracy, 0.1, 1.0)

func apply_recoil():
	if current_weapon.is_empty():
		return
	
	var vertical_recoil = current_weapon.get("recoil_vertical", 100)
	var horizontal_recoil = current_weapon.get("recoil_horizontal", 200)
	
	# 技能减免
	var recoil_control = PlayerData.skills.get("recoil_control", 1)
	var reduction = recoil_control * 0.02
	
	vertical_recoil *= (1.0 - reduction)
	horizontal_recoil *= (1.0 - reduction)
	
	# 应用旋转（模拟后坐力）
	rotation_degrees += randf_range(-horizontal_recoil/10, horizontal_recoil/10) * 0.01

func start_reload():
	if is_reloading or current_weapon.is_empty():
		return
	
	if reserve_ammo <= 0 or current_ammo >= current_weapon.get("mag_size", 30):
		return
	
	is_reloading = true
	can_shoot = false
	
	# 计算换弹时间（受技能影响）
	var reload_time = 2.5
	var mag_drills = PlayerData.skills.get("mag_drills", 1)
	reload_time *= (1.0 - mag_drills * 0.03)
	
	reload_timer.wait_time = reload_time
	reload_timer.start()
	
	animation_player.play("reload")
	print("开始换弹...")

func _on_reload_finished():
	var mag_size = current_weapon.get("mag_size", 30)
	var needed = mag_size - current_ammo
	var to_load = min(needed, reserve_ammo)
	
	current_ammo += to_load
	reserve_ammo -= to_load
	
	is_reloading = false
	can_shoot = true
	ammo_changed.emit(current_ammo, reserve_ammo)
	print("换弹完成")

func _on_shoot_cooldown_finished():
	can_shoot = true

func toggle_crouch():
	is_crouching = !is_crouching
	if is_crouching:
		$CollisionShape2D.scale.y = 0.6
		sprite.scale.y = 0.6
	else:
		$CollisionShape2D.scale.y = 1.0
		sprite.scale.y = 1.0

func handle_interaction_detection():
	interaction_ray.target_position = Vector2(interact_range, 0).rotated(rotation)
	interaction_ray.force_raycast_update()
	
	nearby_interactables.clear()
	
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider.has_method("interact"):
			nearby_interactables.append(collider)
			# TODO: 显示交互提示UI

func interact():
	for obj in nearby_interactables:
		if obj.has_method("interact"):
			obj.interact(self)
			break

func toggle_inventory():
	GameManager.change_state(GameManager.GameState.INVENTORY)
	# TODO: 打开背包UI

func equip_weapon(weapon_data: Dictionary, slot: String):
	match slot:
		"primary":
			primary_weapon = weapon_data
			if current_weapon.is_empty():
				switch_to_primary()
		"secondary":
			secondary_weapon = weapon_data
			if current_weapon.is_empty():
				switch_to_secondary()

func switch_to_primary():
	if not primary_weapon.is_empty():
		current_weapon = primary_weapon
		current_ammo = primary_weapon.get("current_ammo", 0)
		reserve_ammo = primary_weapon.get("reserve_ammo", 0)
		weapon_changed.emit(current_weapon)
		ammo_changed.emit(current_ammo, reserve_ammo)

func switch_to_secondary():
	if not secondary_weapon.is_empty():
		current_weapon = secondary_weapon
		current_ammo = secondary_weapon.get("current_ammo", 0)
		reserve_ammo = secondary_weapon.get("reserve_ammo", 0)
		weapon_changed.emit(current_weapon)
		ammo_changed.emit(current_ammo, reserve_ammo)

func get_current_ammo_penetration() -> int:
	# TODO: 根据当前使用的弹药类型返回穿透值
	return 25

func take_damage(damage: float, body_part: String, penetration: int = 0):
	if not body_parts.has(body_part):
		return
	
	var part = body_parts[body_part]
	
	# 护甲减伤计算
	var armor = InventoryManager.equipment.get("body_armor")
	var damage_reduction = 0.0
	
	if armor != null and body_part in ["thorax", "stomach"]:
		var armor_class = armor.get("armor_class", 1)
		var durability = armor.get("durability", 100)
		
		# 穿透判定
		if penetration >= armor_class * 10:
			# 穿透成功，部分减伤
			damage_reduction = 0.2
		else:
			# 未穿透，大幅减伤但消耗护甲耐久
			damage_reduction = 0.8
			armor.durability -= damage * 0.5
	
	damage *= (1.0 - damage_reduction)
	
	# 头部暴击倍率
	if body_part == "head":
		damage *= 2.5
	
	part.health -= damage
	
	# 检查死亡
	if part.health <= 0:
		part.health = 0
		if body_part == "head" or body_part == "thorax":
			die()
		return
	
	# 更新总生命值显示
	update_total_health()
	health_changed.emit(current_health, max_health)

func update_body_part_health():
	var total = 0
	var max_total = 0
	for part_name in body_parts:
		total += body_parts[part_name].health
		max_total += body_parts[part_name].max
	
	current_health = total
	max_health = max_total

func update_total_health():
	update_body_part_health()

func heal_body_part(body_part: String, amount: float):
	if not body_parts.has(body_part):
		return
	
	body_parts[body_part].health += amount
	if body_parts[body_part].health > body_parts[body_part].max:
		body_parts[body_part].health = body_parts[body_part].max
	
	update_total_health()
	health_changed.emit(current_health, max_health)

func die():
	died.emit()
	GameManager.fail_raid("KIA - 阵亡")
	queue_free()

func update_animation():
	if velocity.length() > 10:
		if is_sprinting:
			animation_player.play("sprint")
		elif is_crouching:
			animation_player.play("crouch_walk")
		else:
			animation_player.play("walk")
	else:
		if is_crouching:
			animation_player.play("crouch_idle")
		else:
			animation_player.play("idle")
