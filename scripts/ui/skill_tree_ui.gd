extends CanvasLayer

## ============================================================================
## 技能树 UI 管理器
## ============================================================================
## 功能：显示和交互技能树界面
## 注意：继承自 CanvasLayer，避免重定义 visible 属性和 show()/hide() 方法
## ============================================================================


## ============================================================================
## 信号定义
## ============================================================================

signal skill_tree_opened
signal skill_tree_closed


## ============================================================================
## 节点引用
## ============================================================================

@onready var ui_control: Control = $SkillTreeControl
@onready var title_label: Label = $SkillTreeControl/PanelContainer/VBoxContainer/TitleBar/HBoxContainer/TitleLabel
@onready var coin_label: Label = $SkillTreeControl/PanelContainer/VBoxContainer/TitleBar/HBoxContainer/CoinLabel
@onready var close_button: Button = $SkillTreeControl/PanelContainer/CloseButton
@onready var notification_label: Label = $SkillTreeControl/PanelContainer/VBoxContainer/NotificationLabel
@onready var scroll_container: ScrollContainer = $SkillTreeControl/PanelContainer/VBoxContainer/ScrollContainer
@onready var skills_container: VBoxContainer = $SkillTreeControl/PanelContainer/VBoxContainer/ScrollContainer/SkillsVBox


## ============================================================================
## 配置常量
## ============================================================================

const NOTIFICATION_DURATION := 2.0  # 通知显示时长（秒）


## ============================================================================
## 状态变量
## ============================================================================

var is_skill_tree_visible: bool:
	get:
		return _is_ui_visible()
	set(value):
		if value:
			_open_skill_tree()
		else:
			_close_skill_tree()

var _notification_tween: Tween = null


## ============================================================================
## 初始化
## ============================================================================

func _ready() -> void:
	# 初始隐藏 UI
	if ui_control:
		ui_control.visible = false

	# 连接关闭按钮
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

	# 连接技能树管理器信号
	SkillTreeManager.skill_upgraded.connect(_on_skill_upgraded)
	SkillTreeManager.upgrade_failed.connect(_on_upgrade_failed)

	# 连接 ESC 键
	_setup_escape_key()


## 配置 ESC 键关闭
func _setup_escape_key() -> void:
	# ESC 键会通过 _input() 处理
	pass


## ============================================================================
## UI 显示/隐藏（避免重定义 CanvasLayer 原生方法）
## ============================================================================

## 检查 UI 是否可见
func _is_ui_visible() -> bool:
	return ui_control != null and ui_control.visible


## 打开技能树
func _open_skill_tree() -> void:
	if ui_control:
		ui_control.visible = true

	# 更新金币显示
	_update_coin_display()

	# 刷新技能列表
	_populate_skill_list()

	# 禁用玩家控制
	_disable_player_control()

	emit_signal("skill_tree_opened")
	print("📖 技能树已打开")


## 关闭技能树
func _close_skill_tree() -> void:
	if ui_control:
		ui_control.visible = false

	# 恢复玩家控制
	_enable_player_control()

	emit_signal("skill_tree_closed")
	print("📕 技能树已关闭")


## 切换技能树显示状态
func toggle_skill_tree() -> void:
	is_skill_tree_visible = not is_skill_tree_visible


## ============================================================================
## 技能列表生成
## ============================================================================

## 填充技能列表（树状结构）
func _populate_skill_list() -> void:
	# 清空现有内容
	for child in skills_container.get_children():
		child.queue_free()

	# 获取所有默认解锁的技能（根技能）
	var root_skills = _get_root_skills()

	# 递归创建技能树
	for skill_id in root_skills:
		_create_skill_tree_recursive(skill_id, 0)


## 获取根技能（无前置条件的技能）
func _get_root_skills() -> Array:
	var root_skills = []
	for skill_id in SkillTreeManager.SKILL_CONFIG:
		var config = SkillTreeManager.get_skill_config(skill_id)
		if config.unlock_condition == "":
			root_skills.append(skill_id)
	return root_skills


## 递归创建技能树
func _create_skill_tree_recursive(skill_id: String, depth: int) -> void:
	# 检查技能是否已解锁
	if not SkillTreeManager.is_skill_unlocked(skill_id):
		return

	# 创建技能项
	var skill_item = _create_skill_item(skill_id, depth)
	skills_container.add_child(skill_item)

	# 查找依赖此技能的子技能
	var child_skills = _get_child_skills(skill_id)

	# 递归创建子技能
	for child_id in child_skills:
		_create_skill_tree_recursive(child_id, depth + 1)


## 获取依赖指定技能的子技能
func _get_child_skills(parent_skill_id: String) -> Array:
	var children = []
	for skill_id in SkillTreeManager.SKILL_CONFIG:
		var config = SkillTreeManager.get_skill_config(skill_id)
		if config.unlock_condition == parent_skill_id:
			children.append(skill_id)
	return children


## 创建单个技能项 UI
func _create_skill_item(skill_id: String, depth: int) -> HBoxContainer:
	var config = SkillTreeManager.get_skill_config(skill_id)
	var current_level = SkillTreeManager.get_skill_level(skill_id)
	var upgrade_cost = SkillTreeManager.get_upgrade_cost(skill_id)
	var skill_value = SkillTreeManager.get_skill_value(skill_id)

	# 创建容器
	var hbox = HBoxContainer.new()
	hbox.name = "SkillItem_%s" % skill_id
	hbox.custom_minimum_size.y = 80

	# 添加缩进（基于深度）
	var indent = 40 * depth
	if indent > 0:
		var indent_control = Control.new()
		indent_control.custom_minimum_size.x = indent
		hbox.add_child(indent_control)

	# 创建技能卡片（使用 PanelContainer 作为背景）
	var card = PanelContainer.new()
	card.name = "SkillCard"
	card.custom_minimum_size = Vector2(420, 70)
	card.mouse_filter = Control.MOUSE_FILTER_PASS  # 允许鼠标事件穿透

	# 创建卡片内部布局
	var card_hbox = HBoxContainer.new()
	card_hbox.name = "CardHBox"

	# 图标（使用 Emoji 占位符）
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(60, 60)

	var icon_label = Label.new()
	icon_label.name = "IconLabel"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 32)

	# 根据 effect_type 选择 Emoji
	var emoji = _get_skill_emoji(config.effect_type)
	icon_label.text = emoji

	icon_container.add_child(icon_label)
	card_hbox.add_child(icon_container)

	# 技能信息区域
	var info_vbox = VBoxContainer.new()
	info_vbox.name = "InfoVBox"
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 技能名称和等级
	var name_level_hbox = HBoxContainer.new()

	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = config.name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_level_hbox.add_child(name_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_level_hbox.add_child(spacer)

	var level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "Lv.%d/%d" % [current_level, config.max_level]
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.add_theme_color_override("font_color", Color.YELLOW)
	name_level_hbox.add_child(level_label)

	info_vbox.add_child(name_level_hbox)

	# 技能描述
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.text = config.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	info_vbox.add_child(desc_label)

	# 效果值
	if skill_value > 0:
		var value_label = Label.new()
		value_label.name = "ValueLabel"
		value_label.text = "当前加成: +%d" % skill_value
		value_label.add_theme_font_size_override("font_size", 11)
		value_label.add_theme_color_override("font_color", Color.CYAN)
		info_vbox.add_child(value_label)

	card_hbox.add_child(info_vbox)

	# 升级按钮
	var upgrade_btn = Button.new()
	upgrade_btn.name = "UpgradeButton"
	upgrade_btn.custom_minimum_size = Vector2(80, 50)

	if current_level >= config.max_level:
		upgrade_btn.text = "已满级"
		upgrade_btn.disabled = true
	else:
		upgrade_btn.text = "%d💰" % upgrade_cost

		# 检查金币是否足够
		if GlobalData.player_coin < upgrade_cost:
			upgrade_btn.disabled = true
			upgrade_btn.tooltip_text = "金币不足"
		else:
			upgrade_btn.tooltip_text = "点击升级"
			# 连接按钮信号（传递 skill_id 参数）
			upgrade_btn.pressed.connect(_on_upgrade_button_pressed.bind(skill_id))

	card_hbox.add_child(upgrade_btn)

	card.add_child(card_hbox)
	hbox.add_child(card)

	# 添加鼠标悬停效果
	_setup_hover_effect(card, upgrade_btn)

	return hbox


## 根据效果类型获取 Emoji
func _get_skill_emoji(effect_type: String) -> String:
	match effect_type:
		"increase_max_health":
			return "❤️"
		"increase_attack":
			return "⚔️"
		"increase_speed":
			return "🏃"
		"increase_critical_chance":
			return "💥"
		_:
			return "⭐"  # 默认图标


## 设置鼠标悬停效果
func _setup_hover_effect(card: PanelContainer, button: Button) -> void:
	# 创建 StyleBox 用于高亮效果
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	normal_style.border_color = Color(0.4, 0.4, 0.5)
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(8)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.3, 0.3, 0.5, 0.95)
	hover_style.border_color = Color(0.8, 0.8, 1.0)
	hover_style.set_border_width_all(3)
	hover_style.set_corner_radius_all(8)

	# 应用默认样式
	card.add_theme_stylebox_override("panel", normal_style)

	# 连接鼠标事件
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseMotion:
			if card.get_rect().has_point(card.get_local_mouse_position()):
				card.add_theme_stylebox_override("panel", hover_style)
			else:
				card.add_theme_stylebox_override("panel", normal_style)
	)

	card.mouse_entered.connect(func():
		card.add_theme_stylebox_override("panel", hover_style)
	)

	card.mouse_exited.connect(func():
		card.add_theme_stylebox_override("panel", normal_style)
	)


## ============================================================================
## 事件处理
## ============================================================================

## 处理输入事件（ESC 键关闭）
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			if is_skill_tree_visible:
				_close_skill_tree()
				get_viewport().set_input_as_handled()


## 升级按钮点击事件
func _on_upgrade_button_pressed(skill_id: String) -> void:
	var success = SkillTreeManager.upgrade_skill(skill_id)

	if success:
		# 刷新 UI
		_populate_skill_list()
		_update_coin_display()
	else:
		# 失败消息已通过 upgrade_failed 信号处理
		pass


## 技能升级成功回调
func _on_skill_upgraded(skill_id: String, new_level: int) -> void:
	var config = SkillTreeManager.get_skill_config(skill_id)
	var value = SkillTreeManager.get_skill_value(skill_id)

	var message = "✅ %s 升级成功！Lv.%d (+%d)" % [config.name, new_level, value]
	_show_notification(message, Color.GREEN)


## 升级失败回调
func _on_upgrade_failed(skill_id: String, reason: String) -> void:
	_show_notification("❌ 升级失败: " + reason, Color.RED)


## 关闭按钮点击事件
func _on_close_button_pressed() -> void:
	_close_skill_tree()


## ============================================================================
## UI 更新
## ============================================================================

## 更新金币显示
func _update_coin_display() -> void:
	if coin_label:
		coin_label.text = "💰 %d" % GlobalData.player_coin


## 显示通知消息（带淡入淡出动画）
func _show_notification(message: String, color: Color = Color.WHITE) -> void:
	if not notification_label:
		return

	# 停止之前的动画
	if _notification_tween:
		_notification_tween.kill()

	# 设置消息
	notification_label.text = message
	notification_label.modulate = color
	notification_label.visible = true

	# 创建淡入淡出动画
	_notification_tween = create_tween()
	_notification_tween.set_ease(Tween.EASE_IN_OUT)
	_notification_tween.set_trans(Tween.TRANS_LINEAR)

	# 淡入
	notification_label.modulate.a = 0.0
	_notification_tween.tween_property(notification_label, "modulate:a", 1.0, 0.3)

	# 保持显示
	_notification_tween.tween_interval(NOTIFICATION_DURATION - 0.6)

	# 淡出
	_notification_tween.tween_property(notification_label, "modulate:a", 0.0, 0.3)

	# 隐藏
	_notification_tween.tween_callback(func(): notification_label.visible = false)


## ============================================================================
## 玩家控制管理（参考商店系统）
## ============================================================================

## 禁用玩家控制
func _disable_player_control() -> void:
	var player = _find_player()
	if player:
		player.set_process_input(false)
		player.set_physics_process(false)


## 恢复玩家控制
func _enable_player_control() -> void:
	var player = _find_player()
	if player:
		player.set_process_input(true)
		player.set_physics_process(true)


## 查找玩家节点（双重查找机制）
func _find_player() -> Node:
	# 方法1：通过组查找
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]

	# 方法2：通过节点名称查找
	var player = get_tree().current_scene.find_child("knight", true, false)
	if player:
		return player

	# 方法3：通过场景根节点查找
	var root_player = get_tree().current_scene.get_node_or_null("knight")
	if root_player:
		return root_player

	push_warning("未找到玩家节点")
	return null
