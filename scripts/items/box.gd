extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer



func _on_area_2d_body_entered(body: Node2D) -> void:
    
    if body.is_in_group("player"):
        animation_player.play("shakefall")
    
    pass # Replace with function body.
