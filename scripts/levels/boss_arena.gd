extends Node2D

@onready var door: Node2D = $Door
@onready var boss: RedSlimeBoss = $SlimePurple as RedSlimeBoss
@onready var door_show_sound: AudioStreamPlayer = $DoorShowSound

func _ready():
    # 假设 boss 是场景中的 Boss 节点
    boss.connect("boss_battle_finish",_on_boss_battle_finish)
    door.hide_door()



func _on_boss_battle_finish():
    # 显示门
    await get_tree().create_timer(6.0).timeout
    door_show_sound.play()
    door.show_door()
