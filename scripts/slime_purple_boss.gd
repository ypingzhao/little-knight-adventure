extends CharacterBody2D
class_name RedSlimeBoss

# region 导出变量
@export var max_hp: int = 10
@export var speed: float = 400.0
@export var jump_height: int = 80
@export var small_slime_scene: PackedScene   # 拖 green_slime.tscn
@export var projectile_scene: PackedScene    # 拖抛物线弹丸（Area2D）
# endregion

# 声明自定义信号（放在导出变量或状态变量区域）
signal boss_battle_finish  # BOSS 战斗结束信号（可携带参数，如是否胜利等）
signal invulnerability_ended
# region 状态变量
var hp: int = max_hp:
    set = set_hp
var stage: int = 1
var current_skill: String = ""
var skill_queue: Array[String] = []
var player: Node
var ground_y: float
var invulnerable:bool = false

const GRAVITY        = 3000.0   # 比玩家重力大，看起来更沉重
const JUMP_VELOCITY  = -400.0   # 起跳初速度（向上）
var jump_height_max  = 120.0    # 想跳多高（像素）
var jump_drop_active = false
        
# endregion

@onready var hurt_sound: AudioStreamPlayer = $HurtSound
@onready var hit_box: Area2D = $HitBox
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

# region 常量
const CLOSE_ENOUGH: float = 8.0
const PARABOLA_GRAVITY: float = 900.0
# endregion

# region 生命周期
func _ready():
    player = get_tree().get_first_node_in_group("player")
    ground_y = global_position.y
    push_skill("stage1_aim_dash")
# endregion

# region 血量与阶段
func set_hp(value: int):
    var old = hp
    hp = clampi(value, 0, max_hp)
    print("boss hp:" ,hp)
    if hp == 0:
        _die()
        return
    _check_stage_change(old)

func _physics_process(delta):
    #face player
    animated_sprite.flip_h = global_position.x > player.global_position.x
    
    if jump_drop_active:
        # ————— 起跳阶段 —————
        if velocity.y < 0 and (ground_y - global_position.y) < jump_height_max:
            # 还在上升且没达最大高度 → 继续上升
            pass
        else:
            # 到达顶点或开始下落 → 交给重力
            velocity.y += GRAVITY * delta

        # ————— 落地检测 —————
        move_and_slide()
        if is_on_floor():
            jump_drop_active = false      # 切回正常 AI
            # 这里可以继续发信号、开下一阶段的逻辑
            player.camera_shake() #没有生效
            print("landed")
        return

    # ===== 下面是普通 AI 逻辑 =====
    velocity.y += GRAVITY * delta
    move_and_slide()

func _check_stage_change(_old_hp: int):
    var new_stage = 1
    if hp <= 8: new_stage = 2
    if hp <= 5: new_stage = 3
    if new_stage == stage: return
    stage = new_stage

    # 为每个阶段创建循环计时器（只创建一次）
    match stage:
        2:
            var t2 = Timer.new()
            t2.name = "StageTimer2"
            t2.wait_time = 12.0   # 每 12 秒跳砸
            t2.timeout.connect(_push_stage2, CONNECT_ONE_SHOT)
            add_child(t2); t2.start()
        3:
            var t3 = Timer.new()
            t3.name = "StageTimer3"
            t3.wait_time = 8.0    # 每 8 秒抛物线吐液
            t3.timeout.connect(_push_stage3, CONNECT_ONE_SHOT)
            add_child(t3); t3.start()
# endregion

# region 技能排队
func push_skill(name: String):
    skill_queue.append(name)
    if current_skill == "":
        _process_skill()

func _process_skill():
    while true:
        if skill_queue.is_empty():
            current_skill = ""
            return
        current_skill = skill_queue.pop_front()
        match current_skill:
            "stage1_aim_dash": await _stage1_aim_dash()
            "stage2_jump_drop": await _stage2_jump_drop()
            "stage3_spit": await _stage3_spit()

func _push_stage2():
    if stage >= 2: push_skill("stage2_jump_drop")

func _push_stage3():
    if stage >= 3: push_skill("stage3_spit")
# endregion

# region 技能实现
func _stage1_aim_dash():
    print("aim dash attack!")
    
    await get_tree().create_timer(1.0).timeout
    var target_x = player.global_position.x
    var start_x = global_position.x
    var dx = max(abs(target_x - start_x), 1.0)
    await create_tween().tween_property(self, "global_position:x", target_x, dx / speed)
    await get_tree().create_timer(3.2).timeout
    push_skill("stage1_aim_dash")

func _stage2_jump_drop():
    print("jump drop attack")
     # 1. 切状态、关正常 AI、清速度
    jump_drop_active = true
    set_physics_process(true)     # 确保物理帧开着
    velocity        = Vector2.ZERO
    ground_y        = global_position.y

    # 2. 给一次向上的初速度
    velocity.y = JUMP_VELOCITY
    
    #_camera_shake()
    player.get_child(0)
    
    # 掉落 3 只小史莱姆（屏幕外出生）
    for i in 2:
        print("slime drop phase:")
        var slime = small_slime_scene.instantiate()
        print(slime.name)
        slime.global_position = Vector2(global_position.x + randi_range(-80, 80), -50)
        get_tree().current_scene.add_child(slime)

    await get_tree().create_timer(6.0).timeout
    push_skill("stage2_jump_drop")

func _stage3_spit():
    print("spit attack")
    var proj = projectile_scene.instantiate()
    proj.global_position = global_position + Vector2(0, -20)
    var to_target = player.global_position - proj.global_position
    var vx = to_target.x / 0.7
    var vy = -sqrt(2.0 * PARABOLA_GRAVITY * abs(to_target.y))
    proj.set_velocity(Vector2(vx, vy))
    get_tree().current_scene.add_child(proj)
    await get_tree().create_timer(6.0).timeout
    push_skill("stage3_spit")
# endregion

# region 辅助 & 死亡
#func _camera_shake():
    #var cam = get_tree().get_first_node_in_group("camera")
    #if cam:
        #cam.offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
        #await get_tree().create_timer(0.3).timeout
        #cam.offset = Vector2.ZERO

func take_damage(amount: int):
    if current_skill == "die": return
    
    print("boss hurt!")
    
    if hp >0:
        set_hp(hp - amount)
        start_invulnerability()
    elif hp <= 0:
        start_invulnerability()
        print("boss hurt dead")
        set_hp(hp - amount)
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

func _die():
    current_skill = "die"
    set_physics_process(false)
    # 清计时器
    for t in get_children():
        if t is Timer and t.name.begins_with("StageTimer"):
            t.queue_free()

    # 闪烁消失
    var tween = create_tween().set_loops(6)
    tween.tween_property(self, "modulate:a", 0.2, 0.1)
    tween.tween_property(self, "modulate:a", 1.0, 0.1)
    await tween.finished

    # 爆炸掉落 4 只小史莱姆（左右抛物线）
    var base_angle = deg_to_rad(45)   # 左右扇形
    for i in 4:
        var angle = base_angle * (i - 1.5)          # 左右对称
        var vx = cos(angle) * randf_range(200.0, 400.0)   # 随机水平速
        var vy = -sqrt(2.0 * 980 * 80)     # 固定向上初速（负值）
        
        print("爆炸角度=", rad_to_deg(angle), "  vx=", vx, "  vy=", vy)
        
        var slime = small_slime_scene.instantiate()
        slime.global_position = global_position
        slime.set_explosion_vel(Vector2(vx, vy))   # 需要 GreenSlime 提供此方法
        get_tree().current_scene.add_child(slime)
    
    # 发射信号
    emit_signal("boss_battle_finish")
    
    # 清场现存小史莱姆
    for s in get_tree().get_nodes_in_group("green_slime"):
        s.queue_free()
    queue_free()
# endregion

# ===== 运行时调血 =====
func _input(event):
    if not event.is_echo():
        match event.as_text():
            "1": set_hp(7)   # 阶段 1
            "2": set_hp(5)   # 阶段 2
            "3": set_hp(2)   # 阶段 3
            "0": set_hp(0)    # 立即死亡
