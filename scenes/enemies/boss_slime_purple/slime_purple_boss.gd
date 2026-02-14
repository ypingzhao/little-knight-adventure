extends CharacterBody2D
class_name PurpleBoss

# region Export variables
@export var max_hp: int = 10
@export var speed: float = 300.0
@export var jump_height: int = 80
@export var small_slime_scene: PackedScene   #拖 green_slime.tscn
@export var projectile_scene: PackedScene    #拖抛物线弹丸（Area2D）
# endregion

# region Custom signals
signal hp_changed(new_hp: int)
signal invulnerability_ended()
signal boss_battle_finish()
# endregion

# region State variables
var hp: int = max_hp:
    set = set_hp
var stage: int = 1
var current_skill: String = ""
var skill_queue: Array[String] = []
var player: Node
var ground_y: float
var invulnerable: bool = false
var jump_drop_active: bool = false

const GRAVITY = 3000.0   #玩家重力大，看起来更沉重
const JUMP_VELOCITY = -400.0   #跳跃初速度（向上）
var jump_height_max = 120.0    #跳跃多高（像素）

# endregion

# region Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var hurt_sound: AudioStreamPlayer = $HurtSound
@onready var hit_box: Area2D = $HitBox
# endregion

# region Lifecycle
func _ready():
    player = get_tree().get_first_node_in_group("player")
    ground_y = global_position.y

    # 延迟一帧连接HUD，确保HUD已经ready并添加到组
    await get_tree().process_frame
    _connect_to_hud()

    # 开始攻击
    push_skill("stage1_aim_dash")

func _connect_to_hud():
    var hud = get_tree().get_first_node_in_group("hud")
    if not hud:
        print("Boss: HUD not found!")
        return

    # 显示血条
    if hud.has_method("show_boss_health_bar"):
        hud.show_boss_health_bar(max_hp)
        print("Boss: showed boss health bar, max_hp=", max_hp)
    else:
        print("Boss: HUD does not have show_boss_health_bar method")

    # 直接连接HP变化信号
    if hud.has_method("_on_boss_health_changed"):
        hp_changed.connect(hud._on_boss_health_changed)
        print("Boss: connected hp_changed signal to HUD")
    else:
        print("Boss: HUD does not have _on_boss_health_changed method")

# region Health & Stage
func set_hp(value: int):
    var old = hp
    hp = clampi(value, 0, max_hp)
    print("boss hp:" , hp)
    hp_changed.emit(hp)  # Emit signal for UI to update
    if hp <= 0:
        _die()
        return
    _check_stage_change(old)

func _physics_process(delta):
    #face player
    animated_sprite.flip_h = global_position.x > player.global_position.x

    if jump_drop_active:
        # ————— 跳跃阶段 —————
        if velocity.y < 0 and (ground_y - global_position.y) < jump_height_max:
            # 还在上升且没达最大高度 → 继续上升
            pass
        else:
            # 到达顶点或开始下落 → 交给重力
            velocity.y += GRAVITY * delta

        # ————— 地面检测 —————
        move_and_slide()
        if is_on_floor():
            jump_drop_active = false      # 切回正常 AI

            # 在屏幕外正上方生成一个史莱姆自由掉落
            if small_slime_scene:
                var camera = get_viewport().get_camera_2d()
                if camera:
                    var spawn_pos = camera.global_position + Vector2(0, -200)  # 相机上方200像素（屏幕外）
                    var slime = small_slime_scene.instantiate()
                    slime.global_position = spawn_pos
                    get_tree().current_scene.add_child(slime)
                    print("Boss landed: spawned slime above screen at ", slime.global_position)

            # 镜头震动（如果玩家有此方法）
            if player and player.has_method("camera_shake"):
                player.camera_shake()
            print("landed")
        return

    # ===== 下面是正常 AI 逻辑 =====
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
            t2.timeout.connect(_on_stage2_timer.bind(t2), CONNECT_ONE_SHOT)
            add_child(t2); t2.start()
        3:
            var t3 = Timer.new()
            t3.name = "StageTimer3"
            t3.wait_time = 8.0    # 每 8 秒抛物线
            t3.timeout.connect(_on_stage3_timer.bind(t3), CONNECT_ONE_SHOT)
            add_child(t3); t3.start()

func _on_stage2_timer(timer: Timer):
    push_skill("stage2_jump_drop")
    # 重新创建计时器循环
    var t2 = Timer.new()
    t2.name = "StageTimer2"
    t2.wait_time = 12.0
    t2.timeout.connect(_on_stage2_timer.bind(t2), CONNECT_ONE_SHOT)
    add_child(t2); t2.start()

func _on_stage3_timer(timer: Timer):
    push_skill("stage3_spit")
    # 重新创建计时器循环
    var t3 = Timer.new()
    t3.name = "StageTimer3"
    t3.wait_time = 8.0
    t3.timeout.connect(_on_stage3_timer.bind(t3), CONNECT_ONE_SHOT)
    add_child(t3); t3.start()

# region Skill queue
func push_skill(name: String):
    skill_queue.append(name)
    if current_skill == "":
        _process_skill()

func _process_skill():
    while true:
        # 如果已经死亡，停止处理技能
        if current_skill == "die":
            skill_queue.clear()
            return

        if skill_queue.is_empty():
            current_skill = ""
            return
        current_skill = skill_queue.pop_front()
        match current_skill:
            "stage1_aim_dash": await _stage1_aim_dash()
            "stage2_jump_drop": await _stage2_jump_drop()
            "stage3_spit": await _stage3_spit()

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

    # 1. 切状态、清速度
    jump_drop_active = true
    velocity = Vector2.ZERO

    ground_y = global_position.y

    # 2. 给一次向上的初速度
    velocity.y = JUMP_VELOCITY

    # 3. 给一点时间等待（模拟抛物线飞行）
    await get_tree().create_timer(6.0).timeout
    push_skill("stage3_spit")

func _stage3_spit():
    print("spit small slimes attack")
    # 向玩家方向抛射1个小史莱姆
    for i in range(1):
        var slime = small_slime_scene.instantiate()
        # 在boss前方不同位置生成，让它们稍微分散
        var offset_x = (i - 0.5) * 30  # -45, -15, 15, 45
        slime.global_position = global_position + Vector2(offset_x, -20)
        get_tree().current_scene.add_child(slime)

    await get_tree().create_timer(6.0).timeout
    push_skill("stage3_spit")

# endregion

# region Helper & Death
func take_damage(amount: int):
    if current_skill == "die": return
    if invulnerable: return  # 无敌状态不受伤

    print("boss hurt! amount=", amount, " current hp=", hp)

    # 立即扣血，让血条动画在击中时就触发
    set_hp(hp - amount)

    # 受击效果：播放音效、无敌、闪烁
    invulnerable = true
    hurt_sound.play()
    hit_box.set_deferred("monitoring", false)

    # 闪烁动画：快速闪烁2次表示受击
    var tween = create_tween().set_loops(2)
    tween.tween_property(animated_sprite, "modulate:a", 0.5, 0.05)
    tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.05)
    await tween.finished

    # 0.3秒后恢复
    await get_tree().create_timer(0.3).timeout
    invulnerable = false
    hit_box.set_deferred("monitoring", true)

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
    invulnerability_ended.emit()   # ←通知世界

func _die():
    current_skill = "die"
    skill_queue.clear()  # 清空技能队列

    # 记录本轮击杀数
    GlobalData.add_session_enemy_killed("boss")
    set_physics_process(false)     # 清计时器
    for t in get_children():
        if t is Timer and t.name.begins_with("StageTimer"):
            t.queue_free()

    # 闪烁消失
    var tween = create_tween().set_loops(6)
    tween.tween_property(animated_sprite, "modulate:a", 0.2, 0.1)
    tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.1)
    await tween.finished

    # 抛射小史莱姆 - 使用扇形角度计算
    print("spit small slimes on death")

    # 判断玩家在boss的左边还是右边
    var throw_direction = sign(player.global_position.x - global_position.x)  # -1 或 1
    var base_angle = deg_to_rad(45)  # 左右扇形角度

    # 向玩家方向抛射4个小史莱姆
    for i in range(3):
        var angle = base_angle * (i - 1.5)  # -67.5°, -22.5°, 22.5°, 67.5°
        var vx = cos(angle) * randf_range(200.0, 400.0) * throw_direction  # 乘方向符号
        var vy = -sqrt(2.0 * 980 * 80)  # 固定向上初速度（负值=向上）

        print("爆炸角度=", rad_to_deg(angle), "  vx=", vx, "  vy=", vy, "  方向=", throw_direction)

        var slime = small_slime_scene.instantiate()
        var offset_x = (i - 1.5) * 30  # -45, -15, 15, 45
        slime.global_position = global_position + Vector2(offset_x, -20)
        get_tree().current_scene.add_child(slime)

        # 等待一帧让史莱姆正确初始化（CharacterBody2D需要物理帧）
        await get_tree().process_frame

        slime.set_explosion_vel(Vector2(vx, vy))

        # 每个史莱姆之间间隔一点时间，不要同时生成
        await get_tree().create_timer(0.15).timeout

    # 发射信号通知场景脚本显示门
    boss_battle_finish.emit()

    # 最后移除boss对象
    queue_free()

# 这个函数不再需要，逻辑已经整合到_die()中
func spit_slimes_on_death():
    pass
