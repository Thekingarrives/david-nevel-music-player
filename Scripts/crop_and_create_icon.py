from PIL import Image
import os

# 读取文件夹中的 icon.png
icon_path = "icon.png"
if not os.path.exists(icon_path):
    print("Error: icon.png not found!")
    exit(1)

img = Image.open(icon_path).convert("RGBA")

# 获取图片尺寸
width, height = img.size
print(f"Original image size: {width}x{height}")

# 裁切成正方形（取中心区域）
min_dim = min(width, height)
left = (width - min_dim) // 2
top = (height - min_dim) // 2
right = left + min_dim
bottom = top + min_dim

cropped = img.crop((left, top, right, bottom))
print(f"Cropped to square: {min_dim}x{min_dim}")

# 保存裁切后的图片
cropped.save("icon_cropped.png")
print("Saved cropped image as icon_cropped.png")

# 创建图标尺寸列表
sizes = [16, 32, 128, 256, 512, 1024]
iconset_path = "SimpleMusicPlayer.app/Contents/Resources/AppIcon.iconset"
os.makedirs(iconset_path, exist_ok=True)

for size in sizes:
    # 调整图片大小
    resized = cropped.resize((size, size), Image.LANCZOS)
    
    # 保存各种尺寸
    if size <= 512:
        resized.save(f"{iconset_path}/icon_{size}x{size}.png")
        if size <= 256:
            resized2 = cropped.resize((size*2, size*2), Image.LANCZOS)
            resized2.save(f"{iconset_path}/icon_{size}x{size}@2x.png")
    else:
        resized.save(f"{iconset_path}/icon_{size}x{size}.png")

print("Icon set created from cropped image successfully!")
