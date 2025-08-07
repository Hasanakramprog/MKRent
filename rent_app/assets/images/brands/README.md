# Brand Logo Images

Place your brand logo images in this folder. The recommended format and naming:

## Required Brand Images:
- `canon.png` - Canon camera brand logo
- `nikon.png` - Nikon camera brand logo  
- `sony.png` - Sony camera brand logo
- `fujifilm.png` - Fujifilm camera brand logo
- `panasonic.png` - Panasonic camera brand logo
- `olympus.png` - Olympus camera brand logo
- `leica.png` - Leica camera brand logo
- `pentax.png` - Pentax camera brand logo

## Image Guidelines:
- **Format:** PNG (preferred for transparency) or JPEG
- **Size:** 100x100px to 200x200px recommended
- **Background:** Transparent PNG or white background
- **Style:** Clean, recognizable brand logos
- **Naming:** lowercase with no spaces (use underscores if needed)

## How to Add Your Images:
1. Save your brand logo images in this folder
2. Make sure the filenames match exactly what's in the code:
   - `canon.png`, `nikon.png`, `sony.png`, etc.
3. The app will automatically display them in the brand slider

## Adding New Brands:
To add more brands, update the `brands` list in `lib/widgets/brand_slider.dart`:

```dart
static const List<Map<String, String>> brands = [
  {'name': 'Canon', 'logo': 'assets/images/brands/canon.png'},
  {'name': 'Your Brand', 'logo': 'assets/images/brands/your_brand.png'},
  // Add more brands here
];
```

## Current Status:
The brand slider is now configured to use regular image files instead of SVG.
The widget includes error handling - if an image is missing, it will show a camera icon as fallback.
