extends Node2D        # 任意节点都行

@onready var tween_A: Tween
@onready var tween_B: Tween
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
    play_A()

# ---------- 动画 A ----------
func play_A() -> void:
    animated_sprite.flip_h = true
    tween_A = create_tween()
    tween_A.tween_property(self, "position:x", 500.0, 8.0).set_trans(Tween.TRANS_QUAD)
    # 任何别的属性都可以，这里只是水平移动 200 像素，耗时 1 秒
    tween_A.finished.connect(play_B)   # A 放完自动进 B

# ---------- 动画 B ----------
func play_B() -> void:
    animated_sprite.flip_h = false
    tween_B = create_tween()
    tween_B.tween_property(self, "position:x", 0.0, 8.0).set_trans(Tween.TRANS_QUAD)
    tween_B.finished.connect(play_A)   # B 放完自动回 A
