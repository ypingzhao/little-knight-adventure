extends CharacterBody2D
class_name Bat

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_box: Area2D = $HitBox
@onready var hurt_sound: AudioStreamPlayer = $HurtSound


@export var bat_hp:int = 1
@export var speed := 120.0          # 基础左飞速度
@export var sine_amplitude := 90.0  # 上下摆动幅度
@export var sine_frequency := 1.0   # 摆动快慢

signal invulnerability_ended() 
var invulnerable:bool = false

var dead = false
var _base_y := 0.0                  # 生成时的 Y（中心线）
var _life_time := 0.0               # 累计时间，用于 sin

func _ready() -> void:
    _base_y = global_position.y
    # 连接屏幕外自毁信号
    $VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)
    animated_sprite.play("fly")
    
    
#func _process(_delta: float) -> void:
    

func _physics_process(delta: float) -> void:
    if dead == true:
        velocity = Vector2(0,20)
        move_and_collide(velocity * delta)  
        return
    
    _life_time += delta

    # 1. 水平匀速左飞
    velocity = Vector2.LEFT * speed
    animated_sprite.flip_h = true

    # 2. 垂直 S 曲线
    velocity.y = sine_amplitude * sin(_life_time * sine_frequency * TAU)

    # 3. 应用移动
    move_and_collide(velocity * delta)
    
func take_damage(_amount:int)->void:
    print("bat hurt!")
    bat_hp -= _amount
    if bat_hp >0:
        start_invulnerability()
    elif bat_hp <= 0:
        
        start_invulnerability()
        hit_box.set_deferred("monitorable",false)
        die()
        #invulnerability_ended.connect(die,CONNECT_ONE_SHOT)

func die()->void:
    dead = true
    print("die active!")
    
    animated_sprite.play("die")
    await animated_sprite.animation_finished
    queue_free()

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
