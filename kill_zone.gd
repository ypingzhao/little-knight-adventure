extends Area2D
    

func _on_body_entered(body: Node2D) -> void:
    print("You died!")
    #Engine.time_scale = 0.5
    body.get_node("CollisionShape2D").queue_free()
    #get_tree().reload_current_scene()
    call_deferred("deferred_change_scene")
    
func deferred_change_scene() -> void:
    get_tree().reload_current_scene()
