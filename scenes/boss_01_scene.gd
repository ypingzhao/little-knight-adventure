extends Node2D

@onready var door: Node2D = $Door
@onready var door_show_sound: AudioStreamPlayer = $DoorShowSound

func _ready():
    # 找到boss节点并连接信号
    var boss = get_node_or_null("SlimePurple")
    if boss and boss.has_signal("boss_battle_finish"):
        boss.boss_battle_finish.connect(_on_boss_battle_finish)
        print("Boss01Scene: connected to boss death signal")

    # 隐藏门
    door.hide_door()

func _on_boss_battle_finish():
    # 显示门并播放音效
    await get_tree().create_timer(3.0).timeout
    if door_show_sound:
        door_show_sound.play()
    if door:
        door.show_door()
