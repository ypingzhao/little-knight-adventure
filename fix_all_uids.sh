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
