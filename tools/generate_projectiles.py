import os
import numpy as np
from PIL import Image

src_dir = r'c:\code\Vector-Nova\docs\assets\projectiles'
dst_dir = r'c:\code\Vector-Nova\assets\sprites\projectiles'
os.makedirs(dst_dir, exist_ok=True)

files = [f for f in os.listdir(src_dir) if f.endswith('.jpg')]

for f in files:
    name_base = os.path.splitext(f)[0]
    safe_name = name_base.replace('-', '_') + '.png'
    src_path = os.path.join(src_dir, f)
    dst_path = os.path.join(dst_dir, safe_name)
    
    im = Image.open(src_path).convert('RGB')
    if im.size != (512, 512):
        im = im.resize((512, 512), Image.Resampling.LANCZOS)
    
    arr = np.array(im, dtype=np.float32)
    max_c = np.max(arr, axis=-1)
    
    alpha = np.clip((max_c - 6.0) / (255.0 - 6.0), 0.0, 1.0)
    alpha = np.power(alpha, 0.85) * 255.0
    
    alpha_norm = np.clip(alpha / 255.0, 1e-4, 1.0)[:, :, np.newaxis]
    rgb_restored = np.clip(arr / alpha_norm, 0.0, 255.0)
    
    rgba = np.zeros((512, 512, 4), dtype=np.uint8)
    rgba[:, :, :3] = np.uint8(np.round(rgb_restored))
    rgba[:, :, 3] = np.uint8(np.round(alpha))
    
    out_im = Image.fromarray(rgba, 'RGBA')
    out_im.save(dst_path, 'PNG')
    # Save standard png also in docs/assets/projectiles
    docs_png_path = os.path.join(src_dir, name_base + '.png')
    out_im.save(docs_png_path, 'PNG')
    print(f'Converted {f} -> {safe_name}')

print('All projectile sprites successfully processed.')
