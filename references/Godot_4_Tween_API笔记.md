# Godot 4.x Tween API 注意事项

## 常见错误

### ❌ 错误方法名
```gdscript
# 错误：set_looped() - 不存在此方法
tween.set_looped()
# 错误：set_loop() - 不存在此方法
tween.set_loop()
```

### ✅ 正确方法名
```gdscript
# 正确：set_loops() - 设置循环（有 s）
tween.set_loops()
```

## Godot 4.x Tween 正确用法

### 基础循环 Tween
```gdscript
func _start_float_animation() -> void:
    var float_tween = create_tween()
    float_tween.set_loops()  # 正确的方法名（有 s）
    float_tween.set_ease(Tween.EASE_IN_OUT)
    float_tween.set_trans(Tween.TRANS_SINE)

    # 添加动画属性
    float_tween.tween_property(self, "global_position:y", target_y, duration)
```

### 链式调用
```gdscript
var tween = create_tween()
tween.set_loops().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
```

## 完整示例：Checkpoint Lamp 浮动动画

```gdscript
extends Node2D

var original_y: float
var float_range: float

func _start_float_animation() -> void:
    var float_tween = create_tween()
    float_tween.set_loops().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

    # 向上浮动
    float_tween.tween_property(self, "global_position:y", original_y - 16 - float_range, 1.0)
    float_tween.tween_property(self, "global_position:y", original_y - 16, 1.0)
```

## Tween 缓动类型参考

### EASE 类型
- `Tween.EASE_IN` - 渐入
- `Tween.EASE_OUT` - 渐出
- `Tween.EASE_IN_OUT` - 渐入渐出
- `Tween.EASE_OUT_IN` - 渐出渐入

### TRANS 类型
- `Tween.TRANS_LINEAR` - 线性
- `Tween.TRANS_SINE` - 正弦曲线（平滑）
- `Tween.TRANS_QUINT` - 五次方曲线
- `Tween.TRANS_QUART` - 四次方曲线
- `Tween.TRANS_BACK` - 回弹效果
- `Tween.TRANS_ELASTIC` - 弹性效果

## 重要提醒

1. **方法名是 `set_loop()` 不是 `set_looped()`**
2. 在 Godot 4.x 中，Tween 使用方式与 Godot 3.x 完全不同
3. 使用 `create_tween()` 创建 Tween 对象
4. 使用 `tween_property()` 添加动画属性
5. 链式调用时注意顺序：先设置循环，再设置缓动和过渡

## 相关文档链接
- [Godot 4.x Tween 官方文档](https://docs.godotengine.org/en/stable/classes/class_tween.html)
- [Tweening 教程](https://docs.godotengine.org/en/stable/tutorials/tweens.html)
