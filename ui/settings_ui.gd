extends Control
# 设置界面 - 音量、画质、控制等选项

class_name SettingsUI

@onready var master_volume_slider: HSlider = $Panel/VBoxContainer/ScrollContainer/SettingsList/MasterVolume/Slider
@onready var music_volume_slider: HSlider = $Panel/VBoxContainer/ScrollContainer/SettingsList/MusicVolume/Slider
@onready var sfx_volume_slider: HSlider = $Panel/VBoxContainer/ScrollContainer/SettingsList/SFXVolume/Slider
@onready var ambient_volume_slider: HSlider = $Panel/VBoxContainer/ScrollContainer/SettingsList/AmbientVolume/Slider
@onready var fullscreen_checkbox: CheckBox = $Panel/VBoxContainer/ScrollContainer/SettingsList/Fullscreen/CheckBox
@onready var vsync_checkbox: CheckBox = $Panel/VBoxContainer/ScrollContainer/SettingsList/VSync/CheckBox
@onready var mouse_sensitivity_slider: HSlider = $Panel/VBoxContainer/ScrollContainer/SettingsList/MouseSensitivity/Slider
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton
@onready var save_button: Button = $Panel/VBoxContainer/ButtonContainer/SaveButton
@onready var reset_button: Button = $Panel/VBoxContainer/ButtonContainer/ResetButton

var settings_data = {
	"master_volume": 1.0,
	"music_volume": 0.7,
	"sfx_volume": 0.8,
	"ambient_volume": 0.5,
	"fullscreen": false,
	"vsync": true,
	"mouse_sensitivity": 1.0
}

const SETTINGS_FILE = "user://settings.save"

func _ready():
	close_button.pressed.connect(close_settings)
	save_button.pressed.connect(save_settings)
	reset_button.pressed.connect(reset_to_default)
	
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	ambient_volume_slider.value_changed.connect(_on_ambient_volume_changed)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	vsync_checkbox.toggled.connect(_on_vsync_toggled)
	mouse_sensitivity_slider.value_changed.connect(_on_mouse_sensitivity_changed)
	
	load_settings()
	visible = false
	print("设置UI已加载")

func toggle():
	if visible:
		close_settings()
	else:
		open_settings()

func open_settings():
	visible = true
	GameManager.change_state(GameManager.GameState.TRADING)  # 使用 TRADING 状态作为暂停状态
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_settings():
	visible = false
	GameManager.change_state(GameManager.GameState.HIDEOUT)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_master_volume_changed(value: float):
	settings_data.master_volume = value / 100.0
	AudioManager.set_master_volume(settings_data.master_volume)
	update_slider_label(master_volume_slider, value)

func _on_music_volume_changed(value: float):
	settings_data.music_volume = value / 100.0
	AudioManager.set_music_volume(settings_data.music_volume)
	update_slider_label(music_volume_slider, value)

func _on_sfx_volume_changed(value: float):
	settings_data.sfx_volume = value / 100.0
	AudioManager.set_sfx_volume(settings_data.sfx_volume)
	update_slider_label(sfx_volume_slider, value)

func _on_ambient_volume_changed(value: float):
	settings_data.ambient_volume = value / 100.0
	AudioManager.set_ambient_volume(settings_data.ambient_volume)
	update_slider_label(ambient_volume_slider, value)

func update_slider_label(slider: HSlider, value: float):
	var parent = slider.get_parent()
	var label = parent.get_node_or_null("ValueLabel")
	if label:
		label.text = "%d%%" % int(value)

func _on_fullscreen_toggled(enabled: bool):
	settings_data.fullscreen = enabled
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_vsync_toggled(enabled: bool):
	settings_data.vsync = enabled
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED)

func _on_mouse_sensitivity_changed(value: float):
	settings_data.mouse_sensitivity = value / 50.0
	update_slider_label(mouse_sensitivity_slider, value)

func save_settings():
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file:
		file.store_var(settings_data)
		file.close()
		print("设置已保存")
	else:
		print("保存设置失败")

func load_settings():
	if FileAccess.file_exists(SETTINGS_FILE):
		var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
		if file:
			var loaded_data = file.get_var()
			file.close()
			if loaded_data is Dictionary:
				settings_data.merge(loaded_data, true)
	
	apply_settings()

func apply_settings():
	# 应用音量设置
	master_volume_slider.value = settings_data.master_volume * 100.0
	music_volume_slider.value = settings_data.music_volume * 100.0
	sfx_volume_slider.value = settings_data.sfx_volume * 100.0
	ambient_volume_slider.value = settings_data.ambient_volume * 100.0
	
	AudioManager.set_master_volume(settings_data.master_volume)
	AudioManager.set_music_volume(settings_data.music_volume)
	AudioManager.set_sfx_volume(settings_data.sfx_volume)
	AudioManager.set_ambient_volume(settings_data.ambient_volume)
	
	# 应用显示设置
	fullscreen_checkbox.button_pressed = settings_data.fullscreen
	vsync_checkbox.button_pressed = settings_data.vsync
	
	if settings_data.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if settings_data.vsync else DisplayServer.VSYNC_DISABLED
	)
	
	# 应用鼠标灵敏度
	mouse_sensitivity_slider.value = settings_data.mouse_sensitivity * 50.0

func reset_to_default():
	settings_data = {
		"master_volume": 1.0,
		"music_volume": 0.7,
		"sfx_volume": 0.8,
		"ambient_volume": 0.5,
		"fullscreen": false,
		"vsync": true,
		"mouse_sensitivity": 1.0
	}
	apply_settings()
	print("设置已重置为默认值")
