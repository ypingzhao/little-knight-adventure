extends Node2D

func _ready() -> void:
    PlayerHealth.health = PlayerHealth.max_health

func _on_button_play_pressed() -> void:

    LevelManager.goto_next_room("easy")

    pass # Replace with function body.

func _on_button_upgrade_pressed() -> void:
    # TODO: Implement upgrade menu or functionality
    print("UPGRADE button pressed - functionality to be implemented")
    pass
