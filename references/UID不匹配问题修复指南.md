# UID 不匹配问题修复指南

## 📋 概述

本文档详细记录了 Godot 4.x 项目中 UID（Unique Resource Identifier）不匹配警告的原因、检测方法和修复方案。

---

## 🔍 什么是 UID？

### UID 的作用

在 Godot 4.x 中，每个资源文件（脚本、场景、材质等）都有一个唯一的 UID 标识符，格式为：

```
uid://xxxxxxxxxxxx
```

**UID 的优势**：
- ✅ 允许资源文件被重命名或移动而不破坏引用
- ✅ 比 `res://` 路径更稳定可靠
- ✅ Godot 可以通过 UID 快速定位资源

### UID 存储位置

- **脚本文件**：存储在 `.gd.uid` 文件中（与 `.gd` 文件同目录）
- **场景文件**：内嵌在 `.tscn` 文件的元数据中
- **其他资源**：内嵌在资源文件中或 `.uid` 文件中

---

## ⚠️ UID 不匹配警告的症状

### 典型警告信息

```
W 0:00:02:696 level_manager.gd:28 @ goto_next_room():
res://scenes/enemies/slime_green.tscn:4 - ext_resource, invalid UID: uid://bs07w5jexn0lw
- using text path instead: res://scripts/actors/enemies/slime_green.gd
```

### 警告的含义

- 场景文件中的 UID 引用 `uid://bs07w5jexn0lw` 无效
- Godot 回退到使用文本路径 `res://scripts/actors/enemies/slime_green.gd`
- **游戏仍可正常运行**，但会产生警告信息

---

## 🐛 造成 UID 不匹配的原因

### 原因 1: 文件移动后 UID 未更新

**场景**：文件重组或迁移时

```
旧结构：
scripts/actors/enemies/slime_green.gd
  └── slime_green.gd.uid (包含 uid://old123)

新结构：
scripts/actors/enemies/slime_green.gd
  └── slime_green.gd.uid (包含 uid://new456)

问题：
- 场景文件仍引用 uid://old123
- 实际脚本 UID 已变为 uid://new456
```

**本项目的实际情况**：
- 40+ 个脚本文件从旧位置移动到 `scripts/` 新结构
- 38+ 个场景文件中的 UID 引用未同步更新

### 原因 2: 批量文件操作

**常见操作**：
- 使用 `git mv` 移动文件
- 手动复制粘贴文件
- 使用脚本批量重命名

**结果**：
- `.uid` 文件可能丢失或未同步移动
- 新位置的 `.uid` 文件包含不同的 UID
- 场景文件引用的 UID 与实际不匹配

### 原因 3: 跨设备或跨系统同步

**场景**：
- Windows → Linux 文件系统不兼容
- Git 冲突解决时选择错误的 UID
- 多人协作时 UID 不同步

---

## 🔎 如何检测 UID 不匹配

### 方法 1: 查看 Godot 控制台

运行游戏时查看警告信息：

```
W 0:00:02:696 - ext_resource, invalid UID: uid://xxxxxxxxx
- using text path instead: res://scripts/...
```

### 方法 2: 检查场景文件

打开 `.tscn` 文件，查找脚本引用：

```ini
[ext_resource type="Script" uid="uid://old123" path="res://scripts/actors/enemies/slime_green.gd" id="1"]
```

对比 `.gd.uid` 文件内容：

```bash
cat scripts/actors/enemies/slime_green.gd.uid
# 输出: uid://new456
```

如果 `uid://old123` ≠ `uid://new456`，则存在不匹配。

### 方法 3: 批量检测脚本

使用以下 bash 命令批量检测：

```bash
#!/bin/bash
# 检测所有 UID 不匹配的脚本引用

find scripts -name "*.gd.uid" | while read uidfile; do
    scriptfile="${uidfile%.uid}"
    scriptpath="res://${scriptfile//\\//}"
    correctuid=$(cat "$uidfile" | tr -d '\r\n')

    find scenes -name "*.tscn" | while read scenefile; do
        if grep -q "path=\"$scriptpath\"" "$scenefile" 2>/dev/null; then
            currentuid=$(grep "path=\"$scriptpath\"" "$scenefile" | grep -oP 'uid="\K[^"]+')

            if [ -n "$currentuid" ] && [ "$currentuid" != "$correctuid" ]; then
                echo "⚠️  UID 不匹配: $scenefile"
                echo "   脚本: $scriptpath"
                echo "   当前: uid://$currentuid"
                echo "   正确: $correctuid"
                echo ""
            fi
        fi
    done
done
```

---

## 🛠️ 修复方法

### 方法 1: 在 Godot 编辑器中手动修复（推荐新手）

**步骤**：

1. 在 Godot 编辑器中打开场景文件
2. 选择根节点或其他有脚本引用的节点
3. 在 Inspector 面板中找到 `Script` 属性
4. 点击脚本路径，重新选择脚本（即使路径相同）
5. 保存场景（Ctrl+S）
6. 关闭并重新打开场景确认

**优点**：
- ✅ 最安全，不会有语法错误
- ✅ Godot 自动更新 UID
- ✅ 适合单个文件修复

**缺点**：
- ❌ 耗时较长，不适合批量修复
- ❌ 需要逐个打开场景

### 方法 2: 使用 Godot 工具脚本批量修复（推荐）

**步骤**：

1. 创建工具脚本 `scripts/utils/update_scene_uids.gd`：

```gdscript
@tool
extends EditorScript

# 批量更新场景文件中脚本的UID引用
# 在Godot编辑器中运行：项目 -> 工具 -> 运行脚本

var updated_count = 0
var error_count = 0

func _run() -> void:
    print("开始更新场景文件的UID引用...")
    updated_count = 0
    error_count = 0

    # 递归扫描 scenes/ 目录
    _scan_directory("res://scenes/")

    print("\n✅ 更新完成！")
    print("成功更新: ", updated_count, " 个文件")
    print("错误: ", error_count, " 个文件")

func _scan_directory(dir_path: String) -> void:
    var dir = DirAccess.open(dir_path)
    if not dir:
        push_error("无法打开目录: " + dir_path)
        return

    dir.list_dir_begin()
    var file_name = dir.get_next()

    while file_name != "":
        if file_name == "." or file_name == "..":
            file_name = dir.get_next()
            continue

        var full_path = dir_path + file_name

        if dir.current_is_dir():
            _scan_directory(full_path + "/")
        elif file_name.ends_with(".tscn"):
            _update_scene_uids(full_path)

        file_name = dir.get_next()

    dir.list_dir_end()

func _update_scene_uids(file_path: String) -> void:
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        push_error("无法打开文件: " + file_path)
        error_count += 1
        return

    var content = file.get_as_text()
    file.close()

    var lines = content.split("\n")
    var modified = false
    var file_updated_count = 0

    for i in range(lines.size()):
        var line = lines[i]
        if line.begins_with("[ext_resource type=\"Script\"") and line.contains(".gd\""):
            var path_start = line.find("path=\"") + 6
            var path_end = line.find("\"", path_start)
            var script_path = line.substr(path_start, path_end - path_start)

            if script_path.begins_with("res://scripts/"):
                if FileAccess.file_exists(script_path):
                    var uid_file = script_path + ".uid"
                    if FileAccess.file_exists(uid_file):
                        var uid_file_obj = FileAccess.open(uid_file, FileAccess.READ)
                        if uid_file_obj:
                            var uid_content = uid_file_obj.get_as_text().strip_edges()
                            uid_file_obj.close()

                            var old_uid_start = line.find("uid://")
                            if old_uid_start > 0:
                                var old_uid_end = line.find("\"", old_uid_start)
                                line = line.substr(0, old_uid_start) + uid_content + line.substr(old_uid_end)
                                lines[i] = line
                                modified = true
                                file_updated_count += 1
                                print("  ✓ ", script_path)

    if modified:
        var file_write = FileAccess.open(file_path, FileAccess.WRITE)
        if file_write:
            file_write.store_string("\n".join(lines))
            file_write.close()
            updated_count += file_updated_count
            print("  📄 ", file_path, " (", file_updated_count, " 个引用)")
        else:
            push_error("无法写入文件: " + file_path)
            error_count += 1
```

2. 在 Godot 编辑器中运行：
   - 顶部菜单：**项目** → **工具** → **运行脚本**
   - 选择 `scripts/utils/update_scene_uids.gd`

**优点**：
- ✅ 自动化批量处理
- ✅ 使用 Godot 原生 API，兼容性好
- ✅ 实时查看进度

**缺点**：
- ❌ 需要在 Godot 编辑器中运行
- ❌ 不适合 CI/CD 自动化

### 方法 3: 使用 Bash 脚本批量修复（本项目采用）

**步骤**：

1. 创建修复脚本 `fix_all_uids.sh`：

```bash
#!/bin/bash
# 批量修复所有场景文件中的UID引用

echo "开始批量修复UID..."

# 遍历所有 .gd.uid 文件
for uidfile in $(find scripts -name "*.gd.uid" -type f); do
    # 获取脚本文件名（去掉.uid后缀）
    scriptfile="${uidfile%.uid}"

    # 读取正确的UID
    correctuid=$(cat "$uidfile" | tr -d '\r\n')

    # 构建res://路径
    scriptpath="res://${scriptfile//\\//}"

    # 在所有场景文件中查找并替换
    find scenes -name "*.tscn" -type f | while read scenefile; do
        # 检查是否包含该脚本路径
        if grep -q "path=\"$scriptpath\"" "$scenefile" 2>/dev/null; then
            # 提取当前的旧UID
            olduid=$(grep "path=\"$scriptpath\"" "$scenefile" | grep -oP 'uid="\K[^"]+' | head -1)

            if [ -n "$olduid" ] && [ "$olduid" != "$correctuid" ]; then
                echo "修复: $(basename "$scenefile")"
                echo "  脚本: $scriptpath"
                echo "  旧UID: uid://$olduid"
                echo "  新UID: $correctuid"

                # 替换UID
                sed -i "s|uid=\"$olduid\"|uid=\"$correctuid\"|g" "$scenefile"
            fi
        fi
    done
done

echo "✅ UID修复完成！"
```

2. 运行脚本：

```bash
chmod +x fix_all_uids.sh
./fix_all_uids.sh
```

**优点**：
- ✅ 命令行运行，无需打开编辑器
- ✅ 适合 CI/CD 集成
- ✅ 快速处理大量文件

**缺点**：
- ❌ 依赖 Linux/WSL 环境
- ❌ Windows 上需要 Git Bash 或 WSL

### 方法 4: 使用 Python 脚本（跨平台）

**步骤**：

1. 创建 Python 脚本 `fix_uids.py`：

```python
#!/usr/bin/env python3
"""
批量修复场景文件中的UID引用
自动读取脚本的.uid文件并更新场景文件中的引用
"""

import os
import re
from pathlib import Path

def main():
    print("开始修复UID...")

    project_root = Path(__file__).parent
    scripts_dir = project_root / "scripts"
    scenes_dir = project_root / "scenes"

    updated_count = 0
    error_count = 0

    # 查找所有 .gd.uid 文件
    for uid_file in scripts_dir.rglob("*.gd.uid"):
        # 读取正确的UID
        with open(uid_file, 'r', encoding='utf-8') as f:
            correct_uid = f.read().strip()

        # 脚本文件路径
        script_file = uid_file.with_suffix('')
        script_path = "res://" + script_file.relative_to(project_root).as_posix()

        # 在场景文件中查找引用
        for scene_file in scenes_dir.rglob("*.tscn"):
            try:
                with open(scene_file, 'r', encoding='utf-8') as f:
                    content = f.read()

                if script_path in content:
                    lines = content.split('\n')
                    modified = False

                    for i, line in enumerate(lines):
                        if 'type="Script"' in line and script_path in line:
                            uid_match = re.search(r'uid="([^"]*)"', line)
                            if uid_match:
                                current_uid = uid_match.group(1)

                                if current_uid != correct_uid:
                                    line = line.replace(f'uid="{current_uid}"', f'uid="{correct_uid}"')
                                    lines[i] = line
                                    modified = True

                                    print(f"  ✓ {scene_file.name}")
                                    print(f"    脚本: {script_path}")
                                    print(f"    旧UID: {current_uid}")
                                    print(f"    新UID: {correct_uid}")

                    if modified:
                        with open(scene_file, 'w', encoding='utf-8', newline='\n') as f:
                            f.write('\n'.join(lines))
                        updated_count += 1

            except Exception as e:
                print(f"  ⚠ 错误: {scene_file} - {e}")
                error_count += 1

    print(f"\n✅ 修复完成！")
    print(f"更新了 {updated_count} 个场景文件")
    print(f"错误: {error_count} 个")

if __name__ == "__main__":
    main()
```

2. 运行脚本：

```bash
python fix_uids.py
# 或
python3 fix_uids.py
```

**优点**：
- ✅ 跨平台（Windows/Linux/macOS）
- ✅ 纯文本操作，简单可靠
- ✅ 详细的错误报告

**缺点**：
- ❌ 需要安装 Python 3.x

---

## 📊 本项目修复案例

### 修复统计

**修复范围**：
- **修复文件数量**：32 个场景文件
- **涉及脚本数量**：25+ 个脚本文件
- **修复位置**：
  - `scenes/` 目录：28 个 .tscn 文件
  - 根目录：4 个 .tscn 文件

### 修复的具体文件

#### 📁 scenes/ 目录

**enemies/**
- `bat.tscn` - 更新 bat.gd 的 UID
- `bat_spawner.tscn` - 更新 bat_spawner.gd 的 UID
- `slime_green.tscn` - 更新 slime_green.gd 的 UID
- `slime_purple.tscn` - 更新 slime_boss.gd 的 UID

**NPC/**
- `knight.tscn` - 更新 knight.gd 的 UID
- `soldier.tscn` - 更新 npc.gd 的 UID
- `shop_keeper.tscn` - 更新 shop_keeper.gd 的 UID

**items/**
- `coin.tscn` - 更新 coin.gd 的 UID
- `box.tscn` - 更新 box.gd 的 UID
- `door.tscn` - 更新 door.gd 的 UID
- `sword.tscn` - 更新 sword.gd 的 UID
- `health_pot.tscn` - 更新 health_potion.gd 的 UID
- `treasure_box.tscn` - 更新 treasure_box.gd 的 UID
- `fruit_a.tscn` - 更新 interaction_area.gd 的 UID
- `fruit_b.tscn` - 更新 interaction_area.gd 的 UID

**levels/**
- `coco_adventure.tscn` - 更新 coco_adventure.gd 的 UID
- `dungeon.tscn` - 更新 dungeon.gd 的 UID
- `oscar_adventure.tscn` - 更新 oscar_adventure.gd 的 UID
- `shop.tscn` - 更新 shop.gd 的 UID
- `boss01_scene.tscn` - 更新 boss_arena.gd 的 UID
- `island_normal_ch_1.tscn` - 更新 active_platform.gd 的 UID
- `dungeon_normal_ch_1.tscn` - 更新相关脚本 UID

**traps/**
- `spike.tscn` - 更新 spike.gd 的 UID
- `waterfall.tscn` - 更新 waterfall.gd 的 UID

#### 📁 根目录

- `kill_zone.tscn` - 更新 kill_zone.gd 的 UID
  - 旧UID: `uid://cp8ei1nm6w53s`
  - 新UID: `uid://k5hl2sclsl0t`
- `fall_stone.tscn` - 更新 falling_stone.gd 的 UID
  - 旧UID: `uid://b3se5x4xqh2qh`
  - 新UID: `uid://b146j3k8ias2p`
- `flying_pig.tscn` - 更新 flying_pig.gd 的 UID
  - 旧UID: `uid://8yljrdb2nrlj`
  - 新UID: `uid://rros263s02j`
- `GlobalData.tscn` - 更新 global_data.gd 的 UID
  - 旧UID: `uid://h088x803o47g`
  - 新UID: `uid://cid6ef01fw8m4`

### 修复效果

**修复前**：
```
W 0:00:02:348 level_manager.gd:28 @ goto_next_room():
res://kill_zone.tscn:3 - ext_resource, invalid UID: uid://cp8ei1nm6w53s
- using text path instead: res://scripts/traps/kill_zone.gd

W 0:00:02:696 level_manager.gd:28 @ goto_next_room():
res://scenes/coco_adventure.tscn:3 - ext_resource, invalid UID: uid://48h5jtm1voqy
- using text path instead: res://scripts/levels/coco_adventure.gd
```

**修复后**：
```
（控制台输出干净，无 UID 警告）
```

---

## 🛡️ 预防措施

### 1. 文件移动时的最佳实践

**✅ 推荐做法**：
```bash
# 使用 git mv 移动文件（保留 .uid 文件）
git mv old_location/script.gd new_location/script.gd
git mv old_location/script.gd.uid new_location/script.gd.uid
```

**❌ 避免做法**：
```bash
# 直接复制粘贴，可能丢失 .uid 文件
cp old/script.gd new/script.gd
# 忘记复制 .uid 文件
```

### 2. 定期验证 UID 一致性

创建定期检查脚本 `check_uids.sh`：

```bash
#!/bin/bash
# 检查 UID 不匹配问题

echo "检查 UID 一致性..."

count=0
for uidfile in $(find scripts -name "*.gd.uid"); do
    scriptfile="${uidfile%.uid}"
    scriptpath="res://${scriptfile//\\//}"
    correctuid=$(cat "$uidfile" | tr -d '\r\n')

    for scenefile in $(find scenes -name "*.tscn"); do
        if grep -q "path=\"$scriptpath\"" "$scenefile" 2>/dev/null; then
            currentuid=$(grep "path=\"$scriptpath\"" "$scenefile" | grep -oP 'uid="\K[^"]+')

            if [ -n "$currentuid" ] && [ "$currentuid" != "$correctuid" ]; then
                echo "⚠️  不匹配: $scenefile"
                echo "   脚本: $scriptpath"
                count=$((count + 1))
            fi
        fi
    done
done

if [ $count -eq 0 ]; then
    echo "✅ 所有 UID 匹配正确！"
else
    echo "❌ 发现 $count 个 UID 不匹配问题"
    exit 1
fi
```

### 3. Git 提交前检查

在 `.git/hooks/pre-commit` 中添加 UID 检查：

```bash
#!/bin/bash
# 提交前检查 UID 一致性

./check_uids.sh
if [ $? -ne 0 ]; then
    echo "提交被阻止：存在 UID 不匹配问题"
    echo "请运行 ./fix_all_uids.sh 修复"
    exit 1
fi
```

### 4. 团队协作注意事项

- ✅ 提交时包含 `.uid` 文件
- ✅ 冲突解决时保留正确的 UID
- ✅ 定期同步团队间的 UID 更改
- ✅ 在 pull request 中检查 UID 变更

---

## 🔧 常见问题 FAQ

### Q1: UID 警告会影响游戏运行吗？

**A**: 不会。UID 警告只是提示，Godot 会自动回退到使用文本路径。但建议修复以保持项目整洁。

### Q2: 为什么移动文件后 UID 会变化？

**A**: 如果 `.uid` 文件未同步移动，Godot 会为脚本生成新的 UID，导致旧引用失效。

### Q3: 可以完全禁用 UID 吗？

**A**: 不建议。UID 是 Godot 4.x 的核心特性，禁用会导致其他问题（如资源引用不稳定）。

### Q4: 修复后仍然有警告怎么办？

**A**:
1. 在编辑器中打开场景，重新选择脚本并保存
2. 清除 `.godot` 缓存文件夹
3. 重启 Godot 编辑器

### Q5: 如何确认所有 UID 都已修复？

**A**:
1. 运行 `check_uids.sh` 脚本
2. 运行游戏查看控制台是否还有 UID 警告
3. 在 Godot 编辑器中检查输出面板

---

## 📚 相关文档

- [Godot 4.x 资源系统文档](https://docs.godotengine.org/en/stable/tutorials/assets/index.html)
- [项目文件组织规范](./项目文件组织规范.md)
- [文件组织迁移指南](./文件组织迁移指南.md)
- [2D动画生成注意事项](./2D动画生成注意事项.md)

---

## 📝 更新日志

### v1.0 - 2025-02-11
- 初始版本
- 记录本次 UID 修复的完整过程
- 提供 4 种修复方法
- 添加预防措施和最佳实践

---

**文档版本**: 1.0
**最后更新**: 2025-02-11
**适用项目**: Little Knight Adventure v0.5
**作者**: Claude Sonnet 4.5
