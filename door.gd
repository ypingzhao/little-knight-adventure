extends Node2D
class_name Door

### 在编辑器里直接填关卡路径
#@export_file("*.tscn") var target_level: String
### 可选：给每个门起个名字，方便调试
#@export var door_name: String = "Door"
@onready var area_2d: Area2D = $Area2D

@export_enum("easy", "normal", "hard", "boss", "bonus", "win", "start") var difficulty := "easy"

#const DUNGEON = preload("uid://ctph7o0jcutqv")
#var dungeon_uid:String = "uid://ctph7o0jcutqv"
#
#const SHOP = preload("uid://b0bw7o7yjf3mf")
#var shop_uid = "uid://b0bw7o7yjf3mf"

func _ready() -> void:
    area_2d.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player") and GlobalData.player_coin >= 0:
        print("ready to change scene!")
        SaveLoad.save_game()
        
        #get_tree().change_scene_to_file(shop_uid)
        call_deferred("deferred_change_scene")
    #
func deferred_change_scene() -> void:
    LevelManager.goto_next_room(difficulty)

func hide_door():
    area_2d.monitorable = false
    area_2d.monitoring = false
    hide()

func show_door():
    area_2d.monitorable = true
    area_2d.monitoring = true
    show()
