import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class FirebaseDataInitializer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize sample products in Firebase
  static Future<void> initializeSampleProducts() async {
    try {
      print('Initializing sample products in Firebase...');

      // Sample products data
      final sampleProducts = [
        Product(
          id: 'prod_001',
          name: 'Canon EOS R5',
          description: 'Professional mirrorless camera with 45MP full-frame sensor',
          price: 89.0,
          imageUrl: 'https://images.unsplash.com/photo-1606983340126-99ab4feaa64a?w=400',
          category: 'Mirrorless Camera',
          tags: ['professional', 'full-frame', '45mp', '8k-video'],
          specifications: ['45MP Full-Frame Sensor', '8K Video Recording', 'Dual Memory Card Slots', 'Weather Sealed'],
          rating: 4.9,
          ownerId: 'sample_store_001',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Product(
          id: 'prod_002',
          name: 'Sony A7 III',
          description: 'Versatile full-frame camera perfect for photography and video',
          price: 69.0,
          imageUrl: 'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=400',
          category: 'Mirrorless Camera',
          tags: ['versatile', 'full-frame', 'hybrid', 'professional'],
          specifications: ['24.2MP Full-Frame Sensor', '4K Video', '693 Phase Detection AF Points', '10fps Continuous Shooting'],
          rating: 4.8,
          ownerId: 'sample_store_001',
          createdAt: DateTime.now().subtract(const Duration(days: 25)),
        ),
        Product(
          id: 'prod_003',
          name: 'Canon 70-200mm f/2.8',
          description: 'Professional telephoto zoom lens with image stabilization',
          price: 45.0,
          imageUrl: 'https://images.unsplash.com/photo-1606983340075-85db8e830f80?w=400',
          category: 'Lens',
          tags: ['telephoto', 'professional', 'zoom', 'stabilized'],
          specifications: ['70-200mm Focal Length', 'f/2.8 Constant Aperture', 'Image Stabilization', 'Weather Sealed'],
          rating: 4.9,
          isAvailable: false,
          ownerId: 'sample_store_002',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
        Product(
          id: 'prod_004',
          name: 'DJI Ronin-S',
          description: 'Professional 3-axis gimbal stabilizer for DSLR cameras',
          price: 35.0,
          imageUrl: 'https://images.unsplash.com/photo-1551431009-a802eeec77b1?w=400',
          category: 'Accessories',
          tags: ['stabilizer', '3-axis', 'professional', 'smooth'],
          specifications: ['3-Axis Stabilization', '12-Hour Battery Life', 'Wireless Control', 'Creative Shooting Modes'],
          rating: 4.7,
          ownerId: 'sample_store_001',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
        Product(
          id: 'prod_005',
          name: 'Nikon D850',
          description: 'High-resolution DSLR camera with 45.7MP sensor',
          price: 79.0,
          imageUrl: 'https://images.unsplash.com/photo-1612198188060-c7c2a3b66eae?w=400',
          category: 'DSLR Camera',
          tags: ['high-resolution', '45mp', 'professional', 'dslr'],
          specifications: ['45.7MP Full-Frame Sensor', '4K UHD Video', '153-Point AF System', 'Weather Sealed'],
          rating: 4.8,
          ownerId: 'sample_store_002',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        Product(
          id: 'prod_006',
          name: 'Godox AD600Pro',
          description: 'Portable studio flash with wireless control',
          price: 55.0,
          imageUrl: 'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?w=400',
          category: 'Lighting',
          tags: ['flash', 'studio', 'portable', 'wireless'],
          specifications: ['600Ws Power Output', 'Wireless TTL Control', 'Fast Recycling Time', 'Built-in Receiver'],
          rating: 4.6,
          isAvailable: false,
          ownerId: 'sample_store_003',
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
        ),
        Product(
          id: 'prod_007',
          name: 'Sony FX3',
          description: 'Compact cinema camera with professional video features',
          price: 99.0,
          imageUrl: 'https://images.unsplash.com/photo-1617005082133-548c4dd27ed4?w=400',
          category: 'Cinema',
          tags: ['cinema', 'compact', 'professional', '4k'],
          rating: 4.9,
          ownerId: 'sample_store_001',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Product(
          id: 'prod_008',
          name: 'Peak Design Tripod',
          description: 'Ultra-portable carbon fiber tripod for travel photography',
          price: 25.0,
          imageUrl: 'https://images.unsplash.com/photo-1563474396536-a0b1e2a99d60?w=400',
          category: 'Accessories',
          tags: ['portable', 'carbon-fiber', 'travel', 'lightweight'],
          rating: 4.7,
          ownerId: 'sample_store_002',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];

      // Add products to Firebase
      for (var product in sampleProducts) {
        await _firestore.collection('products').doc(product.id).set(product.toMap());
        print('Added product: ${product.name}');
      }

      print('✅ Sample products initialized successfully!');
    } catch (e) {
      print('❌ Error initializing sample products: $e');
    }
  }

  // Call this method once to populate your Firebase with sample data
  static Future<void> setupInitialData() async {
    await initializeSampleProducts();
  }
}
