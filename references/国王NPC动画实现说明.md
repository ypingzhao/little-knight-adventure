# 国王NPC Idle动画实现说明

## 📋 概述
为商店场景中的国王NPC添加了idle序列帧动画，替换了原本的静态Sprite2D。

## 🎨 资源信息
- **源文件**: `assets/Kings and Pigs Sprites/01-King Human/Idle (78x58).png`
- **帧尺寸**: 78x58 像素
- **帧数**: 11 帧
- **动画类型**: 水平序列帧图集

## 📁 相关文件

### 1. NPC场景
**文件**: `scenes/NPC/shop_keeper.tscn`
- 将 `Sprite2D` 替换为 `AnimatedSprite2D`
- 使用内嵌的 `SubResource SpriteFrames` (不使用外部文件)
- 设置自动播放 (`autoplay = &"idle"`)
- 保持原有 scale `Vector2(-1, 1)` (水平翻转)
- 位置: `Vector2(6, -15)`

### 2. 工具脚本 (可选)
**文件**: `Scripts/tools/create_king_animation.gd`
- 编辑器工具脚本
- 可用于自动生成动画资源
- 在编辑器中: 项目 -> 工具 -> 运行脚本

## 🔧 技术细节

### 重要修复 (2025-02-11)
最初使用外部 SpriteFrames 资源文件导致动画无法播放。**已修复**为使用内嵌 SubResource 方式，这是 Godot 4.x 的推荐做法。

### AtlasTexture 坐标配置
每一帧使用独立的 AtlasTexture，通过 `region` 属性指定切分区域：
- 第1帧: `Rect2(0, 0, 78, 58)`
- 第2帧: `Rect2(78, 0, 78, 58)`
- 第3帧: `Rect2(156, 0, 78, 58)`
- ...
- 第11帧: `Rect2(780, 0, 78, 58)`

### 动画参数
- **名称**: "idle"
- **速度**: 8.0 FPS (每帧0.125秒)
- **循环**: true
- **总时长**: 约1.375秒 (11帧 ÷ 8 FPS)

## ✅ 使用说明
1. 在 Godot 编辑器中打开项目
2. 打开 `scenes/NPC/shop_keeper.tscn`
3. 运行游戏，国王NPC会自动播放idle动画
4. 可以在场景中调整 SpriteFrames 的播放速度

### 在编辑器中调整动画
1. 选择 `AnimatedSprite2D` 节点
2. 在 Inspector 中找到 `SpriteFrames`
3. 点击展开，可以看到所有帧
4. 在底部面板中可以：
   - 调整 `Speed` (FPS)
   - 预览动画
   - 添加/删除帧

## 🎨 自定义建议
- 调整播放速度: 在 Inspector 中修改 SpriteFrames 的 `speed` 值
- 添加其他动画: 在 SpriteFrames 中添加新的动画轨道
- 调整帧顺序: 在 frames 数组中重新排列

## 📝 后续可扩展功能
- [ ] 添加 walk 动画 (使用 `Run (78x58).png`)
- [ ] 添加 attack 动画 (使用 `Attack (78x58).png`)
- [ ] 添加交互动画 (打开商店时的特殊动作)
- [ ] 根据玩家距离切换不同的idle动作

---
**创建日期**: 2025-02-11
**最后更新**: 2025-02-11 (修复动画不播放问题)
**状态**: ✅ 完成并测试通过
