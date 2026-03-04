extends Control
# 主菜单

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var load_button: Button = $VBoxContainer/LoadButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var version_label: Label = $VersionLabel

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	version_label.text = "Tarkov RPG v0.1 - Godot 4.3"
	
	# 检查是否有存档
	var has_save = FileAccess.file_exists("user://player_save.json")
	load_button.disabled = not has_save
	
	print("主菜单已加载")

func _on_start_pressed():
	print("开始新游戏")
	GameManager.start_new_game()

func _on_load_pressed():
	print("加载游戏")
	GameManager.load_game()

func _on_settings_pressed():
	print("打开设置")
	var settings_ui = get_node_or_null("/root/SettingsUI")
	if settings_ui:
		settings_ui.toggle()
	else:
		# 动态加载设置界面
		var settings_scene = load("res://scenes/settings_ui.tscn")
		if settings_scene:
			var settings_instance = settings_scene.instantiate()
			get_tree().root.add_child(settings_instance)
			settings_instance.toggle()

func _on_quit_pressed():
	print("退出游戏")
	GameManager.quit_game()
