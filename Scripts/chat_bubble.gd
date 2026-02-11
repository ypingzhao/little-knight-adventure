extends Node2D

@export var text : String =""
@onready var panel: PanelContainer = $PanelContainer
@onready var label: Label = $PanelContainer/Label


func _ready():
    label.text = text
    #show_bubble()
    hide()                    # 初始隐藏

func show_bubble() -> void:
    show()
    panel.modulate.a = 0.0          # 确保从透明开始
    create_tween().tween_property(panel, "modulate:a", 1.0, 0.15)

func hide_bubble() -> void:
    var tween = create_tween()
    tween.tween_property(panel, "modulate:a", 0.0, 0.15)
    tween.finished.connect(_on_hide_finished, CONNECT_ONE_SHOT)

func _on_hide_finished() -> void:
    hide()
    panel.modulate.a = 1.0          # 恢复初始值，方便下次淡入
