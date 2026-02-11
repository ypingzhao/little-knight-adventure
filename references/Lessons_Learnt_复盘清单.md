# 📝 项目文件迁移 - Lessons Learnt 复盘清单

> **目的**：为未来的 AI session 提供快速参考，避免重复踩坑
>
> **补充文档**：本文档是对已有详细文档的凝练总结，不重复内容

---

## ⚡ 关键教训

### 🔴 严重问题（必须避免）

- **Windows 大小写陷阱**：`Scripts/` 和 `scripts/` 在 Windows 上是同一文件夹，删除一个会同时删除另一个
  - ✅ **预防**：永远只用小写文件夹名，迁移前先 `git commit`
  - ❌ **错误**：先删除旧文件夹再移动新文件夹

- **class_name 双重定义**：新旧位置同时存在相同 `class_name` 会导致 Parse Error
  - ✅ **预防**：移动文件后立即删除旧位置文件
  - ✅ **检测**：`grep -r "class_name" --include="*.gd" | grep -v "scripts/actors/" | grep -v "scripts/autoload/"` 等

- **.godot 缓存污染**：即使更新了所有引用，编辑器仍会从缓存中读取旧路径
  - ✅ **预防**：移动文件后立即删除 `.godot/` 文件夹
  - ✅ **时机**：在文件移动和引用更新都完成后删除

### 🟡 重要经验（提高效率）

- **批量操作优于手动**：38个场景文件手动更新耗时且易错
  - ✅ **工具**：使用 `find + sed` 批量替换
  - ✅ **验证**：替换后用 `grep` 验证无遗漏

- **UID 更新是可选的**：UID 警告不影响游戏运行，但建议修复
  - ✅ **优先级**：先修复 Parser Error 和 File not found，再修复 UID
  - ✅ **方法**：优先使用自动化工具脚本

- **Git 是安全网**：每次大批量操作前都应提交
  - ✅ **频率**：每完成一批操作就提交（便于回滚）
  - ✅ **粒度**：删除文件、更新路径、修复错误分别提交

---

## 🎯 操作流程优化

### ✅ 推荐的迁移流程（基于实际经验）

```
1. 准备阶段
   - git commit -m "迁移前备份"
   - 关闭 Godot 编辑器

2. 文件移动
   - 使用 git mv 保留历史
   - 或 cp + 验证后再删除旧文件

3. 路径更新
   - 批量替换所有 .tscn 文件中的路径
   - 批量替换 project.godot 中的 autoload 路径
   - git commit

4. 清理旧文件
   - 验证新位置文件存在
   - 删除旧位置文件（小心 Windows 大小写）
   - git commit

5. 清除缓存
   - 删除 .godot/ 文件夹
   - 重新打开项目

6. 验证
   - 检查无 Parser Error
   - 检查无 File not found
   - 测试游戏运行
```

### ❌ 错误的操作顺序

```
❌ 先删除旧文件夹 → 移动新文件（Windows 会误删）
❌ 移动文件后不删除旧文件 → class_name 冲突
❌ 更新引用后不清缓存 → 编辑器仍读旧路径
❌ 批量操作前不提交 git → 无法回滚
```

---

## 🔧 工具和脚本

### 已创建的工具（可复用）

- **`scripts/utils/update_scene_uids.gd`** - Godot 工具脚本，批量更新 UID
- **`fix_all_uids.sh`** - Bash 脚本，批量修复 UID 不匹配
- **`fix_uids.py`** - Python 脚本，跨平台 UID 修复

### 常用检查命令

```bash
# 检查旧路径引用
grep -r "res://Scripts/" scenes/
grep -r "res://player/" scenes/

# 检查 class_name 冲突
grep -r "class_name" --include="*.gd" scripts/ | grep -v "scripts/actors/" | grep -v "scripts/autoload/"

# 检查文件是否存在
ls scripts/autoload/global_data.gd
ls scripts/actors/enemies/bat.gd

# 检查 UID 引用数量
grep -r "kill_zone\.tscn" scenes/ --include="*.tscn" | wc -l
```

---

## 📊 问题优先级

### P0 - 阻塞性问题（立即修复）
- Parser Error: Class "XXX" hides a global script class
- Cannot open file 'res://xxx.tscn'
- Failed loading resource

### P1 - 功能性问题（尽快修复）
- Attempt to open script resulted in error 'File not found'
- 脚本路径未更新

### P2 - 警告性问题（建议修复）
- invalid UID: uid://xxx - using text path instead
- UID 不匹配警告

---

## 🚀 给未来 AI 的建议

### DO ✅

- **Windows 环境**：始终使用小写文件夹名（scripts/, assets/, scenes/）
- **批量操作**：优先使用 find + sed，避免手动编辑
- **Git 频繁提交**：每完成一个子任务就提交
- **删除前验证**：确认新文件存在后再删除旧文件
- **清除缓存**：移动文件后删除 .godot/ 文件夹

### DON'T ❌

- **不要同时存在** Scripts/ 和 scripts/ 文件夹
- **不要在编辑器打开时**修改场景文件路径
- **不要忘记删除**旧位置的重复文件
- **不要跳过验证**：更新后必须测试游戏运行
- **不要忽略 Windows 大小写问题**：这是最常见的严重错误

---

## 📈 本次迁移数据

- **脚本文件**：40+ 个
- **场景文件**：38 个 .tscn 更新
- **提交次数**：18 次
- **遇到问题**：6 个主要问题
- **总耗时**：~3 小时（含问题排查）
- **删除旧文件**：19 个
- **创建文档**：3 个详细文档 + 1 个复盘清单

---

## 🔗 相关文档参考

1. **[文件组织迁移指南.md](./文件组织迁移指南.md)** - 完整迁移步骤和故障排查
2. **[UID不匹配问题修复指南.md](./UID不匹配问题修复指南.md)** - UID 问题详解
3. **[场景文件移动后的缓存清理问题.md](./场景文件移动后的缓存清理问题.md)** - 缓存问题解决方案
4. **[项目文件组织规范.md](./项目文件组织规范.md)** - 文件组织标准

---

**创建时间**: 2025-02-11
**适用项目**: Little Knight Adventure v0.5
**目的**: 为未来 AI session 提供快速参考，避免重复踩坑
**版本**: 1.0
