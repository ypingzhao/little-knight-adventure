extends Node2D
@export var bat_scene: PackedScene
@export var spawn_interval := 1.2
@export var max_bats := 10                # 新增：上限

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var camera: Camera2D = get_viewport().get_camera_2d()
@onready var timer: Timer

var _spawned := 0                         # 已生成数量

func _ready() -> void:
    timer = Timer.new()
    timer.wait_time = spawn_interval
    timer.timeout.connect(_on_timer)
    add_child(timer)
    timer.start()

func _on_timer() -> void:
    if _spawned >= max_bats:              # 到上限就关 Timer
        timer.stop()
        timer.queue_free()
        return

    if not is_instance_valid(player):
        return

    # 下面与之前完全相同
    var vp_size := get_viewport_rect().size
    var half_w := vp_size.x * 0.5 / camera.zoom.x
    var margin := 128.0
    var spawn_pos := Vector2(
        player.global_position.x + half_w + margin,
        player.global_position.y
    )

    var bat := bat_scene.instantiate()
    bat.global_position = spawn_pos
    get_parent().add_child(bat)

    _spawned += 1
