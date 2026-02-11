extends Node2D

@export var jump_height_mult: float = 0.5
@export var run_speed_mult: float = 0.1


var player: CharacterBody2D = null

func _ready() -> void:
    $Area2D.body_entered.connect(_on_body_entered)
    $Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        print("enter waterfall!")
        player = body
        player.velocity.y = 200
        player.jump_velocity *= jump_height_mult
        player.SPEED *= run_speed_mult

func _on_body_exited(body: Node2D) -> void:
    if body == player:
        player.jump_velocity /= jump_height_mult
        player.SPEED /= run_speed_mult
        player = null
