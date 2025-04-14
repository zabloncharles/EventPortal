from PIL import Image
import os

# Sizes needed for iOS app icons
SIZES = {
    'iPhone': {
        '20pt@2x': 40,
        '20pt@3x': 60,
        '29pt@2x': 58,
        '29pt@3x': 87,
        '40pt@2x': 80,
        '40pt@3x': 120,
        '60pt@2x': 120,
        '60pt@3x': 180
    },
    'iPad': {
        '20pt': 20,
        '20pt@2x': 40,
        '29pt': 29,
        '29pt@2x': 58,
        '40pt': 40,
        '40pt@2x': 80,
        '76pt': 76,
        '76pt@2x': 152,
        '83.5pt@2x': 167
    },
    'appstore': {
        '': 1024
    }
}

def resize_icon(image_path, output_dir):
    # Open the original image
    img = Image.open(image_path)
    
    # Create output directory if it doesn't exist
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # Generate iPhone icons
    for name, size in SIZES['iPhone'].items():
        resized = img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(os.path.join(output_dir, f'iPhone_{name}.png'))
    
    # Generate iPad icons
    for name, size in SIZES['iPad'].items():
        resized = img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(os.path.join(output_dir, f'iPad_{name}.png'))
    
    # Generate App Store icon
    resized = img.resize((1024, 1024), Image.Resampling.LANCZOS)
    resized.save(os.path.join(output_dir, 'appstore.png'))

if __name__ == '__main__':
    # Get the directory of this script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Set paths
    icon_path = os.path.join(script_dir, 'original_icon.png')
    output_dir = os.path.join(script_dir, 'EventAppPortal/Assets.xcassets/AppIcon.appiconset')
    
    # Resize icons
    resize_icon(icon_path, output_dir) 