#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFilter
import math

# 创建1024x1024的图标
size = 1024
img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# 圆角矩形背景
radius = 200
bg_color = (120, 180, 100, 255)  # 浅绿色
shadow_color = (80, 140, 60, 255)  # 深绿色阴影

# 绘制圆角矩形
def draw_rounded_rect(draw, xy, radius, fill):
    x1, y1, x2, y2 = xy
    draw.rounded_rectangle(xy, radius=radius, fill=fill)

# 主背景
draw.rounded_rectangle([20, 20, size-20, size-20], radius=radius, fill=bg_color)

# 添加一些纹理效果
for i in range(0, size, 4):
    alpha = 15
    draw.line([(i, 0), (i, size)], fill=(255, 255, 255, alpha), width=1)
    draw.line([(0, i), (size, i)], fill=(255, 255, 255, alpha), width=1)

# 绘制音乐符号
note_color = (60, 100, 50, 255)  # 深绿色音符

# 音符主体位置
center_x = size // 2
center_y = size // 2 + 50

# 绘制音符的两个圆（符头）
head_radius = 90
left_head_x = center_x - 120
right_head_x = center_x + 80
head_y = center_y + 100

# 左符头
draw.ellipse([left_head_x - head_radius, head_y - head_radius, 
              left_head_x + head_radius, head_y + head_radius], fill=note_color)

# 右符头
draw.ellipse([right_head_x - head_radius, head_y - head_radius, 
              right_head_x + head_radius, head_y + head_radius], fill=note_color)

# 绘制符干
stem_width = 50
stem_height = 350
stem_x = right_head_x + head_radius - 20
stem_top = head_y - stem_height

draw.rectangle([stem_x, stem_top, stem_x + stem_width, head_y + head_radius - 20], fill=note_color)

# 绘制符尾（旗帜）
flag_start = stem_top
flag_width = 180
flag_height = 120
draw.polygon([
    (stem_x + stem_width, flag_start),
    (stem_x + stem_width + flag_width, flag_start + flag_height),
    (stem_x + stem_width, flag_start + flag_height)
], fill=note_color)

# 绘制连接两个符头的横梁
beam_height = 40
beam_y = stem_top + 80
draw.rectangle([left_head_x, beam_y, stem_x + stem_width, beam_y + beam_height], fill=note_color)

# 保存图标
img.save('001.png', 'PNG')
print("图标已保存: 001.png")
