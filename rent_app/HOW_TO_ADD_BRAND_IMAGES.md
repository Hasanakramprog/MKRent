# How to Import Brand Images

## Step 1: Prepare Your Brand Images

You need to add 8 brand logo images to the `assets/images/brands/` folder with these exact filenames:

### Required Files:
- `canon.png`
- `nikon.png` 
- `sony.png`
- `fujifilm.png`
- `panasonic.png`
- `olympus.png`
- `leica.png`
- `pentax.png`

## Step 2: Image Requirements

### Format & Size:
- **Format:** PNG (with transparent background) or JPEG
- **Dimensions:** 100x100px to 300x300px (square images work best)
- **Background:** Transparent or white background
- **File size:** Keep under 50KB per image for best performance

### Where to Get Brand Images:
1. **Official brand websites** - Download official logos from press kits
2. **Brand media centers** - Most companies have media/press sections
3. **Create simple text logos** if official logos aren't available

## Step 3: Copy Images to Folder

1. Navigate to: `d:\coding-repo\RentAppMk\rent_app\assets\images\brands\`
2. Copy your brand images into this folder
3. Make sure filenames match exactly (case-sensitive):
   ```
   canon.png
   nikon.png
   sony.png
   fujifilm.png
   panasonic.png
   olympus.png
   leica.png
   pentax.png
   ```

## Step 4: Test in App

After adding the images:
1. Run `flutter pub get` in terminal
2. Run `flutter run` to test the app
3. The brand logos should appear in the horizontal slider

## Step 5: If Images Don't Show

If you see camera icons instead of brand logos:
- Check that filenames match exactly
- Ensure images are in the correct folder
- Verify image formats are supported (PNG/JPEG)
- Check that `flutter pub get` was run after adding images

## Example File Structure:
```
assets/
└── images/
    └── brands/
        ├── README.md
        ├── canon.png          ← Your image here
        ├── nikon.png          ← Your image here
        ├── sony.png           ← Your image here
        ├── fujifilm.png       ← Your image here
        ├── panasonic.png      ← Your image here
        ├── olympus.png        ← Your image here
        ├── leica.png          ← Your image here
        └── pentax.png         ← Your image here
```

The brand slider is ready - just add your images and run the app!
