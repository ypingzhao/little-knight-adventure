shader_type canvas_item;

// 网格参数
uniform int grid_x : hint_range(1, 10) = 3;
uniform int grid_y : hint_range(1, 10) = 3;
// 内缩百分比 (0.0 到 1.0)
uniform float padding : hint_range(0.0, 1.0) = 0.3;
// 颜色纹理 - 用来存储每个格子的颜色
uniform sampler2D color_texture : filter_nearest;
// 闪烁持续时间（秒）
uniform float duration : hint_range(0.1, 5.0) = 1.0;
// 透明度
uniform float alpha : hint_range(0.0, 1.0) = 0.8;

void fragment() {
    vec2 uv = UV;

    // 计算当前像素属于哪个网格
    vec2 grid_size = vec2(1.0 / float(grid_x), 1.0 / float(grid_y));
    vec2 grid_pos = floor(uv / grid_size);

    // 计算在当前网格内的相对位置 (0.0 到 1.0)
    vec2 local_uv = mod(uv, grid_size) / grid_size;

    // 应用内缩 (padding)
    vec2 padded_min = vec2(padding * 0.5);
    vec2 padded_max = vec2(1.0 - padding * 0.5);

    // 检查当前像素是否在内缩后的区域内
    bool in_padded_area = local_uv.x >= padded_min.x && local_uv.x <= padded_max.x &&
                         local_uv.y >= padded_min.y && local_uv.y <= padded_max.y;

    if (in_padded_area) {
        // 计算颜色纹理的UV坐标
        // 将网格位置映射到颜色纹理的像素位置
        vec2 color_uv = (grid_pos + vec2(0.5)) / vec2(float(grid_x), float(grid_y));

        // 从颜色纹理中获取当前格子的颜色
        vec4 grid_color = texture(color_texture, color_uv);

        // 计算闪烁效果
        float time_cycle = mod(TIME, duration);
        float flash_intensity = sin(time_cycle * 2.0 * PI / duration) * 0.5 + 0.5;

        // 应用闪烁颜色
        COLOR = vec4(grid_color.rgb, grid_color.a * flash_intensity * alpha);
    } else {
        // 透明区域
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    }
}