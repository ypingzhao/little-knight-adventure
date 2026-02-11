shader_type canvas_item;

// 过渡控制参数
uniform bool is_active = false; // 过渡方向开关
uniform float progress : hint_range(0.0, 1.0) = 0.0; // 过渡进度

// 颜色参数
uniform vec4 transition_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // 过渡颜色
uniform vec4 clear_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // 消失颜色
uniform vec4 edge_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // 边缘颜色
uniform float edge_width : hint_range(0.0, 0.5) = 0.05; // 边缘宽度

// 视觉效果参数
uniform float pixel_size : hint_range(1.0, 500.0) = 100.0; // 像素化程度
uniform float noise_strength : hint_range(0.0, 1.0) = 0.5; // 噪声强度

// 几何参数
uniform vec2 center_point = vec2(0.5, 0.5); // 中心点位置
uniform vec2 screen_size = vec2(1920.0, 1080.0); // 屏幕尺寸

// 简单的2D噪声函数
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    // 1. 像素化处理
    vec2 pixelated_uv = floor(UV * pixel_size) / pixel_size;

    // 2. 噪声生成
    float noise = random(pixelated_uv) * noise_strength;

    // 3. 宽高比校正
    float aspect_ratio = screen_size.x / screen_size.y;
    vec2 corrected_uv = vec2(UV.x * aspect_ratio, UV.y);
    vec2 corrected_center = vec2(center_point.x * aspect_ratio, center_point.y);

    // 4. 距离计算与归一化
    float dist = distance(corrected_uv, corrected_center);

    // 计算最远角落
    vec2 corner = vec2(
        corrected_center.x < aspect_ratio * 0.5 ? aspect_ratio : 0.0,
        corrected_center.y < 0.5 ? 1.0 : 0.0
    );

    float max_dist = distance(corrected_center, corner);
    dist = dist / max_dist + noise * 0.1;

    // 5. 边缘效果计算
    float edge_start = progress - edge_width;
    float edge_end = progress;
    float edge_blend = smoothstep(edge_start, edge_end, dist);

    // 6. 应用过渡效果
    if (progress >= 0.99) {
        // 完全过渡情况
        if (is_active) {
            COLOR = transition_color;
        } else {
            COLOR = clear_color;
        }
    } else if (is_active) {
        // 向外扩散效果
        if (dist < edge_start) {
            COLOR = transition_color;
        } else if (dist < edge_end) {
            COLOR = mix(transition_color, edge_color, edge_blend);
        } else {
            COLOR = clear_color;
        }
    } else {
        // 向内收缩效果
        if (dist < edge_start) {
            COLOR = clear_color;
        } else if (dist < edge_end) {
            COLOR = mix(clear_color, edge_color, edge_blend);
        } else {
            COLOR = transition_color;
        }
    }
}