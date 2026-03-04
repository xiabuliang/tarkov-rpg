extends Area2D
# 撤离点

class_name ExtractionPoint

signal player_entered_extraction_zone()
signal player_left_extraction_zone()
signal extraction_started(time_remaining)
signal extraction_completed()

@export var extraction_name: String = "撤离点"
@export var extraction_time: float = 10.0  # 撤离所需时间（秒）
@export var is_always_available: bool = true
@export var requires_item: String = ""  # 需要的物品ID（如"car_key"）
@export var min_players: int = 1  # 最少需要多少玩家（组队用）
@export var max_players: int = 5  # 最多允许多少玩家

var players_in_zone: Array = []
var is_extracting: bool = false
var extraction_timer: float = 0.0
var is_available: bool = true

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var label: Label = $Label
@onready var timer_label: Label = $TimerLabel
@onready var availability_timer: Timer = $AvailabilityTimer

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	availability_timer.timeout.connect(_on_availability_changed)
	
	update_label()
	
	if not is_always_available:
		setup_random_availability()

func setup_random_availability():
	# 随机设置撤离点的可用性
	is_available = randf() < 0.7  # 70%概率初始可用
	var next_change = randf_range(30.0, 120.0)
	availability_timer.start(next_change)

func _on_availability_changed():
	is_available = !is_available
	update_label()
	
	if is_available:
		print("撤离点 [", extraction_name, "] 现已开放")
	else:
		print("撤离点 [", extraction_name, "] 已关闭")
		# 如果有人正在撤离，取消撤离
		if is_extracting:
			cancel_extraction()
	
	# 设置下次变化时间
	var next_change = randf_range(60.0, 300.0)
	availability_timer.start(next_change)

func _process(delta):
	if is_extracting:
		extraction_timer -= delta
		timer_label.text = str(int(extraction_timer) + 1) + "s"
		
		if extraction_timer <= 0:
			complete_extraction()

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		players_in_zone.append(body)
		body.nearby_interactables.append(self)
		player_entered_extraction_zone.emit()
		update_label()
		
		if can_extract():
			start_extraction()

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		players_in_zone.erase(body)
		body.nearby_interactables.erase(self)
		player_left_extraction_zone.emit()
		
		if players_in_zone.is_empty() and is_extracting:
			cancel_extraction()
		
		update_label()

func can_extract() -> bool:
	if not is_available:
		return false
	
	if players_in_zone.is_empty():
		return false
	
	if players_in_zone.size() < min_players:
		return false
	
	if players_in_zone.size() > max_players:
		return false
	
	# 检查是否需要特定物品
	if requires_item != "":
		var has_item = false
		for player in players_in_zone:
			# TODO: 检查玩家是否有该物品
			pass
		if not has_item:
			return false
	
	return true

func start_extraction():
	if is_extracting:
		return
	
	is_extracting = true
	extraction_timer = extraction_time
	extraction_started.emit(extraction_time)
	
	label.text = "正在撤离..."
	timer_label.visible = true
	
	print("开始撤离倒计时:", extraction_time, "秒")

func cancel_extraction():
	if not is_extracting:
		return
	
	is_extracting = false
	extraction_timer = 0.0
	
	label.text = "撤离取消 - 离开区域"
	timer_label.visible = false
	
	await get_tree().create_timer(2.0).timeout
	update_label()

func complete_extraction():
	is_extracting = false
	extraction_completed.emit()
	
	print("撤离成功！")
	
	# 让所有区域内的玩家撤离
	for player in players_in_zone:
		if player.has_method("extract"):
			player.extract(extraction_name)
	
	GameManager.extract(extraction_name)

func interact(player: Node2D):
	# 如果玩家手动交互，也尝试开始撤离
	if can_extract():
		start_extraction()
	else:
		show_requirements()

func show_requirements():
	var msg = "无法撤离:\n"
	
	if not is_available:
		msg += "- 撤离点当前不可用\n"
	
	if players_in_zone.size() < min_players:
		msg += "- 需要至少 " + str(min_players) + " 名玩家\n"
	
	if requires_item != "":
		msg += "- 需要物品: " + requires_item + "\n"
	
	print(msg)
	# TODO: 显示UI提示

func update_label():
	if is_extracting:
		return
	
	if not is_available:
		label.text = extraction_name + "\n[不可用]"
	elif players_in_zone.is_empty():
		label.text = extraction_name + "\n[进入以撤离]"
	else:
		var count = players_in_zone.size()
		label.text = extraction_name + "\n[" + str(count) + " 名玩家]"

func get_status() -> Dictionary:
	return {
		"name": extraction_name,
		"available": is_available,
		"players_in_zone": players_in_zone.size(),
		"extracting": is_extracting,
		"time_remaining": extraction_timer if is_extracting else 0
	}
