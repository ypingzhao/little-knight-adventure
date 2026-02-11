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
        script_file = uid_file.with_suffix('')  # 去掉 .uid 后缀
        script_path = "res://" + script_file.relative_to(project_root).as_posix()

        # 在场景文件中查找引用
        for scene_file in scenes_dir.rglob("*.tscn"):
            try:
                with open(scene_file, 'r', encoding='utf-8') as f:
                    content = f.read()

                # 查找包含该脚本的行
                if script_path in content:
                    lines = content.split('\n')
                    modified = False

                    for i, line in enumerate(lines):
                        # 匹配：[ext_resource type="Script" uid="..." path="res://scripts/..."]
                        if 'type="Script"' in line and script_path in line:
                            # 提取当前UID
                            uid_match = re.search(r'uid="([^"]*)"', line)
                            if uid_match:
                                current_uid = uid_match.group(1)

                                if current_uid != correct_uid:
                                    # 替换UID
                                    old_line = line
                                    line = line.replace(f'uid="{current_uid}"', f'uid="{correct_uid}"')
                                    lines[i] = line
                                    modified = True

                                    print(f"  ✓ {scene_file.name}")
                                    print(f"    脚本: {script_path}")
                                    print(f"    旧UID: {current_uid}")
                                    print(f"    新UID: {correct_uid}")

                    if modified:
                        # 写回文件
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
