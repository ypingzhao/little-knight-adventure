extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var area_2d: Area2D = $Area2D

var audio_finished_connected: bool = false


func _on_area_2d_body_entered(body: Node2D) -> void:

    if body.is_in_group("player"):
        # 1. 先隐藏钻石 sprite
        animated_sprite_2d.visible = false

        # 2. 让 area2d 失效（避免重复触发）- 设置 collision_layer
        area_2d.collision_layer = 0

        # 3. 在GlobalData中增加diamond数量
        GlobalData.player_diamond += 1

        # 4. 记录本轮diamond数量
        GlobalData.add_session_diamond()

        # 5. 保存游戏数据
        SaveLoad.save_game()

        # 6. 播放收集动画效果
        _play_collect_animation()

        # 7. 播放音效，等音效播放完成后再删除节点（只连接一次）
        if not audio_finished_connected:
            audio_stream_player.finished.connect(_on_audio_finished)
            audio_finished_connected = true
        audio_stream_player.play()


func _on_audio_finished() -> void:
    # 音效播放完成，删除钻石节点
    queue_free()


## 播放收集动画（放大并渐隐）
func _play_collect_animation() -> void:
    var tween = create_tween()
    tween.set_parallel()

    # 放大效果
    tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
    # 渐隐效果
    tween.tween_property(animated_sprite_2d, "modulate:a", 0.0, 0.2)
