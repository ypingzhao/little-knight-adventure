extends CharacterBody2D

# 信号：玩家进入/离开商店区域
signal player_entered_shop()
signal player_exited_shop()

# 交互提示UI
@onready var interaction_prompt: Label = _create_interaction_prompt()
var player_in_range: bool = false

func _ready() -> void:
    # 创建并添加交互提示
    add_child(interaction_prompt)
    interaction_prompt.visible = false

    # 连接Area2D信号
    var area = $Area2D
    if area:
        area.body_entered.connect(_on_body_entered)
        area.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
    # 检测玩家按键 (E键)
    if player_in_range and Input.is_action_just_pressed("interact"):
        print("E键被按下，尝试打开商店")
        _toggle_shop()

# 创建交互提示标签
func _create_interaction_prompt() -> Label:
    var label = Label.new()
    label.text = "按 E 键打开商店"
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

    # 设置样式
    var style = LabelSettings.new()
    style.font_size = 12
    style.font_color = Color.WHITE
    style.shadow_size = 3
    style.shadow_color = Color(0, 0, 0, 0.8)
    label.label_settings = style

    # 定位在角色上方
    label.position = Vector2(-40, -80)
    label.z_index = 100

    return label

# 玩家进入检测区域
func _on_body_entered(body: Node2D) -> void:
    print("检测到物体进入Area2D: ", body.name, " 类型: ", body.get_class())
    print("是否在player组: ", body.is_in_group("player"))
    print("名称是否以knight开头: ", body.name.begins_with("knight"))

    # 检查是否是玩家（CharacterBody2D类型或特定名称）
    if body.is_in_group("player") or body.name.begins_with("knight") or body is CharacterBody2D:
        player_in_range = true
        interaction_prompt.visible = true
        player_entered_shop.emit()
        print("✅ 玩家进入商店区域，现在可以按E键交互")

# 玩家离开检测区域
func _on_body_exited(body: Node2D) -> void:
    print("物体离开Area2D: ", body.name)

    if body.is_in_group("player") or body.name.begins_with("knight") or body is CharacterBody2D:
        player_in_range = false
        interaction_prompt.visible = false
        player_exited_shop.emit()
        print("❌ 玩家离开商店区域")

# 打开/关闭商店UI
func _toggle_shop() -> void:
    var shop_ui = get_node_or_null("/root/ShopUI")
    if shop_ui:
        # 使用is_shop_visible属性来检查
        if shop_ui.is_shop_visible:
            shop_ui._close_shop()
            Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
        else:
            shop_ui._open_shop()
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
            # 刷新商品列表
            if shop_ui.has_method("refresh_items"):
                shop_ui.refresh_items()
