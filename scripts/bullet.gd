extends Area2D
# 子弹/投射物

class_name Bullet

var direction: Vector2 = Vector2.RIGHT
var speed: float = 1200.0
var damage: float = 30.0
var penetration: int = 25
var max_distance: float = 2000.0
var traveled_distance: float = 0.0
var shooter: Node = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	var velocity = direction * speed * delta
	position += velocity
	traveled_distance += velocity.length()
	
	if traveled_distance >= max_distance:
		queue_free()

func _on_body_entered(body: Node2D):
	if body == shooter:
		return
	
	if body.has_method("take_damage"):
		# 确定命中部位（简化版）
		var hit_part = "thorax"
		if body.is_in_group("player") or body.is_in_group("enemy"):
			hit_part = calculate_hit_part(body)
		
		body.take_damage(damage, hit_part, penetration)
		print("命中", body.name, "部位:", hit_part, "伤害:", damage)
	
	# 生成击中效果
	create_hit_effect()
	
	queue_free()

func calculate_hit_part(body: Node2D) -> String:
	# 根据击中位置判断身体部位
	# 简化处理：随机分配，实际应该根据碰撞区域
	var parts = ["head", "thorax", "stomach", "left_arm", "right_arm", "left_leg", "right_leg"]
	var weights = [0.05, 0.25, 0.20, 0.15, 0.15, 0.10, 0.10]  # 头部概率最低
	
	var random = randf()
	var cumulative = 0.0
	
	for i in range(parts.size()):
		cumulative += weights[i]
		if random <= cumulative:
			return parts[i]
	
	return "thorax"

func create_hit_effect():
	# TODO: 实例化粒子效果或弹孔贴图
	pass
