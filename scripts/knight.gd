extends CharacterBody2D

var SPEED = 130.0
var jump_velocity = -360.0

@export var sword_scene: PackedScene        # 拖 Sword.tscn

@onready var hurt_box: Area2D = $HurtBox
@onready var dead_sound: AudioStreamPlayer = $DeadSound
@onready var hurt_sound: AudioStreamPlayer = $HurtSound
@onready var camera: Camera2D = $Camera2D

var current_sword: Node = null 

var dead : bool = false
var invulnerable := false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
    #死亡后什么都不做
    if dead:
        velocity = Vector2.ZERO
        return
    
    # Add the gravity.
    if not is_on_floor():
        velocity.y += gravity * delta

    # Handle jump.
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    # Get the input direction: -1, 0, 1
    var direction = Input.get_axis("left", "right")
    
    # Flip the Sprite
    if direction > 0:
        animated_sprite.flip_h = false
    elif direction < 0:
        animated_sprite.flip_h = true
    
    # Play animations
    if is_on_floor():
        if direction == 0:
            animated_sprite.play("idle")
        else:
            animated_sprite.play("run")
    else:
        animated_sprite.play("jump")
    
    # Apply movement
    if direction:
        velocity.x = direction * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)

    move_and_slide()


func _on_hurt_box_area_entered(area: Area2D) -> void:
    if dead or invulnerable or not area.get_parent().is_in_group("enemy"):
        return
        
    if area.get_parent().is_in_group("enemy"):
        PlayerHealth.take_damage(1)
        if PlayerHealth.health == 0:
            die()
            return
        
        start_invulnerability()
        
    pass # Replace with function body.

func start_invulnerability() -> void:
    invulnerable = true
    hurt_sound.play()
    # 闪烁动画：0.1 秒 × 10 次 = 1 秒
    var tween = create_tween().set_loops(10)
    tween.tween_property(animated_sprite, "modulate:a", 0.2, 0.05)
    tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.05)
    await get_tree().create_timer(1.0).timeout
    invulnerable = false

func die()->void:
    dead = true
    hurt_box.set_deferred("monitoring",false)
    dead_sound.play()
    animated_sprite.play("die")
    await animated_sprite.animation_finished
    get_tree().change_scene_to_file("res://scenes/start_game.tscn")

func _unhandled_input(_event):
    if dead:return
    # 只要引擎收到按键，就用全局 Input 判断
    if Input.is_action_just_pressed("throw") and current_sword == null:
        throw_sword()

func throw_sword():
    var sword = sword_scene.instantiate() as Node2D
    # 出生在玩家中心
    sword.global_position = global_position
    # 朝向
    var dir = 1 if animated_sprite.flip_h == false else -1
    sword.init(self, dir)
    
    # 加入世界
    get_tree().current_scene.add_child(sword)
    current_sword = sword
    
    # ④ 剑销毁时自动清引用（弱引用不会阻止队列释放）
    sword.tree_exited.connect(func(): current_sword = null)

func camera_shake(strength := 12.0, duration := 0.2):
    camera.set_process(true)                       # 打开抖动
    camera.offset = Vector2.ZERO
    var t := get_tree().create_timer(duration)
    t.timeout.connect(func(): camera.set_process(false); camera.offset = Vector2.ZERO)
    
