extends CanvasLayer

# 商店UI主脚本
# 支持显示最多3个商品（1排3列）

@onready var ui_control: Control = $ShopUIControl
@onready var title_label: Label = $ShopUIControl/PanelContainer/VBoxContainer/TitleLabel
@onready var close_button: Button = $ShopUIControl/PanelContainer/CloseButton
@onready var items_container: GridContainer = $ShopUIControl/PanelContainer/VBoxContainer/ItemsGrid
@onready var coins_label: Label = $ShopUIControl/PanelContainer/VBoxContainer/CoinsLabel
@onready var notification_label: Label = $ShopUIControl/NotificationLabel

var current_items: Array = []
const ITEMS_PER_ROW = 3
const MAX_ITEMS = 3

# 兼容属性：is_shop_visible (避免与CanvasLayer的visible冲突)
var is_shop_visible: bool:
    get:
        return _is_ui_visible()
    set(value):
        if value:
            _open_shop()
        else:
            _close_shop()

func _ready() -> void:
    # 初始隐藏
    if ui_control:
        ui_control.visible = false

    # 连接关闭按钮
    if close_button:
        close_button.pressed.connect(_on_close_pressed)

    # 连接退出键
    set_process_input(true)

    # 隐藏通知
    if notification_label:
        notification_label.visible = false
        notification_label.modulate = Color.TRANSPARENT

func _input(event: InputEvent) -> void:
    # 使用自定义的可见性检查
    if _is_ui_visible() and event.is_action_pressed("ui_cancel"):
        _on_close_pressed()

# 刷新商品列表
func refresh_items() -> void:
    # 清空现有商品
    _clear_items()

    # 获取随机商品（最多6个）
    current_items = TradeItemList.get_random_items(MAX_ITEMS)

    # 创建商品UI
    for item_data in current_items:
        _create_item_ui(item_data)

    # 更新金币显示
    _update_coins_display()

    print("商店已刷新，显示商品数: %d" % current_items.size())

# 清空商品容器
func _clear_items() -> void:
    if items_container:
        for child in items_container.get_children():
            child.queue_free()

# 创建单个商品的UI
func _create_item_ui(item_data) -> void:
    if not items_container:
        return

    # 创建商品面板（减小高度以适应屏幕）
    var item_panel = Panel.new()
    item_panel.custom_minimum_size = Vector2(135, 140)

    var panel_vbox = VBoxContainer.new()
    item_panel.add_child(panel_vbox)
    panel_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel_vbox.add_theme_constant_override("separation", 3)

    # 商品图标（缩小尺寸）
    if item_data.icon_path != "" and ResourceLoader.exists(item_data.icon_path):
        var icon = TextureRect.new()
        icon.custom_minimum_size = Vector2(50, 50)
        icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        var texture = load(item_data.icon_path)
        if texture:
            icon.texture = texture
        panel_vbox.add_child(icon)
    else:
        # 使用 emoji 作为占位符（缩小尺寸）
        var placeholder = Label.new()
        placeholder.text = "📦"
        placeholder.add_theme_font_size_override("font_size", 32)
        placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        placeholder.custom_minimum_size = Vector2(50, 50)
        panel_vbox.add_child(placeholder)

    # 商品名称（缩小字体）
    var name_label = Label.new()
    name_label.text = item_data.name
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_label.add_theme_font_size_override("font_size", 11)
    panel_vbox.add_child(name_label)

    # 价格标签（缩小字体）
    var price_label = Label.new()
    price_label.text = "💰 %d" % item_data.price
    price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    price_label.add_theme_font_size_override("font_size", 10)
    price_label.add_theme_color_override("font_color", Color.GOLD)
    panel_vbox.add_child(price_label)

    # 描述标签（减小高度和字体）
    var desc_label = Label.new()
    desc_label.text = item_data.description
    desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc_label.custom_minimum_size = Vector2(125, 25)
    desc_label.add_theme_font_size_override("font_size", 8)
    desc_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
    panel_vbox.add_child(desc_label)

    # 购买按钮（减小尺寸）
    var buy_button = Button.new()
    if item_data.owned:
        buy_button.text = "已拥有"
        buy_button.disabled = true
        buy_button.modulate = Color.GRAY
    else:
        buy_button.text = "购买"

    buy_button.custom_minimum_size = Vector2(90, 24)
    buy_button.add_theme_font_size_override("font_size", 10)
    # Button 文本默认居中，不需要额外设置
    buy_button.pressed.connect(_on_buy_button_pressed.bind(item_data))
    panel_vbox.add_child(buy_button)

    # 添加到容器
    items_container.add_child(item_panel)

# 购买按钮按下
func _on_buy_button_pressed(item_data) -> void:
    print("尝试购买: %s, 价格: %d" % [item_data.name, item_data.price])

    # 调用购买逻辑
    var success = TradeItemList.purchase_item(item_data.id, GlobalData.player_coin)

    if success:
        # 扣除金币
        GlobalData.player_coin -= item_data.price
        SaveLoad.save_game()

        # 显示成功通知
        _show_notification("成功购买 %s！" % item_data.name, Color.GREEN)

        # 刷新UI
        refresh_items()

        # 应用道具效果（如果有）
        _apply_item_effect(item_data)
    else:
        # 检查失败原因
        if GlobalData.player_coin < item_data.price:
            _show_notification("金币不足！需要 %d，当前 %d" % [item_data.price, GlobalData.player_coin], Color.RED)
        elif item_data.owned:
            _show_notification("你已经拥有这个商品", Color.YELLOW)
        else:
            _show_notification("购买失败", Color.RED)

# 应用道具效果
func _apply_item_effect(item_data) -> void:
    match item_data.effect_type:
        "HEALTH_POTION":
            # 生命药水：恢复50点生命
            if PlayerHealth.health < PlayerHealth.max_health:
                PlayerHealth.heal(50)
                _show_notification("恢复了50点生命值！", Color.LIGHT_GREEN)
            else:
                _show_notification("生命值已满", Color.CYAN)
        "MANA_POTION":
            # 魔法药水（暂时只显示提示）
            _show_notification("恢复了40点魔法值！", Color.LIGHT_BLUE)
        "SPEED_BOOST":
            _show_notification("移动速度提升20%，持续10秒！", Color.ORANGE)
        "SHIELD":
            _show_notification("获得临时护盾！", Color.CYAN)
        "DOUBLE_COIN":
            _show_notification("双倍金币效果，持续5分钟！", Color.GOLD)
        "JUMP_BOOST":
            _show_notification("跳跃高度提升30%！", Color.LIGHT_GREEN)
        "ATTACK_BOOST":
            _show_notification("攻击力提升50%，持续30秒！", Color.RED)
        "DEFENSE_BOOST":
            _show_notification("防御力提升30%，持续30秒！", Color.BLUE)
        "XP_BOOST":
            _show_notification("双倍经验值效果，持续10分钟！", Color.MAGENTA)
        "INVISIBILITY":
            _show_notification("隐身5秒，敌人无法发现！", Color.PURPLE)
        _:
            _show_notification("获得: %s" % item_data.name, Color.WHITE)

# 显示通知消息
func _show_notification(message: String, color: Color = Color.WHITE) -> void:
    if not notification_label:
        return

    notification_label.text = message
    notification_label.add_theme_color_override("font_color", color)
    notification_label.visible = true

    # 淡入动画
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(notification_label, "modulate", color, 0.3)
    tween.tween_property(notification_label, "modulate:a", 1.0, 0.3)

    # 等待2.5秒后淡出
    await get_tree().create_timer(2.5).timeout

    # 淡出动画
    var fade_out = create_tween()
    fade_out.set_parallel(true)
    fade_out.tween_property(notification_label, "modulate:a", 0.0, 0.5)
    fade_out.tween_property(notification_label, "visible", false, 0.5)

# 更新金币显示
func _update_coins_display() -> void:
    if coins_label:
        coins_label.text = "当前金币: 💰 %d" % GlobalData.player_coin

# 显示商店UI (自定义方法，避免与CanvasLayer.show()冲突)
func _open_shop() -> void:
    if ui_control:
        ui_control.visible = true

    # 禁用玩家控制
    _disable_player_control()
    print("商店UI已显示，玩家控制已禁用")

# 隐藏商店UI (自定义方法，避免与CanvasLayer.hide()冲突)
func _close_shop() -> void:
    if ui_control:
        ui_control.visible = false

    # 恢复玩家控制
    _enable_player_control()

# 禁用玩家控制
func _disable_player_control() -> void:
    # 方法1：通过组查找
    var players = get_tree().get_nodes_in_group("player")
    for player in players:
        if player.has_method("set_process_input"):
            player.set_process_input(false)
            player.set_physics_process(false)
            print("已禁用玩家控制 (通过组)")

    # 方法2：通过场景树查找knight节点
    if players.is_empty():
        var current_scene = get_tree().current_scene
        if current_scene:
            var knight = current_scene.find_child("knight", true, false)
            if knight:
                knight.set_process_input(false)
                knight.set_physics_process(false)
                print("已禁用玩家控制 (通过名称)")

# 恢复玩家控制
func _enable_player_control() -> void:
    # 方法1：通过组查找
    var players = get_tree().get_nodes_in_group("player")
    for player in players:
        if player.has_method("set_process_input"):
            player.set_process_input(true)
            player.set_physics_process(true)
            print("已恢复玩家控制 (通过组)")

    # 方法2：通过场景树查找knight节点
    if players.is_empty():
        var current_scene = get_tree().current_scene
        if current_scene:
            var knight = current_scene.find_child("knight", true, false)
            if knight:
                knight.set_process_input(true)
                knight.set_physics_process(true)
                print("已恢复玩家控制 (通过名称)")

# 检查UI是否可见
func _is_ui_visible() -> bool:
    if ui_control:
        return ui_control.visible
    return false

# 关闭按钮
func _on_close_pressed() -> void:
    _close_shop()
    Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
    print("商店已关闭")
