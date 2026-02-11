extends Node2D

@export var heal_amount := 1
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var pot_area: Area2D = $PotArea


func _ready():
    # 只监听玩家碰撞
    #pot_area.area_entered.connect(_on_pot_area_area_entered)
    pass

func _play_effects() -> void:
    # sprite invisible
    sprite_2d.set_deferred("visible",false)
    # 音效
    audio.play()
    await audio.finished
    
    #sprite_2d.visible = false

func _on_pot_area_area_entered(area: Area2D) -> void:
    if area.get_parent().is_in_group("player"):
        # 1. 立即给玩家回血
        PlayerHealth.take_damage(-heal_amount)   # 负值=加血

        # 2. 禁用碰撞，防止重复触发
        set_deferred("monitoring", false)

        # 3. 依次等待执行
        await _play_effects()
        queue_free()          # 全部结束后自删除
        pass # Replace with function body.
