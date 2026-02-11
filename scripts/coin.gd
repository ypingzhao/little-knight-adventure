extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _on_body_entered(body: Node2D) -> void:
    
    if body.is_in_group("player"):
        animation_player.play("pick_up")
        GlobalData.add_point()
        print("coin +1")
    
