import os
from PIL import Image

def generate_app_images():
    source_path = 'assets/orbit_logo_nobg.png'
    app_images_dir = 'assets/AppImages'

    if not os.path.exists(source_path):
        print(f"Error: Source {source_path} not found.")
        return

    print(f"Loading master mascot logo: {source_path}...")
    master = Image.open(source_path).convert('RGBA')
    bbox = master.getbbox()
    cropped = master.crop(bbox)
    print(f"Cropped logo size: {cropped.size}")

    updated_count = 0

    for root, dirs, files in os.walk(app_images_dir):
        for file in files:
            if not file.lower().endswith('.png'):
                continue

            target_path = os.path.join(root, file)
            
            with Image.open(target_path) as current_img:
                target_w, target_h = current_img.size

            # For square icons, 85% fit gives nice padding
            # For wide splash/wide tiles, 75-80% height fit
            fit_ratio = 0.85
            if target_w / target_h > 1.5:
                # Wide banner / splash
                fit_ratio = 0.75

            max_w = int(target_w * fit_ratio)
            max_h = int(target_h * fit_ratio)

            scale = min(max_w / cropped.width, max_h / cropped.height)
            new_w = max(1, int(cropped.width * scale))
            new_h = max(1, int(cropped.height * scale))

            resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)

            canvas = Image.new('RGBA', (target_w, target_h), (0, 0, 0, 0))
            offset_x = (target_w - new_w) // 2
            offset_y = (target_h - new_h) // 2

            canvas.paste(resized, (offset_x, offset_y), resized)
            canvas.save(target_path, format='PNG', optimize=True)

            updated_count += 1
            if updated_count % 20 == 0 or updated_count == 112:
                print(f"Generated {updated_count}/112 icons... (latest: {file} {target_w}x{target_h})")

    print(f"\n[DONE] Successfully regenerated all {updated_count} AppImages with the new Cosmic Otter logo!")

if __name__ == '__main__':
    generate_app_images()
