#!/usr/bin/env python3
"""
Process app icon and generate all required sizes
Usage: python3 process_icon.py <input_icon> <build_dir> <app_name>
"""

import sys
from PIL import Image
import os

def process_icon(input_path, build_dir, app_name):
    """Process icon and generate all required sizes for the app"""
    
    # 打开图片
    img = Image.open(input_path)
    width, height = img.size
    
    # 计算正方形的边长（取较小的一边）
    size = min(width, height)
    
    # 计算裁剪区域（居中裁剪）
    left = (width - size) // 2
    top = (height - size) // 2
    right = left + size
    bottom = top + size
    
    # 裁剪为正方形
    img_square = img.crop((left, top, right, bottom))
    
    # 定义需要的尺寸
    icon_sizes = [
        (16, 16, ""),
        (16, 16, "@2x"),
        (32, 32, ""),
        (32, 32, "@2x"),
        (128, 128, ""),
        (128, 128, "@2x"),
        (256, 256, ""),
        (256, 256, "@2x"),
        (512, 512, ""),
        (512, 512, "@2x"),
    ]
    
    # 更新两个app的图标
    for app_dir in [f"{build_dir}/{app_name}.app", f"{build_dir}/dmg/{app_name}.app"]:
        iconset_dir = f"{app_dir}/Contents/Resources/AppIcon.iconset"
        os.makedirs(iconset_dir, exist_ok=True)
        
        for w, h, suffix in icon_sizes:
            if suffix:
                output_name = f"icon_{w}x{h}{suffix}.png"
            else:
                output_name = f"icon_{w}x{h}.png"
            
            resized = img_square.resize((w, h), Image.Resampling.LANCZOS)
            output_path = os.path.join(iconset_dir, output_name)
            resized.save(output_path, "PNG")
        
        print(f"   ✓ Icons updated: {app_dir}")
    
    print("   ✓ Icon processing complete!")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 process_icon.py <input_icon> <build_dir> <app_name>")
        sys.exit(1)
    
    input_path = sys.argv[1]
    build_dir = sys.argv[2]
    app_name = sys.argv[3]
    
    process_icon(input_path, build_dir, app_name)
