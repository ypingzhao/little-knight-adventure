extends CharacterBody2D

class_name Slime
const SPEED = 60
const EXPLOSION_FRICTION = 0.99
const GRAVITY = 900
signal invulnerability_ended()

var invulnerable:bool = false
var direction = randi_range(0, 1) * 2 - 1 # 0→-1，1→1
var _base_y: float
var dead: bool = false
var explosion_mode: bool = false  # 是否处于被抛射的爆炸模式
var stabilized: bool = false  # 是否已稳定到地面（防止边缘检测抽搐）

@export var slime_hp:int = 2
@onready var hurt_sound: AudioStreamPlayer = $HurtSound
@onready var ray_cast_right: RayCast2D = $RayCast2DRight
@onready var ray_cast_left: RayCast2D = $RayCast2Dleft
@onready var ray_cast_down_a: RayCast2D = $RayCast2DDownA
@onready var ray_cast_down_b: RayCast2D = $RayCast2DDownB
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_box: Area2D = $HitBox

func _ready():
    _base_y = global_position.y
    dead = false

func set_explosion_vel(initial_vel: Vector2):
    velocity = initial_vel
    direction = sign(velocity.x)
    explosion_mode = true  # 启用爆炸模式，保持抛射速度

func _physics_process(delta: float) -> void:
    if slime_hp <= 0 or dead:
        return

    velocity.y += GRAVITY * delta

    # 爆炸模式：保持抛射速度，逐渐减速直到恢复正常
    if explosion_mode:
        # 应用摩擦力
        velocity.x *= EXPLOSION_FRICTION
        
         # ↓↓↓ 插入的修复代码 ↓↓↓
        # 【关键修复】爆炸模式下检测墙壁碰撞，反弹并更新方向
        if ray_cast_right.is_colliding():
            velocity.x = -abs(velocity.x)  # 反向水平速度
            direction = -1  # 更新方向
            animated_sprite.flip_h = not animated_sprite.flip_h
        elif ray_cast_left.is_colliding():
            velocity.x = abs(velocity.x)  # 反向水平速度
            direction = 1  # 更新方向
            animated_sprite.flip_h = not animated_sprite.flip_h
        # ↑↑↑ 插入的修复代码 ↑↑↑
        
        # 当水平速度很小时，退出爆炸模式，恢复正常AI
        if abs(velocity.x) < SPEED:
            explosion_mode = false
            stabilized = false  # 重置稳定标志，等待落地稳定
            direction = sign(velocity.x) if velocity.x != 0 else direction

        move_and_slide()
        return

    # 正常AI模式
    # 墙壁检测：设置反向速度并翻转
    if ray_cast_right.is_colliding():
        velocity.x = -abs(velocity.x) if velocity.x != 0 else -SPEED
        _flip_direction()
    elif ray_cast_left.is_colliding():
        velocity.x = abs(velocity.x) if velocity.x != 0 else SPEED
        _flip_direction()
    # 检测是否在地面，稳定后才能进行边缘检测
    if is_on_floor():
        stabilized = true
        
    # 边缘检测：只有稳定后才能检测边缘（防止抽搐）
    if stabilized and (not ray_cast_down_a.is_colliding() or not ray_cast_down_b.is_colliding()):
        _flip_direction()

    # 统一设置水平速度（使用翻转后的 direction）
    velocity.x = direction * SPEED

    # 应用移动
    move_and_slide()

    

func take_damage(_amount:int)->void:
    print("slime hurt!")
    slime_hp -= _amount
    if slime_hp > 0:
        start_invulnerability()
    elif slime_hp <= 0:
        # 死亡：闪烁动画后消失
        hit_box.set_deferred("monitorable", false)
        die_with_flash()

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
    invulnerability_ended.emit()

func die() -> void:
    dead = true
    print("die active!")
    # 记录本轮击杀数
    GlobalData.add_session_enemy_killed("slime_green")
    # 禁用物理处理，防止继续移动
    set_physics_process(false)
    # 禁用碰撞，防止触发其他事件
    hit_box.set_deferred("monitorable", false)
    # 播放死亡动画
    animated_sprite.play("die")
    # 等待动画完成后再释放
    await animated_sprite.animation_finished
    print("die animation finished, queue_free")
    queue_free()

func die_with_flash() -> void:
    dead = true
    print("die with flash!")
    # 记录本轮击杀数
    GlobalData.add_session_enemy_killed("slime_green")
    # 禁用物理处理
    set_physics_process(false)
    # 播放受伤音效
    hurt_sound.play()
    # 闪烁动画：0.1 秒 × 10 次 = 1 秒
    var tween = create_tween().set_loops(10)
    tween.tween_property(animated_sprite, "modulate:a", 0.2, 0.05)
    tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.05)
    await get_tree().create_timer(1.0).timeout
    print("flash finished, queue_free")
    queue_free()

func end_invulnerability() -> void:
    invulnerable = false
    hit_box.set_deferred("monitorable",true)
    invulnerability_ended.emit()

func _flip_direction():
    direction *= -1
    animated_sprite.flip_h = not animated_sprite.flip_h
