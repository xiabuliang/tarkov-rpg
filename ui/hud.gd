extends CanvasLayer
# 游戏内HUD界面

class_name HUD

@onready var health_bar: ProgressBar = $VBoxContainer/HealthBar
@onready var stamina_bar: ProgressBar = $VBoxContainer/StaminaBar
@onready var ammo_label: Label = $AmmoLabel
@onready var weapon_label: Label = $WeaponLabel
@onready var weight_label: Label = $WeightLabel
@onready var raid_timer_label: Label = $RaidTimerLabel
@onready var minimap: TextureRect = $Minimap
@onready var hit_marker: ColorRect = $HitMarker
@onready var damage_overlay: ColorRect = $DamageOverlay
@onready var interaction_prompt: Label = $InteractionPrompt

var player: PlayerController = null

func _ready():
	hit_marker.visible = false
	damage_overlay.visible = false
	interaction_prompt.visible = false
	print("HUD已加载")

func setup(player_ref: PlayerController):
	player = player_ref
	
	# 连接信号
	player.health_changed.connect(_on_health_changed)
	player.stamina_changed.connect(_on_stamina_changed)
	player.weapon_changed.connect(_on_weapon_changed)
	player.ammo_changed.connect(_on_ammo_changed)
	player.died.connect(_on_player_died)
	
	# 初始化显示
	_on_health_changed(player.current_health, player.max_health)
	_on_stamina_changed(player.current_stamina, player.max_stamina)

func _process(delta):
	update_raid_timer()
	update_weight()
	update_interaction_prompt()

func update_raid_timer():
	if GameManager.current_state == GameManager.GameState.RAID_IN_PROGRESS:
		var elapsed = GameManager.raid_timer
		var minutes = int(elapsed / 60)
		var seconds = int(elapsed) % 60
		raid_timer_label.text = "%02d:%02d" % [minutes, seconds]
		
		# 时间少于5分钟变红
		if elapsed > GameManager.max_raid_time - 300:
			raid_timer_label.modulate = Color.RED
	else:
		raid_timer_label.text = ""

func update_weight():
	var current_weight = InventoryManager.get_inventory_weight()
	var max_weight = InventoryManager.get_max_carry_weight()
	weight_label.text = "%.1f / %.1f kg" % [current_weight, max_weight]
	
	if InventoryManager.is_overweight():
		weight_label.modulate = Color.RED
	elif current_weight > max_weight * 0.8:
		weight_label.modulate = Color.YELLOW
	else:
		weight_label.modulate = Color.WHITE

func update_interaction_prompt():
	if player == null or player.nearby_interactables.is_empty():
		interaction_prompt.visible = false
		return
	
	var interactable = player.nearby_interactables[0]
	var prompt_text = "按 E 交互"
	
	if interactable is LootContainer:
		prompt_text = "按 E 搜刮 [%s]" % interactable.container_type
	elif interactable is LootableCorpse:
		prompt_text = "按 E 搜刮尸体"
	elif interactable is ExtractionPoint:
		prompt_text = "按 E 撤离 [%s]" % interactable.extraction_name
	
	interaction_prompt.text = prompt_text
	interaction_prompt.visible = true

func _on_health_changed(current: float, max_health: float):
	health_bar.max_value = max_health
	health_bar.value = current
	health_bar.get_node("Label").text = "生命 %.0f/%.0f" % [current, max_health]
	
	# 低血量警告
	if current < max_health * 0.3:
		health_bar.modulate = Color.RED
		show_damage_overlay()
	elif current < max_health * 0.6:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.GREEN
		hide_damage_overlay()

func _on_stamina_changed(current: float, max_stamina: float):
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current
	stamina_bar.get_node("Label").text = "体力 %.0f/%.0f" % [current, max_stamina]

func _on_weapon_changed(weapon_data: Dictionary):
	if weapon_data.is_empty():
		weapon_label.text = "无武器"
	else:
		weapon_label.text = weapon_data.get("name", "未知武器")

func _on_ammo_changed(current: int, reserve: int):
	ammo_label.text = "%d / %d" % [current, reserve]
	
	# 低弹药警告
	if current == 0:
		ammo_label.modulate = Color.RED
	elif current < 5:
		ammo_label.modulate = Color.YELLOW
	else:
		ammo_label.modulate = Color.WHITE

func _on_player_died():
	show_death_screen()

func show_hit_marker():
	hit_marker.visible = true
	await get_tree().create_timer(0.1).timeout
	hit_marker.visible = false

func show_damage_overlay():
	damage_overlay.visible = true
	damage_overlay.modulate = Color(1, 0, 0, 0.3)

func hide_damage_overlay():
	damage_overlay.visible = false

func show_death_screen():
	# TODO: 显示死亡界面
	print("玩家死亡 - 显示死亡界面")

func show_extraction_warning():
	# 显示撤离点关闭警告
	pass
