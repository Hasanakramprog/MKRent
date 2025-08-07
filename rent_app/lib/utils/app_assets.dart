class AppAssets {
  // Private constructor to prevent instantiation
  AppAssets._();

  // Base paths
  static const String _imagesPath = 'assets/images';
  static const String _logosPath = '$_imagesPath/logos';
  static const String _iconsPath = '$_imagesPath/icons';
  static const String _placeholdersPath = '$_imagesPath/placeholders';
  static const String _backgroundsPath = '$_imagesPath/backgrounds';

  // Logos
  static const String logo = '$_logosPath/logo.svg';
  static const String logoSmall = '$_logosPath/logo_small.svg';

  // Icons
  static const String cameraIcon = '$_iconsPath/camera_icon.svg';
  static const String rentalIcon = '$_iconsPath/rental_icon.svg';
  static const String bookingIcon = '$_iconsPath/booking_icon.svg';

  // Placeholders
  static const String productPlaceholder = '$_placeholdersPath/product_placeholder.svg';
  static const String userPlaceholder = '$_placeholdersPath/user_placeholder.svg';
  static const String noImage = '$_placeholdersPath/no_image.svg';

  // Backgrounds
  static const String gradientBg = '$_backgroundsPath/gradient_bg.svg';

  // Helper method to get all asset paths (useful for preloading)
  static List<String> getAllAssets() {
    return [
      logo,
      logoSmall,
      cameraIcon,
      rentalIcon,
      bookingIcon,
      productPlaceholder,
      userPlaceholder,
      noImage,
      gradientBg,
    ];
  }

  // Helper method to check if an asset exists (for debugging)
  static bool isValidAsset(String assetPath) {
    return getAllAssets().contains(assetPath);
  }
}
