# SpikeTrap.gd  挂在根节点（Node2D）
extends Node2D
@export var up_time  : float = 0.8   # 伸出停留
@export var down_time: float = 1.2  # 缩回停留
@export var spike_damage:int = 1


@onready var spike: Area2D = $Area2D
@onready var shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var audio: AudioStreamPlayer = $Audio



func _ready() -> void:
    shape.disabled = false
    _start_cycle()

# 启动循环计时器
func _start_cycle() -> void:
    var timer := Timer.new()
    timer.timeout.connect(_on_cycle_tick)
    timer.wait_time = 0.25 + up_time + 0.25 + down_time
    timer.autostart = true
    add_child(timer)

func _on_cycle_tick() -> void:
    # 缩回
    create_tween().tween_property(spike, "position:y", 16, 0.25).set_trans(Tween.TRANS_SINE)
    await get_tree().create_timer(down_time).timeout
    shape.disabled = true
    
    # 升起
    audio.play()
    shape.disabled = false
    create_tween().tween_property(spike, "position:y", 0, 0.25).set_trans(Tween.TRANS_SINE)
    await get_tree().create_timer(up_time).timeout
