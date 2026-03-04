extends CanvasLayer
# 移动端触摸控制 - 虚拟摇杆和按钮

class_name MobileControls

@onready var left_joystick: Control = $LeftJoystick
@onready var right_joystick: Control = $RightJoystick
@onready var action_buttons: Control = $ActionButtons

# 摇杆状态
var left_joystick_vector: Vector2 = Vector2.ZERO
var right_joystick_vector: Vector2.ZERO
var left_joystick_active: bool = false
var right_joystick_active: bool = false

# 按钮状态
var is_sprinting: bool = false
var is_crouching: bool = false
var is_shooting: bool = false
var is_aiming: bool = false

# 配置
var joystick_radius: float = 60.0
var joystick_deadzone: float = 0.2

func _ready():
	# 只在移动平台显示
	if not is_mobile_platform():
		visible = false
		return
	
	setup_touch_controls()
	print("移动端控制已加载")

func is_mobile_platform() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("mobile")

func setup_touch_controls():
	# 设置左摇杆（移动）
	left_joystick.gui_input.connect(_on_left_joystick_input)
	
	# 设置右摇杆（瞄准）
	right_joystick.gui_input.connect(_on_right_joystick_input)
	
	# 设置动作按钮
	for button in action_buttons.get_children():
		if button is Button:
			match button.name:
				"SprintButton":
					button.button_down.connect(func(): is_sprinting = true)
					button.button_up.connect(func(): is_sprinting = false)
				"CrouchButton":
					button.pressed.connect(toggle_crouch)
				"ShootButton":
					button.button_down.connect(func(): is_shooting = true)
					button.button_up.connect(func(): is_shooting = false)
				"AimButton":
					button.button_down.connect(func(): is_aiming = true)
					button.button_up.connect(func(): is_aiming = false)
				"ReloadButton":
					button.pressed.connect(func():
						Input.action_press("reload")
						await get_tree().create_timer(0.1).timeout
						Input.action_release("reload")
					)
				"InteractButton":
					button.pressed.connect(func():
						Input.action_press("interact")
						await get_tree().create_timer(0.1).timeout
						Input.action_release("interact")
					)
				"InventoryButton":
					button.pressed.connect(func():
						Input.action_press("inventory")
						await get_tree().create_timer(0.1).timeout
						Input.action_release("inventory")
					)

func _on_left_joystick_input(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			left_joystick_active = true
			update_joystick(left_joystick, event.position, true)
		else:
			left_joystick_active = false
			left_joystick_vector = Vector2.ZERO
			reset_joystick_visual(left_joystick)
	elif event is InputEventScreenDrag and left_joystick_active:
		update_joystick(left_joystick, event.position, true)

func _on_right_joystick_input(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			right_joystick_active = true
			update_joystick(right_joystick, event.position, false)
		else:
			right_joystick_active = false
			right_joystick_vector = Vector2.ZERO
			reset_joystick_visual(right_joystick)
	elif event is InputEventScreenDrag and right_joystick_active:
		update_joystick(right_joystick, event.position, false)

func update_joystick(joystick: Control, touch_pos: Vector2, is_left: bool):
	var center = joystick.global_position + joystick.size / 2
	var delta = touch_pos - center
	var distance = delta.length()
	
	# 限制在摇杆半径内
	if distance > joystick_radius:
		delta = delta.normalized() * joystick_radius
		distance = joystick_radius
	
	# 计算输入向量
	var input_vector = delta / joystick_radius
	
	# 应用死区
	if input_vector.length() < joystick_deadzone:
		input_vector = Vector2.ZERO
	
	if is_left:
		left_joystick_vector = input_vector
	else:
		right_joystick_vector = input_vector
	
	# 更新视觉
	var knob = joystick.get_node_or_null("Knob")
	if knob:
		knob.position = joystick.size / 2 + delta

func reset_joystick_visual(joystick: Control):
	var knob = joystick.get_node_or_null("Knob")
	if knob:
		knob.position = joystick.size / 2

func _process(_delta):
	if not visible:
		return
	
	# 将摇杆输入转换为游戏输入
	if left_joystick_active:
		# 水平移动
		if left_joystick_vector.x < -joystick_deadzone:
			Input.action_press("move_left", abs(left_joystick_vector.x))
		else:
			Input.action_release("move_left")
		
		if left_joystick_vector.x > joystick_deadzone:
			Input.action_press("move_right", abs(left_joystick_vector.x))
		else:
			Input.action_release("move_right")
		
		# 垂直移动
		if left_joystick_vector.y < -joystick_deadzone:
			Input.action_press("move_up", abs(left_joystick_vector.y))
		else:
			Input.action_release("move_up")
		
		if left_joystick_vector.y > joystick_deadzone:
			Input.action_press("move_down", abs(left_joystick_vector.y))
		else:
			Input.action_release("move_down")
	else:
		# 释放所有移动键
		Input.action_release("move_left")
		Input.action_release("move_right")
		Input.action_release("move_up")
		Input.action_release("move_down")
	
	# 冲刺（双击摇杆或按住冲刺按钮）
	if is_sprinting:
		Input.action_press("sprint")
	else:
		Input.action_release("sprint")
	
	# 射击
	if is_shooting:
		Input.action_press("shoot")
	else:
		Input.action_release("shoot")
	
	# 瞄准
	if is_aiming:
		Input.action_press("aim")
	else:
		Input.action_release("aim")

func toggle_crouch():
	is_crouching = !is_crouching
	if is_crouching:
		Input.action_press("crouch")
	else:
		Input.action_release("crouch")

# 获取瞄准方向（用于射击）
func get_aim_direction() -> Vector2:
	if right_joystick_active and right_joystick_vector.length() > joystick_deadzone:
		return right_joystick_vector.normalized()
	return Vector2.ZERO
