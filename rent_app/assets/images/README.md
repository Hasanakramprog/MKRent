# RentApp Image Assets

This folder contains all image assets for the RentApp project.

## Folder Structure:

### `/icons/`
- App icons, UI icons, and small graphical elements
- Format: PNG, SVG preferred
- Sizes: 24x24, 48x48, 96x96 for different screen densities

### `/logos/`
- App logo, brand elements
- Format: PNG, SVG
- Include different sizes: logo.png, logo_small.png, logo_large.png

### `/placeholders/`
- Placeholder images for products, users, etc.
- Default images when no content is available
- Format: PNG, JPEG

### `/backgrounds/`
- Background images, gradients, patterns
- Format: PNG, JPEG
- Consider different screen sizes

## Image Guidelines:

1. **Naming Convention:**
   - Use lowercase with underscores: `camera_icon.png`
   - Include size if multiple versions: `logo_24.png`, `logo_48.png`
   - Use descriptive names: `product_placeholder.png`

2. **Optimization:**
   - Compress images to reduce app size
   - Use appropriate formats (PNG for transparency, JPEG for photos)
   - Consider using vector formats (SVG) when possible

3. **Screen Densities:**
   - Provide multiple densities: 1x, 2x, 3x
   - Flutter automatically selects appropriate density

## Usage in Code:
```dart
// Loading from assets
Image.asset('assets/images/logos/logo.png')

// With size specification
Image.asset(
  'assets/images/icons/camera_icon.png',
  width: 24,
  height: 24,
)
```
