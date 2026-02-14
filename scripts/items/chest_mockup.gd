# 宝箱脚本 Mockup - 供确认设计
extends Node2D

# 宝箱稀有度配置（会在对应的 .tscn 文件中设置）
# @export var chest_rarity: int = TreasureItemManager.ChestRarity.NORMAL

# 引用 TreasureItemManager enum
const ChestRarity = preload("res://scripts/autoload/treasure_item_manager.gd").ChestRarity

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var area_2d: Area2D = $Area2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

# 是否已开启
var is_opened: bool = false


func _ready() -> void:
	# 连接信号
	area_2d.body_entered.connect(_on_area_2d_body_entered)


## 玩家触碰宝箱时触发
func _on_area_2d_body_entered(body: Node2D) -> void:
	# 检查是否为玩家
	if not body.is_in_group("player"):
		return

	# 防止重复触发
	if is_opened:
		return

	is_opened = true

	# 获取宝箱稀有度（从场景配置中读取）
	var rarity: int = get_meta("chest_rarity", ChestRarity.NORMAL)
	print("Chest: 宝箱稀有度 = %s" % rarity)

	# 1. 播放开箱动画
	_open_chest_animation()

	# 2. 生成宝物（向上浮动8像素）
	_spawn_treasure(rarity)

	# 3. 播放开箱音效
	if audio_stream_player:
		audio_stream_player.play()

	# 4. 禁用宝箱碰撞体（避免重复触发）
	area_2d.collision_layer = 0


## 播放开箱动画
func _open_chest_animation() -> void:
	# TODO: 播放开箱动画（如盖子打开）
	# 当前 mockup 仅更改 sprite
	if sprite_2d:
		sprite_2d.region_enabled = true  # 如果需要切换图片
		# sprite_2d.texture = other_texture  # 切换到打开状态的贴图


## 生成宝物并执行上浮动画
func _spawn_treasure(rarity: int) -> void:
	# 宝物生成位置 = 宝箱位置
	var spawn_pos := global_position

	# 调用 TreasureItemManager 生成宝物
	var treasure_node = TreasureItemManager.spawn_treasure(rarity, spawn_pos, get_parent())
	if not treasure_node:
		push_error("Chest: 宝物生成失败")
		return

	# 执行上浮动画（向上8像素）
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

	# 可选：添加轻微缓动效果
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)

	print("Chest: 宝物上浮动画开始，目标 Y = %s" % target_y)
