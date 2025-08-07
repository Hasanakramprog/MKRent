import '../models/product.dart';
import '../models/rental.dart';
import '../services/product_service.dart';
import '../services/rental_service.dart';

// Legacy compatibility layer for existing code
class ProductManager {
  static Future<List<Product>> getAllProducts() async {
    return await ProductService.getAllProducts();
  }

  static Future<Product?> getProductById(String id) async {
    return await ProductService.getProductById(id);
  }

  static Future<List<Product>> getProductsByCategory(String category) async {
    return await ProductService.getProductsByCategory(category);
  }

  static Future<List<Product>> searchProducts(String query) async {
    return await ProductService.searchProducts(query);
  }

  static Future<List<Product>> getAvailableProducts() async {
    return await ProductService.getAllProducts();
  }

  static Future<List<String>> getCategories() async {
    return await ProductService.getCategories();
  }
}

class RentalManager {
  static Future<bool> createRentalRequest(RentalRequest rental) async {
    return await RentalService.createRentalRequest(rental);
  }

  static Future<List<RentalRequest>> getUserRentals(String userId) async {
    return await RentalService.getUserRentals(userId);
  }

  static Future<List<RentalRequest>> getStoreRentals(String ownerId) async {
    return await RentalService.getStoreRentals(ownerId);
  }

  static Future<bool> updateRentalStatus({
    required String rentalId,
    required RentalStatus status,
    String? storeResponse,
    String? rejectionReason,
  }) async {
    return await RentalService.updateRentalStatus(
      rentalId: rentalId,
      status: status,
      storeResponse: storeResponse,
      rejectionReason: rejectionReason,
    );
  }

  static Future<List<RentalRequest>> getPendingRentals(String ownerId) async {
    return await RentalService.getPendingRentals(ownerId);
  }

  // Legacy method for backward compatibility
  static void initializeSampleData() {
    // This is now handled by Firebase
    print('Sample data initialization moved to Firebase');
  }
}
