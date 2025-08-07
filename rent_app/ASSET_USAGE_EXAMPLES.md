# Asset Usage Examples

Here are some examples of how to use the new image assets in your RentApp:

## 1. App Logo in App Bar:
```dart
AppBar(
  title: Row(
    children: [
      AppLogo(size: 32),
      SizedBox(width: 8),
      Text('RentApp'),
    ],
  ),
)
```

## 2. Custom Icons in Navigation:
```dart
FloatingActionButton(
  onPressed: () => Navigator.pushNamed(context, '/rental-booking'),
  child: AppIcon(
    iconName: 'booking',
    size: 28,
    color: Colors.black,
  ),
)
```

## 3. Enhanced Product Cards:
```dart
CachedNetworkImage(
  imageUrl: product.imageUrl,
  placeholder: (context, url) => ProductPlaceholder(
    width: double.infinity,
    height: 200,
  ),
  errorWidget: (context, url, error) => ProductPlaceholder(
    width: double.infinity,
    height: 200,
  ),
)
```

## 4. User Profile with Avatar:
```dart
ListTile(
  leading: UserAvatar(
    size: 50,
    imageUrl: user.profileImageUrl,
  ),
  title: Text(user.name),
  subtitle: Text(user.email),
)
```

## 5. Category Icons:
```dart
Column(
  children: [
    AppIcon(
      iconName: 'camera',
      size: 32,
    ),
    Text('Cameras'),
  ],
)
```

## 6. Loading States:
```dart
FutureBuilder<Product>(
  future: ProductService.getProduct(id),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return ProductPlaceholder(width: 200, height: 150);
    }
    
    if (snapshot.hasError) {
      return AssetImageWidget(
        assetPath: AppAssets.noImage,
        width: 200,
        height: 150,
      );
    }
    
    return ProductImage(product: snapshot.data!);
  },
)
```

## 7. Background with Pattern:
```dart
Container(
  decoration: BoxDecoration(
    image: DecorationImage(
      image: AssetImage(AppAssets.gradientBg),
      fit: BoxFit.cover,
    ),
  ),
  child: YourContent(),
)
```

## 8. Splash Screen Logo:
```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      AppLogo(size: 120),
      SizedBox(height: 20),
      CircularProgressIndicator(
        color: Color(0xFFFFD700),
      ),
    ],
  ),
)
```
