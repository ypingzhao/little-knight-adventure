extends AnimatableBody2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var area_2d: Area2D = $Area2D

func _ready() -> void:
    animation_player.stop()
    


func _on_area_2d_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        animation_player.play()
    
    pass # Replace with function body.
