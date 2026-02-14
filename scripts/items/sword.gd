extends Area2D
@export var fly_distance: int = 64          # 向前飞出像素
@export var return_accel: float = 800  
@export var max_return_speed: int = 600
#@onready var col: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite
@onready var hit_box: Area2D = $HitBox

const CLOSE_ENOUGH: float = 8.0        # 直接回收阈值
const LINEAR_RETURN_DIST: float = 48.0 # 线性拉回阈值
const LINEAR_SPEED: float = 300.0      # 线性拉回速度

var player: CharacterBody2D                 # 扔剑者
var direction: int = 1                      # 1 右 -1 左
var state: int = 0                          # 0飞出 1悬停 2返回
var velocity: Vector2 = Vector2.ZERO        # 当前速度
var start_pos: Vector2                      # 飞出起点
var target_x: float        
#var sword_dir:int                 # 飞出终点 X

func _ready() -> void:
    hit_box.area_entered.connect(_on_hit)
    pass

func init(p: CharacterBody2D, dir: int):
    player = p
    direction = dir
    #sprite.flip_h = dir <0
    start_pos = global_position
    target_x = start_pos.x + fly_distance * direction
    state = 0
    # 开始旋转
    #sprite.rotation_degrees = 0
    set_physics_process(true)

func _physics_process(delta):
    match state:
        0: # 飞出阶段
            sprite.flip_h = direction <0
            var new_x = move_toward(global_position.x, target_x, 400 * delta)
            global_position.x = new_x
            if abs(global_position.x - target_x) < 1:
                state = 1
                await get_tree().create_timer(0.2).timeout
                state = 2

        2: # 返回阶段（追踪实时玩家位置）
            var to_player = player.global_position - global_position
            var dist = to_player.length()

            if dist < CLOSE_ENOUGH:
                queue_free()                 # 瞬收
                return

            if dist < LINEAR_RETURN_DIST:
                # 小范围：匀速直线拉回（不再累加速度）
                var step = to_player.normalized() * LINEAR_SPEED * delta
                global_position += step
            else:
                # 远距离：匀加速追
                velocity += to_player.normalized() * return_accel * delta
                velocity = velocity.limit_length(max_return_speed)
                global_position += velocity * delta

    # 持续旋转
    sprite.rotation_degrees += 360 * delta * direction

func _on_hit(area:Area2D)->void:
    var parent = area.get_parent()
    # 检查父节点是否存在并且有 take_damage 方法
    if parent and parent.has_method("take_damage"):
        # 让敌人受伤（使用玩家的总攻击力）
        var damage = GlobalData.get_total_attack()
        parent.take_damage(damage)
        # 一把剑只触发一次（可选）
        hit_box.set_deferred("monitoring", false)
