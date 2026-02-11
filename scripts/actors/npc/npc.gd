extends CharacterBody2D

@onready var detect: Area2D = $Area2D
@onready var bubble: Node2D = $ChatBubble

func _ready():
    detect.body_entered.connect(_on_player_entered)
    detect.body_exited.connect(_on_player_exited)

func _on_player_entered(body):
    if body.is_in_group("player"):
        bubble.show_bubble()

func _on_player_exited(body):
    if body.is_in_group("player"):
        bubble.hide_bubble()
