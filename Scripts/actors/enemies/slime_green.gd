extends CharacterBody2D
# 移除 class_name 以避免与全局单例冲突

const SPEED = 60
const EXPLOSION_FRICTION = 0.99
signal invulnerability_ended() 
var invulnerable:bool = false

var direction = randi_range(0, 1) * 2 - 1   # 0→-1，1→1


@export var slime_hp:int = 2

@onready var hurt_sound: AudioStreamPlayer = $HurtSound
@onready var ray_cast_right: RayCast2D = $RayCast2DRight
@onready var ray_cast_left: RayCast2D = $RayCast2Dleft
@onready var ray_cast_down_a: RayCast2D = $RayCast2DDownA
@onready var ray_cast_down_b: RayCast2D = $RayCast2DDownB

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_box: Area2D = $HitBox

# GreenSlime.gd  新增
#var velocity: Vector2 = Vector2.ZERO
const GRAVITY = 900.0

func set_explosion_vel(initial_vel: Vector2):
    velocity = initial_vel
    direction = sign(velocity.x)        # 先按爆炸方向走

func _physics_process(delta: float) -> void:
    if slime_hp <=0:
        return
        
    # 1. 重力
    velocity.y += GRAVITY * delta
    

    # 2. 脚下无平台 → 立刻掉头（防掉落）
    if not ray_cast_down_a.is_colliding() or not ray_cast_down_b.is_colliding():
        _flip_direction()

    # 3. 左右射线碰墙 → 掉头
    if ray_cast_right.is_colliding():
        velocity.x = -abs(velocity.x) 
        _flip_direction()
    elif ray_cast_left.is_colliding():
        velocity.x = abs(velocity.x)
        _flip_direction()

# 2. 爆炸水平速度自然衰减
    if abs(velocity.x) > SPEED:
        velocity.x *= EXPLOSION_FRICTION
        #if abs(velocity.x) < SPEED:     # 衰减到 patrol 速度
            #velocity.x = SPEED * direction
    else:
        # 正常巡逻
        velocity.x = direction * SPEED
    # 5. 移动
    move_and_slide()


# ===== 工具：只在一帧内翻转一次 =====
func _flip_direction() -> void:
    direction *= -1
    animated_sprite.flip_h = direction < 0

func take_damage(_amount:int)->void:
    print("enmey hurt!")
    slime_hp -= _amount
    if slime_hp >0:
        start_invulnerability()
    elif slime_hp <= 0:
        start_invulnerability()
        hit_box.set_deferred("monitorable",false)
        invulnerability_ended.connect(queue_free,CONNECT_ONE_SHOT)

func start_invulnerability() -> void:
    invulnerable = true
    hurt_sound.play()
    hit_box.set_deferred("monitorable",false)
    # 闪烁动画：0.1 秒 × 10 次 = 1 秒
    var tween = create_tween().set_loops(10)
    tween.tween_property(animated_sprite, "modulate:a", 0.2, 0.05)
    tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.05)
    await get_tree().create_timer(1.0).timeout
    invulnerable = false
    hit_box.set_deferred("monitorable",true)
    invulnerability_ended.emit()   # ← 通知世界
