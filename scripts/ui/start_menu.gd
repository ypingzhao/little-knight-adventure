extends Node2D

func _ready() -> void:
    PlayerHealth.health = PlayerHealth.max_health

func _on_button_play_pressed() -> void:
    
    LevelManager.goto_next_room("easy")
    
    pass # Replace with function body.
