# 宝箱脚本 - 支持三种稀有度配置
extends Node2D

# 宝箱稀有度枚举（与 TreasureItemManager 中定义保持一致）
enum ChestRarity {
    NORMAL,  # 普通宝箱 = 0
    RARE,   # 高级宝箱 = 1
    ROYAL    # 皇家宝箱 = 2
}

# 宝箱稀有度配置（在场景检查器中设置）
@export var chest_rarity: int = ChestRarity.NORMAL

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

# 是否已开启
var is_opened: bool = false
# 宝物节点引用
var treasure_node: Node2D = null
# 宝物生成位置
var spawn_pos: Vector2


func _ready() -> void:
    # 调试输出配置的稀有度
    print("Chest: 宝箱稀有度 = %s (0=NORMAL, 1=RARE, 2=ROYAL)" % chest_rarity)


## 玩家触碰宝箱时触发
func _on_area_2d_body_entered(body: Node2D) -> void:
    # 检查是否为玩家
    if not body.is_in_group("player"):
        return

    # 防止重复触发
    if is_opened:
        return

    is_opened = true

    # 1. 播放开箱动画
    animation_player.play("open_chest")

    # 2. 播放开箱音效
    if audio_stream_player:
        audio_stream_player.play()

    # 3. 生成宝物（使用 call_deferred 避免信号回调冲突）
    call_deferred("_spawn_and_add_treasure")


## 生成宝物并添加到场景（延迟调用）
func _spawn_and_add_treasure() -> void:
    # 宝物生成位置 = 宝箱位置
    spawn_pos = global_position

    # 根据稀有度获取宝物场景路径
    var treasure_path := ""
    match chest_rarity:
        ChestRarity.NORMAL:
            treasure_path = "res://scenes/items/coin.tscn"
        ChestRarity.RARE:
            treasure_path = "res://scenes/items/diamond.tscn"
        ChestRarity.ROYAL:
            treasure_path = "res://scenes/items/health_pot.tscn"
        _:
            push_error("Chest: 未知的宝箱稀有度: %s" % chest_rarity)
            return

    if treasure_path.is_empty():
        return

    # 加载场景并实例化
    var treasure_packed = load(treasure_path)
    if not treasure_packed:
        push_error("Chest: 无法加载场景: %s" % treasure_path)
        return

    treasure_node = treasure_packed.instantiate()
    if not treasure_node:
        push_error("Chest: 无法实例化宝物节点")
        return

    # 禁用宝箱碰撞体（避免重复触发）
    $Area2D.collision_layer = 0
    print("Chest: 宝箱碰撞体已禁用")

    # 添加宝物节点到场景
    get_parent().add_child(treasure_node)
    treasure_node.global_position = spawn_pos
    print("Chest: 宝物节点已添加到场景, 位置 = %s" % spawn_pos)

    # 添加上浮动画
    _float_treasure(treasure_node)


## 宝物上浮动画
func _float_treasure(treasure: Node2D) -> void:
    var tween = treasure.create_tween()
    if not tween:
        push_error("Chest: 无法创建 Tween")
        return

    # 向上浮动8像素
    var target_y := treasure.global_position.y - 8
    tween.tween_property(treasure, "global_position:y", target_y, 0.3)

    # 添加轻微缓动效果
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_SINE)

    print("Chest: 宝物上浮动画开始，目标 Y = %s" % target_y)


## 输出宝物类型名称
func _get_treasure_type_name() -> String:
    match chest_rarity:
        ChestRarity.NORMAL:
            return "金币"
        ChestRarity.RARE:
            return "钻石"
        ChestRarity.ROYAL:
            return "血瓶"
        _:
            return "未知"
