extends Node
# 音效管理器 - 管理所有游戏音效和音乐

class_name AudioManager

# 音频播放器
@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var ambient_player: AudioStreamPlayer = AudioStreamPlayer.new()

# 音量设置 (0.0 - 1.0)
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var ambient_volume: float = 0.5

# 当前播放的音乐
var current_music: String = ""
var music_tracks = {
	"main_menu": null,      # res://assets/audio/music/main_menu.ogg
	"hideout": null,        # res://assets/audio/music/hideout.ogg
	"raid_ambient": null,   # res://assets/audio/music/raid_ambient.ogg
	"combat": null,         # res://assets/audio/music/combat.ogg
	"extraction": null      # res://assets/audio/music/extraction.ogg
}

# 音效库
var sfx_library = {
	# 武器音效
	"gunshot_pistol": null,     # res://assets/audio/sfx/gunshot_pistol.wav
	"gunshot_rifle": null,      # res://assets/audio/sfx/gunshot_rifle.wav
	"gunshot_smg": null,        # res://assets/audio/sfx/gunshot_smg.wav
	"reload_start": null,       # res://assets/audio/sfx/reload_start.wav
	"reload_finish": null,      # res://assets/audio/sfx/reload_finish.wav
	"empty_click": null,        # res://assets/audio/sfx/empty_click.wav
	"shell_casing": null,       # res://assets/audio/sfx/shell_casing.wav
	
	# 玩家音效
	"footstep_concrete": null,  # res://assets/audio/sfx/footstep_concrete.wav
	"footstep_grass": null,     # res://assets/audio/sfx/footstep_grass.wav
	"footstep_metal": null,     # res://assets/audio/sfx/footstep_metal.wav
	"jump": null,               # res://assets/audio/sfx/jump.wav
	"land": null,               # res://assets/audio/sfx/land.wav
	"pain_light": null,         # res://assets/audio/sfx/pain_light.wav
	"pain_heavy": null,         # res://assets/audio/sfx/pain_heavy.wav
	"death": null,              # res://assets/audio/sfx/death.wav
	"breathing": null,          # res://assets/audio/sfx/breathing.wav
	
	# 物品音效
	"item_pickup": null,        # res://assets/audio/sfx/item_pickup.wav
	"item_drop": null,          # res://assets/audio/sfx/item_drop.wav
	"inventory_open": null,     # res://assets/audio/sfx/inventory_open.wav
	"inventory_close": null,    # res://assets/audio/sfx/inventory_close.wav
	"equip_weapon": null,       # res://assets/audio/sfx/equip_weapon.wav
	"unequip_weapon": null,     # res://assets/audio/sfx/unequip_weapon.wav
	"use_medkit": null,         # res://assets/audio/sfx/use_medkit.wav
	"eat": null,                # res://assets/audio/sfx/eat.wav
	"drink": null,              # res://assets/audio/sfx/drink.wav
	
	# 环境音效
	"door_open": null,          # res://assets/audio/sfx/door_open.wav
	"door_close": null,         # res://assets/audio/sfx/door_close.wav
	"container_open": null,     # res://assets/audio/sfx/container_open.wav
	"container_close": null,    # res://assets/audio/sfx/container_close.wav
	"button_click": null,       # res://assets/audio/sfx/button_click.wav
	"ui_hover": null,           # res://assets/audio/sfx/ui_hover.wav
	
	# 战斗音效
	"bullet_impact_concrete": null,  # res://assets/audio/sfx/bullet_impact_concrete.wav
	"bullet_impact_metal": null,     # res://assets/audio/sfx/bullet_impact_metal.wav
	"bullet_impact_flesh": null,     # res://assets/audio/sfx/bullet_impact_flesh.wav
	"headshot": null,                # res://assets/audio/sfx/headshot.wav
	"armor_hit": null,               # res://assets/audio/sfx/armor_hit.wav
	"ricochet": null,                # res://assets/audio/sfx/ricochet.wav
	
	# 敌人音效
	"enemy_alert": null,        # res://assets/audio/sfx/enemy_alert.wav
	"enemy_death": null,        # res://assets/audio/sfx/enemy_death.wav
	"enemy_pain": null,         # res://assets/audio/sfx/enemy_pain.wav
	
	# 特殊音效
	"extraction_start": null,   # res://assets/audio/sfx/extraction_start.wav
	"extraction_complete": null,# res://assets/audio/sfx/extraction_complete.wav
	"level_up": null,           # res://assets/audio/sfx/level_up.wav
	"quest_complete": null,     # res://assets/audio/sfx/quest_complete.wav
	"trader_level_up": null,    # res://assets/audio/sfx/trader_level_up.wav
	"low_health": null,         # res://assets/audio/sfx/low_health.wav
	"stamina_low": null         # res://assets/audio/sfx/stamina_low.wav
}

func _ready():
	add_child(music_player)
	add_child(sfx_player)
	add_child(ambient_player)
	
	music_player.bus = "Music"
	sfx_player.bus = "SFX"
	ambient_player.bus = "Ambient"
	
	print("音效管理器已加载")

# 播放音乐
func play_music(track_name: String, fade_duration: float = 1.0):
	if not music_tracks.has(track_name):
		print("音乐轨道不存在：", track_name)
		return
	
	if current_music == track_name:
		return
	
	current_music = track_name
	var stream = music_tracks[track_name]
	
	if stream == null:
		print("音乐文件未加载：", track_name)
		return
	
	# 淡入淡出效果
	if music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_duration)
		tween.tween_callback(func():
			music_player.stream = stream
			music_player.volume_db = -80.0
			music_player.play()
			create_tween().tween_property(music_player, "volume_db", linear_to_db(music_volume * master_volume), fade_duration)
		)
	else:
		music_player.stream = stream
		music_player.volume_db = linear_to_db(music_volume * master_volume)
		music_player.play()

# 停止音乐
func stop_music(fade_duration: float = 1.0):
	if not music_player.playing:
		return
	
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80.0, fade_duration)
	tween.tween_callback(func():
		music_player.stop()
		current_music = ""
	)

# 播放音效
func play_sfx(sfx_name: String, random_pitch: bool = false):
	if not sfx_library.has(sfx_name):
		print("音效不存在：", sfx_name)
		return
	
	var stream = sfx_library[sfx_name]
	if stream == null:
		# 音效文件未加载，静默处理
		return
	
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume * master_volume)
	player.bus = "SFX"
	
	if random_pitch:
		player.pitch_scale = randf_range(0.9, 1.1)
	
	add_child(player)
	player.play()
	
	# 播放完成后自动删除
	await player.finished
	player.queue_free()

# 播放3D音效（用于位置相关的音效）
func play_sfx_3d(sfx_name: String, position: Vector2):
	if not sfx_library.has(sfx_name):
		return
	
	var stream = sfx_library[sfx_name]
	if stream == null:
		return
	
	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume * master_volume)
	player.position = position
	player.max_distance = 1000.0
	player.attenuation = 1.0
	player.bus = "SFX"
	
	get_tree().current_scene.add_child(player)
	player.play()
	
	await player.finished
	player.queue_free()

# 播放环境音效
func play_ambient(ambient_name: String):
	# TODO: 实现环境音效循环播放
	pass

# 设置音量
func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	update_volumes()

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_volume * master_volume)

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)

func set_ambient_volume(volume: float):
	ambient_volume = clamp(volume, 0.0, 1.0)
	ambient_player.volume_db = linear_to_db(ambient_volume * master_volume)

func update_volumes():
	music_player.volume_db = linear_to_db(music_volume * master_volume)
	ambient_player.volume_db = linear_to_db(ambient_volume * master_volume)

# 辅助函数：线性音量转分贝
func linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)

# 根据游戏状态播放合适的音乐
func on_game_state_changed(new_state: GameManager.GameState):
	match new_state:
		GameManager.GameState.MAIN_MENU:
			play_music("main_menu")
		GameManager.GameState.HIDEOUT:
			play_music("hideout")
		GameManager.GameState.RAID_IN_PROGRESS:
			play_music("raid_ambient")
		GameManager.GameState.RAID_EXTRACTING:
			play_music("extraction")

# 快捷方法：常用音效
func play_gunshot(weapon_type: String = "rifle"):
	match weapon_type:
		"pistol":
			play_sfx("gunshot_pistol", true)
		"smg":
			play_sfx("gunshot_smg", true)
		_:
			play_sfx("gunshot_rifle", true)

func play_reload():
	play_sfx("reload_start")

func play_reload_finish():
	play_sfx("reload_finish")

func play_footstep(surface: String = "concrete"):
	match surface:
		"grass":
			play_sfx("footstep_grass")
		"metal":
			play_sfx("footstep_metal")
		_:
			play_sfx("footstep_concrete")

func play_pain(damage: float):
	if damage > 50.0:
		play_sfx("pain_heavy")
	else:
		play_sfx("pain_light")

func play_item_pickup():
	play_sfx("item_pickup")

func play_inventory(open: bool):
	if open:
		play_sfx("inventory_open")
	else:
		play_sfx("inventory_close")

func play_ui_click():
	play_sfx("button_click")

func play_level_up():
	play_sfx("level_up")

func play_quest_complete():
	play_sfx("quest_complete")
