# 🎨 技能树 UI 实现文档

> **版本**: 1.0
> **最后更新**: 2025-02-11
> **适用项目**: Little Knight Adventure v0.5

---

## 📋 功能清单

### 1. UI 场景结构
- **文件**: `scenes/ui/skill_tree_ui.tscn`, `scripts/ui/skill_tree_ui.gd`
- **功能**:
  - CanvasLayer布局（layer=128）确保UI始终在游戏场景上方
  - 480×224像素居中Panel，适配480×288分辨率
  - 标题栏 "⭐ 技能树" + 当前金币显示
  - 右上角ESC关闭按钮（24×24像素）
  - 顶部通知消息显示（淡入淡出动画，2秒显示）
  - ScrollContainer支持技能滚动

### 2. 技能项展示系统
- **文件**: `scripts/ui/skill_tree_ui.gd:130-275`
- **功能**:
  - 动态创建技能卡片（420×70像素）
  - Emoji图标占位符（❤️⚔️🏃⭐）替代缺失资源
  - 技能名称、等级、描述、当前加成显示
  - 升级按钮（已满级显示灰色禁用状态）
  - 树状结构缩进（每层40像素）
  - 鼠标悬停高亮效果（边框变亮）

### 3. 技能升级系统
- **文件**: `scripts/ui/skill_tree_ui.gd:280-320`
- **功能**:
  - 升级按钮点击验证（金币检查、等级检查）
  - 升级成功通知（绿色，显示技能名称和等级）
  - 升级失败通知（红色，显示原因）
  - 自动刷新UI（更新金币显示、技能列表）
  - 与SkillTreeManager和GlobalData集成

### 4. 技能树结构
- **文件**: `scripts/ui/skill_tree_ui.gd:90-129`
- **功能**:
  - 递归生成技能树（支持无限层级）
  - 根技能识别（无前置条件的技能）
  - 子技能依赖关系（自动缩进显示）
  - 未解锁技能隐藏
  - 解锁技能自动显示（当前置技能升级后）

### 5. 玩家控制系统
- **文件**: `scripts/ui/skill_tree_ui.gd:385-422`
- **功能**:
  - UI打开时禁用玩家控制（set_process_input + set_physics_process）
  - UI关闭时恢复玩家控制
  - 双重查找机制（player组 + knight节点名称）
  - ESC键快捷关闭

### 6. 场景集成
- **文件**: `scenes/start_game.tscn`, `scripts/ui/start_menu.gd`
- **功能**:
  - 技能树UI实例化到start_game场景
  - UPGRADE按钮打开技能树面板
  - 初始测试金币500
  - 自动初始化玩家生命值

---

## ⚠️ 注意事项与设计决策

### 1. 避免CanvasLayer属性冲突（学习自商店系统）

**问题**: CanvasLayer有原生 `visible` 属性和 `show()`/`hide()` 方法

**解决方案** (`scripts/ui/skill_tree_ui.gd:40-52`):
```gdscript
# 使用自定义属性名
var is_skill_tree_visible: bool:
    get:
        return _is_ui_visible()
    set(value):
        if value:
            _open_skill_tree()
        else:
            _close_skill_tree()

# 自定义方法名
func _open_skill_tree() -> void:
    if ui_control:
        ui_control.visible = true
    # ...

func _close_skill_tree() -> void:
    if ui_control:
        ui_control.visible = false
    # ...
```

### 2. 树状结构实现

**需求**: 有前置技能的技能显示在对应前置技能的下一行

**实现** (`scripts/ui/skill_tree_ui.gd:90-129`):
```gdscript
# 递归生成技能树
func _populate_skill_list() -> void:
    var root_skills = _get_root_skills()  # 获取根技能
    for skill_id in root_skills:
        _create_skill_tree_recursive(skill_id, 0)  # 深度0开始

func _create_skill_tree_recursive(skill_id: String, depth: int) -> void:
    # 创建技能项（带缩进）
    var skill_item = _create_skill_item(skill_id, depth)

    # 查找子技能并递归创建
    var child_skills = _get_child_skills(skill_id)
    for child_id in child_skills:
        _create_skill_tree_recursive(child_id, depth + 1)  # 深度+1
```

**缩进计算**:
```gdscript
var indent = 40 * depth  # 每层缩进40像素
if indent > 0:
    var indent_control = Control.new()
    indent_control.custom_minimum_size.x = indent
    hbox.add_child(indent_control)
```

### 3. 鼠标悬停效果

**需求**: 鼠标移动到对应图标上，图标高亮可点击

**实现** (`scripts/ui/skill_tree_ui.gd:300-335`):
```gdscript
func _setup_hover_effect(card: PanelContainer, button: Button) -> void:
    var normal_style = StyleBoxFlat.new()
    normal_style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
    normal_style.border_color = Color(0.4, 0.4, 0.5)

    var hover_style = StyleBoxFlat.new()
    hover_style.bg_color = Color(0.3, 0.3, 0.5, 0.95)
    hover_style.border_color = Color(0.8, 0.8, 1.0)  # 更亮的边框

    # 鼠标进入事件
    card.mouse_entered.connect(func():
        card.add_theme_stylebox_override("panel", hover_style)
    )

    # 鼠标离开事件
    card.mouse_exited.connect(func():
        card.add_theme_stylebox_override("panel", normal_style)
    )
```

### 4. 金币验证

**需求**: 点击时，金币够就提示成功，否则提示不成功

**实现** (`scripts/ui/skill_tree_ui.gd:235-270`):
```gdscript
# 创建升级按钮时检查金币
if GlobalData.player_coin < upgrade_cost:
    upgrade_btn.disabled = true  # 金币不足，禁用按钮
    upgrade_btn.tooltip_text = "金币不足"
else:
    upgrade_btn.tooltip_text = "点击升级"
    upgrade_btn.pressed.connect(_on_upgrade_button_pressed.bind(skill_id))
```

**升级成功/失败处理**:
```gdscript
func _on_skill_upgraded(skill_id: String, new_level: int) -> void:
    var config = SkillTreeManager.get_skill_config(skill_id)
    var value = SkillTreeManager.get_skill_value(skill_id)
    var message = "✅ %s 升级成功！Lv.%d (+%d)" % [config.name, new_level, value]
    _show_notification(message, Color.GREEN)

func _on_upgrade_failed(skill_id: String, reason: String) -> void:
    _show_notification("❌ 升级失败: " + reason, Color.RED)
```

### 5. 通知淡入淡出动画

**实现** (`scripts/ui/skill_tree_ui.gd:370-400`):
```gdscript
func _show_notification(message: String, color: Color = Color.WHITE) -> void:
    # 停止之前的动画
    if _notification_tween:
        _notification_tween.kill()

    notification_label.text = message
    notification_label.modulate = color
    notification_label.visible = true

    # 创建Tween动画
    _notification_tween = create_tween()
    _notification_tween.set_ease(Tween.EASE_IN_OUT)
    _notification_tween.set_trans(Tween.TRANS_LINEAR)

    # 淡入 (0.3秒)
    notification_label.modulate.a = 0.0
    _notification_tween.tween_property(notification_label, "modulate:a", 1.0, 0.3)

    # 保持显示 (1.4秒)
    _notification_tween.tween_interval(1.4)

    # 淡出 (0.3秒)
    _notification_tween.tween_property(notification_label, "modulate:a", 0.0, 0.3)

    # 隐藏
    _notification_tween.tween_callback(func(): notification_label.visible = false)
```

---

## 🎨 视觉设计

### 技能图标（Emoji占位符）

根据 `effect_type` 自动选择图标：

| 效果类型 | Emoji | 技能名称 |
|---------|-------|---------|
| `increase_max_health` | ❤️ | 生命值 |
| `increase_attack` | ⚔️ | 攻击力 |
| `increase_speed` | 🏃 | 移动速度 |
| `increase_critical_chance` | 💥 | 暴击率 |
| 其他 | ⭐ | 默认 |

### 颜色方案

| 元素 | 颜色 | 用途 |
|-----|------|------|
| 面板背景 | `Color(0.15, 0.15, 0.2, 0.95)` | 半透明深色背景 |
| 面板边框 | `Color(0.5, 0.5, 0.6)` | 中性灰色边框 |
| 卡片背景（普通） | `Color(0.2, 0.2, 0.3, 0.9)` | 深蓝灰色 |
| 卡片背景（悬停） | `Color(0.3, 0.3, 0.5, 0.95)` | 亮蓝紫色 |
| 卡片边框（普通） | `Color(0.4, 0.4, 0.5)` | 暗边框 |
| 卡片边框（悬停） | `Color(0.8, 0.8, 1.0)` | 亮边框 |
| 关闭按钮背景 | `Color(0.8, 0.2, 0.2, 1.0)` | 红色 |
| 等级文本 | `Color.YELLOW` | 黄色 |
| 描述文本 | `Color.LIGHT_GRAY` | 浅灰色 |
| 加成文本 | `Color.CYAN` | 青色 |
| 成功通知 | `Color.GREEN` | 绿色 |
| 失败通知 | `Color.RED` | 红色 |

### 字体大小

| 元素 | 字号 | 用途 |
|-----|------|------|
| 技能图标 | 32px | Emoji图标 |
| 技能名称 | 16px | 主标题 |
| 等级 | 14px | 等级显示 |
| 描述 | 12px | 技能描述 |
| 加成 | 11px | 当前加成 |

---

## 📊 技能树结构示例

```
⭐ 技能树                       💰 500
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❤️ 生命值            Lv.0/3
   提升最大生命值
   [100💰]

   ⚔️ 攻击力         Lv.0/3
      提升攻击伤害
      [150💰]

🏃 移动速度          Lv.0/2  (需要先升级生命值)
   提升移动速度
   [200💰]
```

**说明**:
- 生命值和攻击力是根技能（无前置条件）
- 移动速度依赖生命值（缩进显示）
- 按钮显示升级费用
- 等级显示为 Lv.当前/最大

---

## 🎯 使用流程

### 玩家操作流程

1. **打开技能树**: 点击主菜单 "UPGRADE" 按钮
2. **查看技能**: 滚动查看所有已解锁技能
3. **悬停高亮**: 鼠标移到技能卡片上，边框变亮
4. **点击升级**: 点击升级按钮（显示费用）
5. **查看结果**:
   - ✅ 成功：绿色通知显示升级成功
   - ❌ 失败：红色通知显示失败原因
6. **关闭面板**: 点击右上角 "✕" 或按 ESC 键

### 开发者扩展流程

1. **添加新技能**: 编辑 `skill_tree_manager.gd` 的 `SKILL_CONFIG`
2. **设置图标**: 修改 `_get_skill_emoji()` 函数或添加 `icon_path`
3. **实现效果**: 在 `_apply_skill_effect()` 中添加新 case
4. **设置依赖**: 在 `unlock_condition` 中指定前置技能ID

---

## 🔧 技术细节

### 节点路径结构

```
SkillTreeUI (CanvasLayer)
└── SkillTreeControl (Control)
    └── PanelContainer
        ├── CloseButton (Button)
        └── VBoxContainer
            ├── TitleBar (PanelContainer)
            │   └── HBoxContainer
            │       ├── TitleLabel (Label)
            │       ├── Control (Spacer)
            │       └── CoinLabel (Label)
            ├── NotificationLabel (Label)
            └── ScrollContainer
                └── SkillsVBox (VBoxContainer)
                    └── [动态生成的技能项]
```

### 信号连接

```gdscript
# SkillTreeManager 信号
SkillTreeManager.skill_upgraded.connect(_on_skill_upgraded)
SkillTreeManager.upgrade_failed.connect(_on_upgrade_failed)

# 关闭按钮信号
close_button.pressed.connect(_on_close_button_pressed)

# ESC 键处理
func _input(event: InputEvent) -> void:
    if event.keycode == KEY_ESCAPE and event.pressed:
        if is_skill_tree_visible:
            _close_skill_tree()
```

---

## ✅ 测试清单

- [x] 技能树UI正确显示在屏幕中央
- [x] ESC按钮显示为24×24小方块
- [x] 标题显示"⭐ 技能树"
- [x] 金币显示正确（初始500）
- [x] 技能列表正确显示（生命值、攻击力、移动速度）
- [x] 树状结构正确（移动速度缩进显示）
- [x] 鼠标悬停高亮效果工作
- [x] 升级按钮显示费用
- [x] 金币不足时按钮禁用
- [x] 升级成功显示绿色通知
- [x] 升级失败显示红色通知
- [x] 通知淡入淡出动画正常
- [x] 玩家控制正确禁用/恢复
- [x] ESC键关闭技能树
- [x] UPGRADE按钮打开技能树
- [x] 与SkillTreeManager集成正确
- [x] 与GlobalData金币系统集成正确

---

## 📝 已知限制

1. **图标占位符**: 当前使用Emoji，后续可替换为真实图标
2. **攻击力效果**: 标记为 TODO，需要在GlobalData中添加 player_attack
3. **移动速度效果**: 标记为 TODO，需要在玩家脚本中读取技能加成
4. **存档集成**: 技能数据尚未整合到 SaveLoad 系统
5. **音效**: 暂无升级音效和UI音效

---

## 🚀 未来改进

### 优先级 P1
- [ ] 整合到 SaveLoad 存档系统
- [ ] 实现攻击力和移动速度效果
- [ ] 添加技能升级音效
- [ ] 添加技能图标资源

### 优先级 P2
- [ ] 技能树分支可视化（连线）
- [ ] 技能重置功能（返还金币）
- [ ] 多套技能树系统
- [ ] 技能升级动画效果

### 优先级 P3
- [ ] 技能描述富文本（支持颜色）
- [ ] 技能预览（升级前后对比）
- [ ] 技能推荐系统（AI建议）
- [ ] 成就系统整合

---

## 🔗 相关文档

- **技能管理器**: [scripts/autoload/skill_tree_manager.gd](../scripts/autoload/skill_tree_manager.gd)
- **使用指南**: [技能树系统使用指南.md](./技能树系统使用指南.md)
- **商店系统**: [商店系统实现文档.md](./商店系统实现文档.md)
- **项目配置**: [project.godot](../project.godot)

---

**开发日期**: 2025-02-11
**代码行数**: 约600行（新增）
**改动文件**: 4个文件
