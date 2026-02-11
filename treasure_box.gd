extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _on_area_2d_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        print("open chest")
        animation_player.play("open_chest")
