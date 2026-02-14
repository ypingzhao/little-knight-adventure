extends Area2D

var is_processing: bool = false
var cooldown_timer: Timer

# 当玩家进入kill zone时触发
func _on_body_entered(body: Node2D) -> void:
    if not body.is_in_group("player"):
        return

    # 防止重复触发
    if is_processing:
        return

    is_processing = true
    print("Player entered kill zone")

    # 尝试找到激活的checkpoint
    var checkpoint = _find_active_checkpoint()

    if checkpoint:
        # 使用checkpoint重生玩家
        checkpoint.revive_player(body)
        # 设置冷却时间，防止立即再次触发
        _start_cooldown()
    else:
        # 如果没有激活的checkpoint，重新加载场景
        print("No active checkpoint, reloading scene...")
        call_deferred("deferred_change_scene")


# 启动冷却计时器
func _start_cooldown() -> void:
    if not cooldown_timer:
        cooldown_timer = Timer.new()
        cooldown_timer.wait_time = 1.0  # 1秒冷却时间
        cooldown_timer.one_shot = true
        cooldown_timer.timeout.connect(_on_cooldown_finished)
        add_child(cooldown_timer)

    cooldown_timer.start()


# 冷却结束，允许再次触发
func _on_cooldown_finished() -> void:
    is_processing = false
    print("Kill zone cooldown finished")


# 延迟重新加载场景
func deferred_change_scene() -> void:
    get_tree().reload_current_scene()


# 在当前场景中寻找激活的checkpoint lamp
func _find_active_checkpoint() -> Node:
    # 获取当前场景树中的所有checkpoint lamp节点
    var checkpoints = get_tree().get_nodes_in_group("checkpoint")
    print("Found ", checkpoints.size(), " checkpoint(s)")

    # 遍历找到激活的checkpoint
    for checkpoint in checkpoints:
        print("Checking checkpoint, active = ", checkpoint.active)
        if checkpoint.active:
            return checkpoint

    return null
