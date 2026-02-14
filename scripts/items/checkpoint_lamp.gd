extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var lamp_position: Vector2
var active: bool = false
var original_y: float
var float_range: float
var tween: Tween

#初始时候，将checkpointlamb的sprite变成灰色，表示没有激活
func _ready() -> void:
    # 将sprite设置为灰色，半透明
    animated_sprite.modulate = Color(0.5, 0.5, 0.5, 0.6)
    

# 检测到player后执行：
func _on_area_2d_body_entered(body: Node2D) -> void:
    if body.is_in_group("player") and not active:
        print("lamp activated")
        animated_sprite.play("default")
        audio_stream_player.play()
        #将sprite的灰色去掉，恢复原有颜色并提高亮度
        animated_sprite.modulate = Color(1.3, 1.3, 1.3, 1.0)

        # 记录原始位置并生成随机浮动范围
        lamp_position = global_position
        original_y = global_position.y
        float_range = randf_range(2.0, 5.0)

        # 播放tween动画，垂直向上浮起16像素，然后上下缓慢浮动
        _play_activation_animation()

        # 记录玩家重生坐标
        save_player_pos()


# 播放激活动画
func _play_activation_animation() -> void:
    tween = create_tween()
    tween.set_parallel(false)

    # 第一阶段：向上浮起16像素
    tween.tween_property(self, "global_position:y", original_y - 16, 0.5)

    # 第二阶段：上下缓慢浮动（循环）
    _start_float_animation()


# 开始上下浮动动画
func _start_float_animation() -> void:
    var float_tween = create_tween()
    float_tween.set_loops().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
    

    # 向上浮动
    float_tween.tween_property(self, "global_position:y", original_y - 16 - float_range, 1.0)
    float_tween.tween_property(self, "global_position:y", original_y - 16, 1.0)


# 记录player重生坐标方法
func save_player_pos() -> void:
    active = true
    print("Checkpoint saved at: ", lamp_position)


# 将玩家重生在lamp_position x+8的水平位置，y在地面位置
func revive_player(player_node: Node2D) -> void:
    if active and player_node:
        # 将玩家设置到checkpoint位置（x偏移8像素，y在lamp上方）
        # Godot中Y轴向下为正，所以应该用负值让玩家在lamp上方
        player_node.global_position = Vector2(lamp_position.x + 8, lamp_position.y - 20)

        # 如果是CharacterBody2D，重置速度
        if player_node is CharacterBody2D:
            player_node.velocity = Vector2.ZERO

        print("Player revived at checkpoint: ", player_node.global_position)
