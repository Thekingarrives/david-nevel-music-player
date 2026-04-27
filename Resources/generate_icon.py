#!/usr/bin/env python3
"""
Generate a beautiful music player app icon
"""

from PIL import Image, ImageDraw, ImageFilter
import math

def create_music_icon(size=1024):
    """Create a beautiful music note icon"""
    
    # Create base image with transparency
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors - using a beautiful gradient from teal to blue
    bg_color_start = (41, 128, 185)  # Nice blue
    bg_color_end = (52, 152, 219)    # Lighter blue
    note_color = (255, 255, 255, 240)  # White with slight transparency
    
    # Create rounded rectangle background with gradient effect
    corner_radius = size // 5
    padding = size // 20
    
    # Draw main background
    def draw_rounded_rect(draw, xy, radius, fill):
        x1, y1, x2, y2 = xy
        draw.rounded_rectangle(xy, radius=radius, fill=fill)
    
    # Main background - beautiful blue gradient effect
    bg_rect = [padding, padding, size - padding, size - padding]
    draw.rounded_rectangle(bg_rect, radius=corner_radius, fill=bg_color_start)
    
    # Add subtle inner highlight
    highlight_padding = padding + size // 40
    highlight_rect = [
        highlight_padding, 
        highlight_padding, 
        size - highlight_padding, 
        size // 2
    ]
    draw.rounded_rectangle(
        highlight_rect, 
        radius=corner_radius - size // 40, 
        fill=(255, 255, 255, 30)
    )
    
    # Draw music note
    note_size = size * 0.6
    note_x = size // 2
    note_y = size // 2 + size // 30
    
    # Note head (the round part at bottom)
    head_radius = int(note_size * 0.18)
    head_x = int(note_x - note_size * 0.15)
    head_y = int(note_y + note_size * 0.25)
    
    # Draw note head with shadow
    shadow_offset = size // 60
    draw.ellipse([
        head_x - head_radius + shadow_offset,
        head_y - head_radius + shadow_offset,
        head_x + head_radius + shadow_offset,
        head_y + head_radius + shadow_offset
    ], fill=(0, 0, 0, 50))
    
    draw.ellipse([
        head_x - head_radius,
        head_y - head_radius,
        head_x + head_radius,
        head_y + head_radius
    ], fill=note_color)
    
    # Note stem (vertical line)
    stem_width = int(note_size * 0.08)
    stem_height = int(note_size * 0.55)
    stem_x = head_x + head_radius - stem_width // 2
    stem_top = head_y - stem_height
    
    # Draw stem with slight curve effect
    draw.rounded_rectangle([
        stem_x,
        stem_top,
        stem_x + stem_width,
        head_y + head_radius // 2
    ], radius=stem_width // 2, fill=note_color)
    
    # Note flag (the curved part at top)
    flag_width = int(note_size * 0.35)
    flag_height = int(note_size * 0.25)
    flag_start_y = stem_top
    
    # Draw flag as a curved shape
    flag_points = [
        (stem_x + stem_width, flag_start_y),
        (stem_x + stem_width + flag_width, flag_start_y + flag_height),
        (stem_x + stem_width, flag_start_y + flag_height),
    ]
    draw.polygon(flag_points, fill=note_color)
    
    # Add subtle shadow to flag
    shadow_points = [
        (stem_x + stem_width + shadow_offset//2, flag_start_y + shadow_offset//2),
        (stem_x + stem_width + flag_width + shadow_offset//2, flag_start_y + flag_height + shadow_offset//2),
        (stem_x + stem_width + shadow_offset//2, flag_start_y + flag_height + shadow_offset//2),
    ]
    draw.polygon(shadow_points, fill=(0, 0, 0, 30))
    
    # Add glossy effect at top
    gloss_rect = [
        padding + size // 15,
        padding + size // 15,
        size - padding - size // 15,
        size // 3
    ]
    draw.rounded_rectangle(
        gloss_rect,
        radius=corner_radius - size // 20,
        fill=(255, 255, 255, 40)
    )
    
    return img

if __name__ == "__main__":
    # Generate icon
    icon = create_music_icon(1024)
    
    # Save as PNG
    output_path = "/Users/macminim2/Desktop/确实可用在用的mac app/第3版/Resources/AppIcon.png"
    icon.save(output_path, "PNG")
    print(f"✅ Icon generated: {output_path}")
