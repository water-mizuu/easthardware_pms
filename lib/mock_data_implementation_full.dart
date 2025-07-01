// This is a complete implementation of the mock data for the East Hardware PMS system
// with configurable number of invoices, orders, and products
//
// UPDATED TO MATCH MODEL STRUCTURE:
// - Fixed DiscountType handling to only set when discount exists
// - Fixed payment method IDs to use actual database IDs instead of indices
// - Fixed expense type creation to avoid null values
// - Properly structured date handling for different models
// - Added proper model relationships and foreign key constraints

import 'dart:math';

import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/expense_type.dart' as model;
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/invoice_product.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/order_item.dart';
import 'package:easthardware_pms/domain/models/order_product.dart';
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/domain/models/security_question.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/repository/category_repository.dart';
import 'package:easthardware_pms/domain/repository/expense_type_repository.dart';
import 'package:easthardware_pms/domain/repository/invoice_product_repository.dart';
import 'package:easthardware_pms/domain/repository/invoice_repository.dart';
import 'package:easthardware_pms/domain/repository/order_item_repository.dart';
import 'package:easthardware_pms/domain/repository/order_product_repository.dart';
import 'package:easthardware_pms/domain/repository/order_repository.dart';
import 'package:easthardware_pms/domain/repository/payment_method_repository.dart';
import 'package:easthardware_pms/domain/repository/product_repository.dart';
import 'package:easthardware_pms/domain/repository/security_question_repository.dart';
import 'package:easthardware_pms/domain/repository/user_repository.dart';
import 'package:easthardware_pms/domain/services/cryptography_service.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:uuid/uuid.dart';

/// The current date for the app is set to June 29, 2025
final DateTime currentDate = DateTime(2025, 6, 29);

/// Constants for configuring mock data generation
const int NUM_INVOICES = 100; // Increased from 50
const int NUM_ORDERS = 40; // Increased from 20
const int MAX_PRODUCTS = 50; // Limit products to 50
const int DAYS_IN_PAST = 180; // How far back the orders and invoices go (approximately 6 months)

/// Generate mock data with configurable number of invoices and orders
Future<void> generateMockData(DatabaseHelper databaseHelper) async {
  try {
    // Initialize repositories
    final usersRepository = UserRepository(databaseHelper);
    final securityQuestionsRepository = SecurityQuestionRepository(databaseHelper);
    final productsRepository = ProductRepository(databaseHelper);
    final categoryRepository = CategoryRepository(databaseHelper);
    final invoiceRepository = InvoiceRepository(databaseHelper);
    final invoiceProductRepository = InvoiceProductRepository(databaseHelper);
    final orderRepository = OrderRepository(databaseHelper);
    final orderProductRepository = OrderProductRepository(databaseHelper);
    final orderItemRepository = OrderItemRepository(databaseHelper);
    final expenseTypeRepository = ExpenseTypeRepository(databaseHelper);
    final paymentMethodRepository = PaymentMethodRepository(databaseHelper);

    // Get starting user ID
    var usersIdOffset = await usersRepository.getAllUsers().then((u) => u.length);

    // STEP 1: CREATE USERS AND SECURITY QUESTIONS
    const mockUsers = <({
      String firstName,
      String lastName,
      AccessLevel accessLevel,
      List<SecurityQuestion> securityQuestions
    })>[
      (
        firstName: 'John',
        lastName: 'Doe',
        accessLevel: AccessLevel.staff,
        securityQuestions: [
          SecurityQuestion(
            userId: -1,
            question: 'What is your favorite color?',
            answer: 'Blue',
          ),
          SecurityQuestion(
            userId: -1,
            question: 'What is your pet\'s name?',
            answer: 'Buddy',
          ),
          SecurityQuestion(
            userId: -1,
            question: 'What is your favorite food?',
            answer: 'Pizza',
          ),
        ],
      ),
      (
        firstName: 'Jane',
        lastName: 'Doe',
        accessLevel: AccessLevel.administrator,
        securityQuestions: [
          SecurityQuestion(
            userId: -1,
            question: 'What is your favorite color?',
            answer: 'Red',
          ),
          SecurityQuestion(
            userId: -1,
            question: 'What is your pet\'s name?',
            answer: 'Max',
          ),
          SecurityQuestion(
            userId: -1,
            question: 'What is your favorite food?',
            answer: 'Sushi',
          ),
        ],
      ),
      (
        firstName: 'Alice',
        lastName: 'Smith',
        accessLevel: AccessLevel.staff,
        securityQuestions: [
          SecurityQuestion(
            userId: -1,
            question: 'What is your favorite color?',
            answer: 'Green',
          ),
          SecurityQuestion(
            userId: -1,
            question: 'What is your pet\'s name?',
            answer: 'Charlie',
          ),
          SecurityQuestion(
            userId: -1,
            question: 'What is your favorite food?',
            answer: 'Pasta',
          ),
        ],
      ),
      (
        firstName: 'Bob',
        lastName: 'Johnson',
        accessLevel: AccessLevel.administrator,
        securityQuestions: [
          SecurityQuestion(
            userId: -1,
            question: 'What is your favorite color?',
            answer: 'Yellow',
          ),
          SecurityQuestion(
            userId: -1,
            question: 'What is your pet\'s name?',
            answer: 'Rocky',
          ),
          SecurityQuestion(
            userId: -1,
            question: 'What is your favorite food?',
            answer: 'Burger',
          ),
        ],
      ),
    ];

    // Process and insert users and security questions
    final users = <User>[];
    final securityQuestions = <SecurityQuestion>[];
    var userId = usersIdOffset;

    for (final mockUser in mockUsers) {
      final salt = CryptographyService.generateSalt();
      final user = User(
        id: userId++,
        uid: const Uuid().v4(),
        firstName: mockUser.firstName,
        lastName: mockUser.lastName,
        username: '${mockUser.firstName.toLowerCase()}${mockUser.lastName.toLowerCase()}',
        accessLevel: mockUser.accessLevel,
        passwordHash: CryptographyService.generateHash(
          '${mockUser.firstName}${mockUser.lastName}123',
          salt,
        ),
        salt: salt,
        creationDate: '2022-01-01',
        archiveStatus: 0,
        loginStatus: 0,
      );

      // Process security questions
      for (final question in mockUser.securityQuestions) {
        securityQuestions.add(question.copyWith(userId: user.id!));
      }

      users.add(user);
    }

    // Insert users and questions
    for (final user in users) {
      await usersRepository.insertUser(user);
    }

    for (final question in securityQuestions) {
      await securityQuestionsRepository.addSecurityQuestion(question);
    }

    // Reset user ID offset for creator IDs
    usersIdOffset = users.isEmpty ? 0 : users.first.id!;

    // STEP 2: CREATE PRODUCT CATEGORIES
    final categories = [
      const Category(name: "Hardware Tools"),
      const Category(name: "Building Materials"),
      const Category(name: "Plumbing"),
      const Category(name: "Electrical"),
      const Category(name: "Painting Supplies"),
      const Category(name: "Safety & Security"),
      const Category(name: "Automotive"),
    ];

    final categoryIds = <int>[];
    for (final category in categories) {
      final insertedCategory = await categoryRepository.insertCategory(category);
      categoryIds.add(insertedCategory.id!);
    }

    // STEP 3: CREATE PRODUCTS (50 complete and distinct products)
    final mockProducts = [
      // Hardware Tools - 10 products
      Product(
        sku: "HT-001",
        name: "Premium Claw Hammer - 16oz",
        categoryId: categoryIds[0],
        description: "Professional 16oz claw hammer with fiberglass handle and rubber grip, "
            "perfect for general construction and household repairs. Features anti-vibration technology.",
        salePrice: 450.00,
        orderCost: 280.00,
        quantity: 35.0,
        mainUnit: "piece",
        reorderPoint: 5.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 180.0,
        fastMovingStockThreshold: 15.0,
        creationDate: "2025-05-01",
        creatorId: users[0].id!,
        archiveStatus: 0,
      ),
      Product(
        sku: "HT-002",
        name: "Professional Screwdriver Set - 10pc",
        categoryId: categoryIds[0],
        description: "10-piece professional screwdriver set with magnetic tips, ergonomic handles, "
            "and various sizes of flathead and Phillips head screwdrivers. Chrome vanadium steel shafts.",
        salePrice: 850.00,
        orderCost: 520.00,
        quantity: 20.0,
        mainUnit: "set",
        reorderPoint: 3.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 150.0,
        fastMovingStockThreshold: 8.0,
        creationDate: "2025-05-01",
        creatorId: users[0].id!,
        archiveStatus: 0,
      ),
      Product(
        sku: "HT-003",
        name: "Cordless Power Drill - 18V",
        categoryId: categoryIds[0],
        description: "Heavy-duty 18V cordless power drill with brushless motor, variable "
            "speed control, LED work light, and 2 lithium-ion batteries. Includes carrying case.",
        salePrice: 3200.00,
        orderCost: 1900.00,
        quantity: 12.0,
        mainUnit: "set",
        reorderPoint: 2.0,
        minReorderDelay: 10,
        maxReorderDelay: 14,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 4.0,
        creationDate: "2025-05-01",
        creatorId: usersIdOffset,
        archiveStatus: 0,
      ),
      Product(
        sku: "HT-004",
        name: "Adjustable Wrench Set - 3pc",
        categoryId: categoryIds[0],
        description: "Set of 3 adjustable wrenches (6\", 8\", and 10\") with chrome finish, "
            "calibrated jaws and comfortable grip handles. Perfect for plumbing and general repairs.",
        salePrice: 670.00,
        orderCost: 410.00,
        quantity: 25.0,
        mainUnit: "set",
        reorderPoint: 4.0,
        minReorderDelay: 6,
        maxReorderDelay: 12,
        deadStockThreshold: 150.0,
        fastMovingStockThreshold: 8.0,
        creationDate: "2025-05-01",
        creatorId: usersIdOffset + 1,
        archiveStatus: 0,
      ),
      Product(
        sku: "HT-005",
        name: "Laser Level - 50ft Range",
        categoryId: categoryIds[0],
        description: "Professional laser level with 50ft range, self-leveling function, "
            "cross-line projection, and magnetic mount. Includes carrying case and batteries.",
        salePrice: 1850.00,
        orderCost: 1150.00,
        quantity: 10.0,
        mainUnit: "piece",
        reorderPoint: 2.0,
        minReorderDelay: 8,
        maxReorderDelay: 15,
        deadStockThreshold: 140.0,
        fastMovingStockThreshold: 3.0,
        creationDate: "2025-05-01",
        creatorId: usersIdOffset,
        archiveStatus: 0,
      ),
      Product(
        sku: "HT-006",
        name: "Circular Saw - 7-1/4\"",
        categoryId: categoryIds[0],
        description:
            "Powerful 15-amp circular saw with 7-1/4\" blade, bevel capacity up to 56 degrees, "
            "and built-in dust blower. Includes carbide-tipped blade and edge guide.",
        salePrice: 2400.00,
        orderCost: 1500.00,
        quantity: 8.0,
        mainUnit: "piece",
        reorderPoint: 2.0,
        minReorderDelay: 10,
        maxReorderDelay: 18,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 3.0,
        creationDate: "2025-05-02",
        creatorId: usersIdOffset + 1,
        archiveStatus: 0,
      ),
      Product(
        sku: "HT-007",
        name: "Socket Wrench Set - 40pc",
        categoryId: categoryIds[0],
        description: "Complete 40-piece socket wrench set with ratchet handle, extensions, "
            "and metric/SAE sockets. Includes carrying case with molded organization.",
        salePrice: 1250.00,
        orderCost: 750.00,
        quantity: 15.0,
        mainUnit: "set",
        reorderPoint: 3.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 180.0,
        fastMovingStockThreshold: 5.0,
        creationDate: "2025-05-02",
        creatorId: usersIdOffset + 2,
        archiveStatus: 0,
      ),
      Product(
        sku: "HT-008",
        name: "Digital Caliper - 6\"",
        categoryId: categoryIds[0],
        description: "Precision 6\" digital caliper with LCD display, metric/imperial conversion, "
            "and hardened stainless steel construction. Includes battery and storage case.",
        salePrice: 780.00,
        orderCost: 450.00,
        quantity: 20.0,
        mainUnit: "piece",
        reorderPoint: 4.0,
        minReorderDelay: 8,
        maxReorderDelay: 15,
        deadStockThreshold: 200.0,
        fastMovingStockThreshold: 6.0,
        creationDate: "2025-05-02",
        creatorId: usersIdOffset + 3,
        archiveStatus: 0,
      ),
      Product(
        sku: "HT-009",
        name: "Impact Driver - 20V",
        categoryId: categoryIds[0],
        description: "High-torque 20V impact driver with brushless motor, variable speed trigger, "
            "and LED work light. Includes 2 batteries, charger, and carrying case.",
        salePrice: 2800.00,
        orderCost: 1750.00,
        quantity: 10.0,
        mainUnit: "set",
        reorderPoint: 2.0,
        minReorderDelay: 10,
        maxReorderDelay: 16,
        deadStockThreshold: 150.0,
        fastMovingStockThreshold: 3.0,
        creationDate: "2025-05-02",
        creatorId: usersIdOffset,
        archiveStatus: 0,
      ),
      Product(
        sku: "HT-010",
        name: "Utility Knife Set - 3pc",
        categoryId: categoryIds[0],
        description: "Set of 3 utility knives with quick-change blade system, retractable design, "
            "and ergonomic grip. Includes 10 replacement blades and storage pouch.",
        salePrice: 320.00,
        orderCost: 180.00,
        quantity: 40.0,
        mainUnit: "set",
        reorderPoint: 8.0,
        minReorderDelay: 5,
        maxReorderDelay: 12,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 12.0,
        creationDate: "2025-05-02",
        creatorId: usersIdOffset + 1,
        archiveStatus: 0,
      ),

      // Building Materials - 8 products
      Product(
        sku: "BM-001",
        name: "Portland Cement - 40kg",
        categoryId: categoryIds[1],
        description: "40kg bag of high-quality Portland cement, ASTM C150 certified, "
            "suitable for concrete mixing and general construction projects.",
        salePrice: 320.00,
        orderCost: 240.00,
        quantity: 150.0,
        mainUnit: "bag",
        reorderPoint: 20.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 90.0,
        fastMovingStockThreshold: 30.0,
        creationDate: "2025-05-03",
        creatorId: usersIdOffset + 2,
        archiveStatus: 0,
      ),
      Product(
        sku: "BM-002",
        name: "Washed Construction Sand - 50kg",
        categoryId: categoryIds[1],
        description:
            "50kg bag of clean, washed construction sand for concrete mixing and masonry work. "
            "Free from organic materials and properly graded for strength and consistency.",
        salePrice: 130.00,
        orderCost: 85.00,
        quantity: 200.0,
        mainUnit: "bag",
        reorderPoint: 30.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 40.0,
        creationDate: "2025-05-03",
        creatorId: usersIdOffset + 2,
        archiveStatus: 0,
      ),
      Product(
        sku: "BM-003",
        name: "Concrete Mix - Ready to Use - 25kg",
        categoryId: categoryIds[1],
        description:
            "Pre-mixed concrete in 25kg bags. Just add water for quick and easy concrete projects. "
            "Perfect for small repairs, post setting, and minor construction work.",
        salePrice: 210.00,
        orderCost: 140.00,
        quantity: 120.0,
        mainUnit: "bag",
        reorderPoint: 15.0,
        minReorderDelay: 6,
        maxReorderDelay: 12,
        deadStockThreshold: 100.0,
        fastMovingStockThreshold: 25.0,
        creationDate: "2025-05-03",
        creatorId: usersIdOffset + 3,
        archiveStatus: 0,
      ),
      Product(
        sku: "BM-004",
        name: "Construction Plywood - 4'x8'x3/4\"",
        categoryId: categoryIds[1],
        description:
            "Premium 4'x8'x3/4\" construction grade plywood, perfect for general construction, "
            "roofing, flooring, and wall sheathing. Meets building code requirements.",
        salePrice: 1450.00,
        orderCost: 950.00,
        quantity: 40.0,
        mainUnit: "sheet",
        reorderPoint: 8.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 10.0,
        creationDate: "2025-05-03",
        creatorId: usersIdOffset,
        archiveStatus: 0,
      ),
      Product(
        sku: "BM-005",
        name: "Concrete Blocks - 8\"x8\"x16\"",
        categoryId: categoryIds[1],
        description: "Standard 8\"x8\"x16\" concrete blocks for foundation walls, retaining walls, "
            "and structural applications. Meets ASTM C90 specifications.",
        salePrice: 45.00,
        orderCost: 28.00,
        quantity: 300.0,
        mainUnit: "piece",
        reorderPoint: 50.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 150.0,
        fastMovingStockThreshold: 60.0,
        creationDate: "2025-05-04",
        creatorId: usersIdOffset + 1,
        archiveStatus: 0,
      ),
      Product(
        sku: "BM-006",
        name: "Steel Reinforcement Bar - 12mm x 6m",
        categoryId: categoryIds[1],
        description:
            "12mm diameter steel reinforcement bar in 6-meter lengths. Grade 60 deformed rebar "
            "for concrete reinforcement in construction projects.",
        salePrice: 320.00,
        orderCost: 210.00,
        quantity: 80.0,
        mainUnit: "length",
        reorderPoint: 15.0,
        minReorderDelay: 8,
        maxReorderDelay: 15,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 20.0,
        creationDate: "2025-05-04",
        creatorId: usersIdOffset + 2,
        archiveStatus: 0,
      ),
      Product(
        sku: "BM-007",
        name: "Construction Adhesive - 29oz",
        categoryId: categoryIds[1],
        description: "Heavy-duty 29oz construction adhesive for bonding wood, concrete, stone, "
            "and other building materials. Waterproof and weather-resistant formula.",
        salePrice: 280.00,
        orderCost: 180.00,
        quantity: 45.0,
        mainUnit: "tube",
        reorderPoint: 8.0,
        minReorderDelay: 6,
        maxReorderDelay: 12,
        deadStockThreshold: 90.0,
        fastMovingStockThreshold: 15.0,
        creationDate: "2025-05-04",
        creatorId: usersIdOffset + 3,
        archiveStatus: 0,
      ),
      Product(
        sku: "BM-008",
        name: "Insulation Board - 4'x8'x2\"",
        categoryId: categoryIds[1],
        description: "Rigid foam insulation board, 4'x8' with 2\" thickness. R-10 value, "
            "suitable for walls, ceilings, and foundations. Moisture-resistant and easy to cut.",
        salePrice: 950.00,
        orderCost: 620.00,
        quantity: 30.0,
        mainUnit: "sheet",
        reorderPoint: 6.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 8.0,
        creationDate: "2025-05-04",
        creatorId: usersIdOffset,
        archiveStatus: 0,
      ),

      // Plumbing - 7 products
      Product(
        sku: "PL-001",
        name: "PVC Pipe - 1/2\" x 3m",
        categoryId: categoryIds[2],
        description:
            "Schedule 40 PVC pipe, 1/2\" diameter in 3-meter length for residential plumbing. "
            "Suitable for cold water supply lines and drainage applications.",
        salePrice: 95.00,
        orderCost: 60.00,
        quantity: 80.0,
        mainUnit: "length",
        reorderPoint: 10.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 100.0,
        fastMovingStockThreshold: 20.0,
        creationDate: "2025-05-05",
        creatorId: usersIdOffset + 1,
        archiveStatus: 0,
      ),
      Product(
        sku: "PL-002",
        name: "Basin Wrench - Adjustable",
        categoryId: categoryIds[2],
        description:
            "Telescoping basin wrench with adjustable jaw for accessing tight spaces under sinks. "
            "Features spring-loaded design and cushioned grip.",
        salePrice: 550.00,
        orderCost: 350.00,
        quantity: 15.0,
        mainUnit: "piece",
        reorderPoint: 3.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 5.0,
        creationDate: "2025-05-05",
        creatorId: usersIdOffset + 2,
        archiveStatus: 0,
      ),
      Product(
        sku: "PL-003",
        name: "Universal Toilet Repair Kit",
        categoryId: categoryIds[2],
        description:
            "Complete toilet tank repair kit with flush valve, flapper, fill valve, and hardware. "
            "Compatible with most standard toilets and easy to install.",
        salePrice: 380.00,
        orderCost: 220.00,
        quantity: 25.0,
        mainUnit: "set",
        reorderPoint: 5.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 90.0,
        fastMovingStockThreshold: 8.0,
        creationDate: "2025-05-05",
        creatorId: usersIdOffset + 3,
        archiveStatus: 0,
      ),
      Product(
        sku: "PL-004",
        name: "Copper Pipe - 1/2\" x 3m",
        categoryId: categoryIds[2],
        description:
            "Type L copper pipe, 1/2\" diameter in 3-meter length for residential and commercial plumbing. "
            "Suitable for hot and cold water supply lines.",
        salePrice: 420.00,
        orderCost: 280.00,
        quantity: 30.0,
        mainUnit: "length",
        reorderPoint: 6.0,
        minReorderDelay: 8,
        maxReorderDelay: 15,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 10.0,
        creationDate: "2025-05-05",
        creatorId: usersIdOffset,
        archiveStatus: 0,
      ),
      Product(
        sku: "PL-005",
        name: "Shower Head - Adjustable Flow",
        categoryId: categoryIds[2],
        description:
            "Premium adjustable shower head with multiple spray settings and chrome finish. "
            "Easy installation and self-cleaning nozzles to prevent mineral buildup.",
        salePrice: 580.00,
        orderCost: 350.00,
        quantity: 20.0,
        mainUnit: "piece",
        reorderPoint: 4.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 150.0,
        fastMovingStockThreshold: 7.0,
        creationDate: "2025-05-06",
        creatorId: usersIdOffset + 1,
        archiveStatus: 0,
      ),
      Product(
        sku: "PL-006",
        name: "Pipe Cutter - 1/8\" to 1-1/8\"",
        categoryId: categoryIds[2],
        description:
            "Quick-acting pipe cutter for copper, brass, aluminum and plastic pipes from 1/8\" to 1-1/8\". "
            "Features sharp cutting wheel and smooth feed mechanism.",
        salePrice: 450.00,
        orderCost: 290.00,
        quantity: 15.0,
        mainUnit: "piece",
        reorderPoint: 3.0,
        minReorderDelay: 6,
        maxReorderDelay: 12,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 5.0,
        creationDate: "2025-05-06",
        creatorId: usersIdOffset + 2,
        archiveStatus: 0,
      ),
      Product(
        sku: "PL-007",
        name: "Kitchen Sink Faucet - Pull-Down",
        categoryId: categoryIds[2],
        description: "Modern kitchen sink faucet with pull-down sprayer, single handle control, "
            "and brushed nickel finish. Features ceramic disc valve for leak-free performance.",
        salePrice: 1850.00,
        orderCost: 1200.00,
        quantity: 12.0,
        mainUnit: "piece",
        reorderPoint: 3.0,
        minReorderDelay: 8,
        maxReorderDelay: 15,
        deadStockThreshold: 90.0,
        fastMovingStockThreshold: 4.0,
        creationDate: "2025-05-06",
        creatorId: usersIdOffset + 3,
        archiveStatus: 0,
      ),

      // Electrical - 7 products
      Product(
        sku: "EL-001",
        name: "Heavy-Duty Extension Cord - 5m",
        categoryId: categoryIds[3],
        description: "5-meter heavy-duty extension cord with 3 outlets and 14 gauge wire. "
            "Outdoor rated with weather-resistant coating and illuminated plug.",
        salePrice: 420.00,
        orderCost: 265.00,
        quantity: 30.0,
        mainUnit: "piece",
        reorderPoint: 5.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 100.0,
        fastMovingStockThreshold: 10.0,
        creationDate: "2025-05-07",
        creatorId: usersIdOffset,
        archiveStatus: 0,
      ),
      Product(
        sku: "EL-002",
        name: "LED Bulb - 9W - Dimmable",
        categoryId: categoryIds[3],
        description:
            "Energy-efficient 9W dimmable LED light bulb, 800 lumens, warm white (2700K), E27 base. "
            "Lasts up to 25,000 hours and compatible with most dimmer switches.",
        salePrice: 75.00,
        orderCost: 45.00,
        quantity: 100.0,
        mainUnit: "piece",
        reorderPoint: 15.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 150.0,
        fastMovingStockThreshold: 25.0,
        creationDate: "2025-05-07",
        creatorId: usersIdOffset + 1,
        archiveStatus: 0,
      ),
      Product(
        sku: "EL-003",
        name: "Circuit Breaker - 15A - Single Pole",
        categoryId: categoryIds[3],
        description:
            "15-amp single-pole circuit breaker for residential panels. Compatible with most major brands "
            "and designed for safe circuit protection against overloads and short circuits.",
        salePrice: 250.00,
        orderCost: 150.00,
        quantity: 40.0,
        mainUnit: "piece",
        reorderPoint: 8.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 12.0,
        creationDate: "2025-05-07",
        creatorId: usersIdOffset + 2,
        archiveStatus: 0,
      ),
      Product(
        sku: "EL-004",
        name: "Digital Multimeter",
        categoryId: categoryIds[3],
        description:
            "Professional digital multimeter with auto-ranging capability for voltage, current, resistance, "
            "and continuity testing. Includes test leads, battery and protective rubber holster.",
        salePrice: 950.00,
        orderCost: 580.00,
        quantity: 15.0,
        mainUnit: "piece",
        reorderPoint: 3.0,
        minReorderDelay: 8,
        maxReorderDelay: 15,
        deadStockThreshold: 150.0,
        fastMovingStockThreshold: 4.0,
        creationDate: "2025-05-07",
        creatorId: usersIdOffset + 3,
        archiveStatus: 0,
      ),
      Product(
        sku: "EL-005",
        name: "Smart Wi-Fi Light Switch",
        categoryId: categoryIds[3],
        description:
            "Smart Wi-Fi compatible light switch with app control, voice control, scheduling, and away mode. "
            "No hub required and works with most voice assistants. Neutral wire required for installation.",
        salePrice: 780.00,
        orderCost: 480.00,
        quantity: 25.0,
        mainUnit: "piece",
        reorderPoint: 5.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 8.0,
        creationDate: "2025-05-08",
        creatorId: usersIdOffset,
        archiveStatus: 0,
      ),
      Product(
        sku: "EL-006",
        name: "Electrical Wire - 12 AWG - 30m",
        categoryId: categoryIds[3],
        description: "30-meter roll of 12 AWG copper electrical wire with THHN insulation. "
            "Suitable for residential and commercial applications up to 20 amps.",
        salePrice: 650.00,
        orderCost: 410.00,
        quantity: 20.0,
        mainUnit: "roll",
        reorderPoint: 4.0,
        minReorderDelay: 6,
        maxReorderDelay: 12,
        deadStockThreshold: 150.0,
        fastMovingStockThreshold: 6.0,
        creationDate: "2025-05-08",
        creatorId: usersIdOffset + 1,
        archiveStatus: 0,
      ),
      Product(
        sku: "EL-007",
        name: "Surge Protector - 8 Outlet",
        categoryId: categoryIds[3],
        description: "Heavy-duty 8-outlet surge protector with 4,000 joule rating, "
            "6ft cord, and built-in circuit breaker. "
            "Features LED status indicators and safety covers for unused outlets.",
        salePrice: 350.00,
        orderCost: 220.00,
        quantity: 30.0,
        mainUnit: "piece",
        reorderPoint: 6.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 10.0,
        creationDate: "2025-05-08",
        creatorId: usersIdOffset + 2,
        archiveStatus: 0,
      ),

      // Painting Supplies - 6 products
      Product(
        sku: "PS-001",
        name: "Premium Interior Paint - 1 Gallon - Eggshell",
        categoryId: categoryIds[4],
        description:
            "Premium interior latex paint with eggshell finish, 1 gallon. Low-VOC, stain-resistant, "
            "and washable. Available in white, can be tinted to any color.",
        salePrice: 1150.00,
        orderCost: 720.00,
        quantity: 25.0,
        mainUnit: "gallon",
        reorderPoint: 5.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 90.0,
        fastMovingStockThreshold: 8.0,
        creationDate: "2025-05-09",
        creatorId: usersIdOffset + 3,
        archiveStatus: 0,
      ),
      Product(
        sku: "PS-002",
        name: "Professional Paint Roller Set",
        categoryId: categoryIds[4],
        description:
            "Professional 9-inch paint roller set with heavy-duty frame, two microfiber roller covers, "
            "extension pole, and deep-well tray with ladder hooks.",
        salePrice: 280.00,
        orderCost: 170.00,
        quantity: 35.0,
        mainUnit: "set",
        reorderPoint: 7.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 100.0,
        fastMovingStockThreshold: 10.0,
        creationDate: "2025-05-09",
        creatorId: usersIdOffset,
        archiveStatus: 0,
      ),
      Product(
        sku: "PS-003",
        name: "Exterior Paint - 1 Gallon - Satin",
        categoryId: categoryIds[4],
        description:
            "Weather-resistant exterior latex paint with satin finish, 1 gallon. Contains UV blockers "
            "and mildew inhibitors. Available in white, can be tinted to any color.",
        salePrice: 1350.00,
        orderCost: 850.00,
        quantity: 20.0,
        mainUnit: "gallon",
        reorderPoint: 4.0,
        minReorderDelay: 8,
        maxReorderDelay: 15,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 6.0,
        creationDate: "2025-05-09",
        creatorId: usersIdOffset + 1,
        archiveStatus: 0,
      ),
      Product(
        sku: "PS-004",
        name: "Premium Paint Brush Set - 5pc",
        categoryId: categoryIds[4],
        description:
            "Set of 5 premium paint brushes (1\", 1.5\", 2\", 2.5\", 3\") with wooden handles and synthetic bristles. "
            "Perfect for both latex and oil-based paints. Cleans easily and minimizes brush marks.",
        salePrice: 480.00,
        orderCost: 290.00,
        quantity: 25.0,
        mainUnit: "set",
        reorderPoint: 5.0,
        minReorderDelay: 6,
        maxReorderDelay: 12,
        deadStockThreshold: 150.0,
        fastMovingStockThreshold: 8.0,
        creationDate: "2025-05-09",
        creatorId: usersIdOffset + 2,
        archiveStatus: 0,
      ),
      Product(
        sku: "PS-005",
        name: "Paint Primer - Interior/Exterior - 1 Gallon",
        categoryId: categoryIds[4],
        description:
            "Multi-surface primer for interior and exterior use, 1 gallon. Provides excellent adhesion "
            "and sealing for paint, blocks stains, and hides previous colors.",
        salePrice: 950.00,
        orderCost: 580.00,
        quantity: 20.0,
        mainUnit: "gallon",
        reorderPoint: 4.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 6.0,
        creationDate: "2025-05-10",
        creatorId: usersIdOffset + 3,
        archiveStatus: 0,
      ),
      Product(
        sku: "PS-006",
        name: "Painter's Tape - Blue - 2\" x 60yd",
        categoryId: categoryIds[4],
        description:
            "2-inch wide blue painter's tape, 60 yards per roll. Medium adhesion for clean removal "
            "up to 14 days. Suitable for use on walls, trim, glass, and metal.",
        salePrice: 180.00,
        orderCost: 110.00,
        quantity: 50.0,
        mainUnit: "roll",
        reorderPoint: 10.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 15.0,
        creationDate: "2025-05-10",
        creatorId: usersIdOffset,
        archiveStatus: 0,
      ),

      // Safety & Security - 6 products
      Product(
        sku: "SS-001",
        name: "Smart Door Lock Set - Keypad & Bluetooth",
        categoryId: categoryIds[5],
        description:
            "Keyless entry door lock with keypad, Bluetooth connectivity, and traditional key backup. "
            "Features smartphone control, guest access codes, and activity logging.",
        salePrice: 2750.00,
        orderCost: 1750.00,
        quantity: 12.0,
        mainUnit: "set",
        reorderPoint: 3.0,
        minReorderDelay: 10,
        maxReorderDelay: 18,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 4.0,
        creationDate: "2025-05-10",
        creatorId: usersIdOffset + 1,
        archiveStatus: 0,
      ),
      Product(
        sku: "SS-002",
        name: "Smoke & Carbon Monoxide Detector - Battery",
        categoryId: categoryIds[5],
        description:
            "Dual-sensor smoke and carbon monoxide detector with battery backup and loud 85dB alarm. "
            "Features test button, low battery indicator, and end-of-life warning.",
        salePrice: 650.00,
        orderCost: 400.00,
        quantity: 30.0,
        mainUnit: "piece",
        reorderPoint: 6.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 150.0,
        fastMovingStockThreshold: 9.0,
        creationDate: "2025-05-10",
        creatorId: usersIdOffset + 2,
        archiveStatus: 0,
      ),
      Product(
        sku: "SS-003",
        name: "Premium Leather Work Gloves - L",
        categoryId: categoryIds[5],
        description:
            "Heavy-duty leather work gloves, size large. Features reinforced palm and fingers, "
            "adjustable wrist closure, and cotton lining for comfort during extended use.",
        salePrice: 180.00,
        orderCost: 110.00,
        quantity: 50.0,
        mainUnit: "pair",
        reorderPoint: 10.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 15.0,
        creationDate: "2025-05-10",
        creatorId: usersIdOffset + 3,
        archiveStatus: 0,
      ),
      Product(
        sku: "SS-004",
        name: "Wireless Security Camera - Indoor/Outdoor",
        categoryId: categoryIds[5],
        description:
            "HD wireless security camera for indoor/outdoor use with night vision, motion detection, "
            "and smartphone alerts. Includes cloud storage option and weather-resistant housing.",
        salePrice: 1850.00,
        orderCost: 1150.00,
        quantity: 15.0,
        mainUnit: "piece",
        reorderPoint: 3.0,
        minReorderDelay: 8,
        maxReorderDelay: 15,
        deadStockThreshold: 150.0,
        fastMovingStockThreshold: 5.0,
        creationDate: "2025-05-11",
        creatorId: usersIdOffset,
        archiveStatus: 0,
      ),
      Product(
        sku: "SS-005",
        name: "Safety Glasses - Anti-Fog",
        categoryId: categoryIds[5],
        description:
            "ANSI Z87.1 certified safety glasses with anti-fog coating, scratch-resistant lenses, "
            "and adjustable arms. Provides 99.9% UV protection and side shields for maximum protection.",
        salePrice: 120.00,
        orderCost: 70.00,
        quantity: 75.0,
        mainUnit: "piece",
        reorderPoint: 15.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 150.0,
        fastMovingStockThreshold: 20.0,
        creationDate: "2025-05-11",
        creatorId: usersIdOffset + 1,
        archiveStatus: 0,
      ),
      Product(
        sku: "SS-006",
        name: "Fire Extinguisher - ABC - 5lb",
        categoryId: categoryIds[5],
        description:
            "5-pound ABC fire extinguisher for home and office use. Effective against wood, paper, "
            "flammable liquids, and electrical fires. Includes mounting bracket and pressure gauge.",
        salePrice: 850.00,
        orderCost: 520.00,
        quantity: 20.0,
        mainUnit: "piece",
        reorderPoint: 4.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 180.0,
        fastMovingStockThreshold: 6.0,
        creationDate: "2025-05-11",
        creatorId: usersIdOffset + 2,
        archiveStatus: 0,
      ),

      // Automotive - 6 products
      Product(
        sku: "AU-001",
        name: "Full Synthetic Motor Oil - 5W-30 - 1L",
        categoryId: categoryIds[6],
        description:
            "Premium full synthetic motor oil 5W-30, 1 liter. Provides superior engine protection, "
            "improved fuel economy, and extended drain intervals up to 15,000 miles.",
        salePrice: 420.00,
        orderCost: 260.00,
        quantity: 45.0,
        mainUnit: "bottle",
        reorderPoint: 8.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 100.0,
        fastMovingStockThreshold: 12.0,
        creationDate: "2025-05-11",
        creatorId: usersIdOffset + 3,
        archiveStatus: 0,
      ),
      Product(
        sku: "AU-002",
        name: "Premium Windshield Wiper Blades - 18\"",
        categoryId: categoryIds[6],
        description:
            "18-inch premium beam-style windshield wiper blades. All-weather performance with "
            "contoured design for consistent pressure and clear wiping. Universal adapters included.",
        salePrice: 220.00,
        orderCost: 135.00,
        quantity: 40.0,
        mainUnit: "piece",
        reorderPoint: 10.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 150.0,
        fastMovingStockThreshold: 15.0,
        creationDate: "2025-05-12",
        creatorId: usersIdOffset,
        archiveStatus: 0,
      ),
      Product(
        sku: "AU-003",
        name: "Maintenance-Free Car Battery - Group 35",
        categoryId: categoryIds[6],
        description:
            "Maintenance-free 12V car battery, group size 35, with 650 CCA (Cold Cranking Amps) "
            "and 100 reserve minutes. 3-year warranty and built-in charge indicator.",
        salePrice: 3650.00,
        orderCost: 2400.00,
        quantity: 12.0,
        mainUnit: "piece",
        reorderPoint: 3.0,
        minReorderDelay: 10,
        maxReorderDelay: 14,
        deadStockThreshold: 90.0,
        fastMovingStockThreshold: 4.0,
        creationDate: "2025-05-12",
        creatorId: usersIdOffset + 1,
        archiveStatus: 0,
      ),
      Product(
        sku: "AU-004",
        name: "Portable Jump Starter - 1000A",
        categoryId: categoryIds[6],
        description:
            "Compact 1000A portable jump starter and power bank. Can jump start vehicles up to 7.0L gas/5.5L diesel. "
            "Features USB charging ports, LED flashlight, and LCD display.",
        salePrice: 1950.00,
        orderCost: 1250.00,
        quantity: 15.0,
        mainUnit: "piece",
        reorderPoint: 3.0,
        minReorderDelay: 8,
        maxReorderDelay: 15,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 5.0,
        creationDate: "2025-05-12",
        creatorId: usersIdOffset + 2,
        archiveStatus: 0,
      ),
      Product(
        sku: "AU-005",
        name: "Tire Pressure Gauge - Digital",
        categoryId: categoryIds[6],
        description: "Digital tire pressure gauge with backlit LCD display, reads 0-150 PSI. "
            "Features non-slip grip, auto shut-off, and multiple pressure units (PSI, BAR, KPA).",
        salePrice: 180.00,
        orderCost: 110.00,
        quantity: 35.0,
        mainUnit: "piece",
        reorderPoint: 7.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 150.0,
        fastMovingStockThreshold: 10.0,
        creationDate: "2025-05-12",
        creatorId: usersIdOffset + 3,
        archiveStatus: 0,
      ),
      Product(
        sku: "AU-006",
        name: "Auto Detailing Kit - Complete",
        categoryId: categoryIds[6],
        description:
            "Complete 12-piece auto detailing kit with car wash soap, wax, interior cleaner, "
            "microfiber towels, applicator pads, tire shine, and detailing brushes.",
        salePrice: 1250.00,
        orderCost: 780.00,
        quantity: 20.0,
        mainUnit: "kit",
        reorderPoint: 4.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 6.0,
        creationDate: "2025-05-12",
        creatorId: usersIdOffset,
        archiveStatus: 0,
      ),
    ];

    // Insert products and collect IDs (limit to MAX_PRODUCTS)
    final productIds = <int>[];
    final productCount = mockProducts.length > MAX_PRODUCTS ? MAX_PRODUCTS : mockProducts.length;

    for (var i = 0; i < productCount; i++) {
      final product = mockProducts[i];
      // Update creator ID to use actual user references
      final updatedProduct = product.copyWith(
        creatorId: users[i % users.length].id!,
      );
      final insertedProduct = await productsRepository.insertProduct(updatedProduct);

      productIds.add(insertedProduct.id!);
    }

    // STEP 4: CREATE PAYMENT METHODS FIRST
    const mockPaymentMethods = [
      PaymentMethod(name: 'Cash'),
      PaymentMethod(name: 'Credit Card'),
      PaymentMethod(name: 'Bank Transfer'),
      PaymentMethod(name: 'Mobile Payment'),
      PaymentMethod(name: 'Check'),
      PaymentMethod(name: 'Store Credit'),
    ];

    // Add payment methods to database
    final paymentMethodIds = <int>[];
    for (final paymentMethod in mockPaymentMethods) {
      final savedPaymentMethod = await paymentMethodRepository.insertPaymentMethod(paymentMethod);
      paymentMethodIds.add(savedPaymentMethod.id!);
    }

    // STEP 5: CREATE INVOICES AND INVOICE PRODUCTS (SALES TRANSACTIONS)
    // These represent sales to customers - money coming INTO the business
    // List of 50 customer names for the invoices
    final mockCustomers = [
      // First 10 customers
      "Maria Santos",
      "Juan Dela Cruz",
      "Andres Bonifacio",
      "Emilio Aguinaldo",
      "Gabriela Silang",
      "Jose Rizal",
      "Rodrigo Martinez",
      "Corazon Aquino",
      "Efren Reyes",
      "Manny Pacquiao",

      // Next 10 customers
      "Fernando Lopez",
      "Diana Garcia",
      "Carlos Mendoza",
      "Elena Reyes",
      "Miguel Tan",
      "Sofia Cruz",
      "Rafael Villanueva",
      "Victoria Lim",
      "Eduardo Santos",
      "Isabella Ramos",

      // Next 30 customers for 50 total
      "Ricardo Dalisay",
      "Margarita Reyes",
      "Antonio Manahan",
      "Luzviminda Cruz",
      "Pedro Morales",
      "Divina Santos",
      "Roberto Gonzales",
      "Thelma Pineda",
      "Leandro Torres",
      "Josephine Ocampo",
      "Renato Macaraeg",
      "Carmen Bautista",
      "Alejandro Villanueva",
      "Lourdes Quiambao",
      "Emmanuel Torres",
      "Rosario Reyes",
      "Francisco Santos",
      "Aurora Dimaculangan",
      "Benito Reyes",
      "Milagros Soriano",
      "Gerardo Limcangco",
      "Corazon Enriquez",
      "Reynaldo Bautista",
      "Angelina Reyes",
      "Rogelio Marquez",
      "Zenaida Aquino",
      "Marcelo Domingo",
      "Cecilia Magallanes",
      "Teodoro Ramos",
      "Remedios Legaspi",
    ];

    // Memo options for invoices
    final memos = [
      "Regular customer purchase",
      "Bulk order for construction project",
      "Monthly maintenance supplies",
      "Home renovation materials",
      "Emergency repair supplies",
      "Special order with custom pricing",
      "Contractor discount applied",
      "Retail customer - cash & carry",
      "Purchased for residential project",
      "Commercial client order",
    ];

    // Create invoices distributed evenly over time
    final mockInvoices = <Invoice>[];
    for (var i = 0; i < NUM_INVOICES; i++) {
      final customerName = mockCustomers[Random().nextInt(mockCustomers.length)];

      // Create evenly distributed dates for invoices from today back to DAYS_IN_PAST
      final daysAgo = (i * DAYS_IN_PAST / NUM_INVOICES).round();
      final invoiceDate = currentDate.subtract(Duration(days: daysAgo));

      // Create payment date logic
      DateTime? paymentDate;
      final isVeryRecent = invoiceDate.isAfter(currentDate.subtract(const Duration(days: 3)));

      if (isVeryRecent && i % 3 == 0) {
        // 33% of very recent invoices are unpaid
        paymentDate = null;
      } else if (i % 5 == 0) {
        // 20% of all other invoices are unpaid
        paymentDate = null;
      } else if (i % 3 == 0) {
        // 33% are paid later (1-5 days)
        paymentDate = invoiceDate.add(Duration(days: 1 + (i % 5)));
      } else {
        // Remaining are paid same day
        paymentDate = invoiceDate;
      }

      // Determine if invoice has discount and what type
      final hasDiscount = i % 4 == 0; // 25% of invoices have discount
      final discountType = i % 8 == 0 ? DiscountType.value : DiscountType.percentage;
      final discountValue =
          discountType == DiscountType.percentage ? 5.0 + (i % 6) : 50.0 + (i * 10.0 % 100);

      // Select memo text
      final memo = i % 3 == 0 ? memos[i % memos.length] : null;

      // Create reference number with format INV-YYYY MM XXX
      final refNum =
          "INV-${invoiceDate.year}${invoiceDate.month.toString().padLeft(2, '0')}${i.toString().padLeft(3, '0')}";

      // Create invoice
      final invoice = Invoice(
        customerName: customerName,
        invoiceDate: invoiceDate,
        dueDate: invoiceDate.add(Duration(days: 15 + (i % 4) * 5)), // 15-30 days due
        paymentMethod:
            paymentMethodIds[i % paymentMethodIds.length], // Use actual payment method IDs
        referenceNumber: refNum,
        memo: memo,
        discount: hasDiscount ? discountValue : null,
        discountType: hasDiscount ? discountType : null,
        creationDate: invoiceDate,
        paymentDate: paymentDate,
        amountDue: 0, // Will be calculated after adding products
        amountPaid: paymentDate != null ? 0 : null, // Will be updated after adding products
        creatorId: users[(i % users.length)].id!, // Use actual user IDs
      );

      mockInvoices.add(invoice);
    }

    // Insert invoices and add invoice products
    for (final invoice in mockInvoices) {
      final insertedInvoice = await invoiceRepository.insertInvoice(invoice);
      printBoxed(
        "${insertedInvoice.id} for ${insertedInvoice.customerName}",
        "Invoice Created",
      );
      final invoiceId = insertedInvoice.id!;

      // Determine number of products for this invoice
      final customerIndex = mockInvoices.indexOf(invoice);
      // More products for more recent invoices
      final numberOfProducts = customerIndex < 10
          ? 1 + (invoiceId % 3) // 1-3 products
          : (customerIndex < 30
              ? 3 + (invoiceId % 3) // 3-5 products
              : 1 + (invoiceId % 7)); // 1-7 products

      // Track total amount for this invoice
      var totalAmount = 0.0;

      // Prevent duplicate products in the same invoice
      final selectedProducts = <int>{};

      // Add products to this invoice
      for (var j = 0; j < numberOfProducts; j++) {
        // Try to select products from same category for realistic grouping
        final preferredCategory = categoryIds[customerIndex % categoryIds.length];

        // Find a product that hasn't been used in this invoice
        int productIndex;
        if (j < 2) {
          // First 2 products try to select from preferred category
          final categoryProducts = mockProducts
              .asMap()
              .entries
              .where((e) => e.value.categoryId == preferredCategory)
              .where((e) => !selectedProducts.contains(e.key))
              .toList();

          if (categoryProducts.isNotEmpty) {
            productIndex = categoryProducts[(customerIndex + j) % categoryProducts.length].key;
          } else {
            // Fallback if no products available in preferred category
            productIndex = (customerIndex + j * 3) % productIds.length;
            while (selectedProducts.contains(productIndex)) {
              productIndex = (productIndex + 1) % productIds.length;
            }
          }
        } else {
          // Remaining products can be from any category
          productIndex = (customerIndex + j * 3) % productIds.length;
          while (selectedProducts.contains(productIndex)) {
            productIndex = (productIndex + 1) % productIds.length;
          }
        }

        // Mark product as selected for this invoice
        selectedProducts.add(productIndex);

        // Get product
        final product = mockProducts[productIndex];

        // Determine quantity based on product type
        double quantity;
        if (product.mainUnit == "piece" || product.mainUnit == "set") {
          quantity = 1 + (j % 3); // 1-3 for piece/set items
        } else if (product.mainUnit == "bag" || product.mainUnit == "gallon") {
          quantity = 1 + (j % 2); // 1-2 for heavy items
        } else {
          quantity = 1 + (j % 5); // 1-5 for other items
        }

        // Calculate amount
        final rate = product.salePrice;
        final amount = rate * quantity;
        totalAmount += amount;

        // Create invoice product
        final invoiceProduct = InvoiceProduct(
          invoiceId: invoiceId,
          productId: productIds[productIndex],
          productName: product.name,
          description: product.description,
          quantity: quantity.toInt(),
          rate: rate,
          amount: amount,
        );

        // Add to database
        await invoiceProductRepository.insertInvoiceProduct(invoiceProduct);
      }

      // Update invoice with total amount
      final updatedInvoice = invoice.copyWith(
        id: invoiceId,
        amountDue: totalAmount,
        amountPaid: invoice.paymentDate != null ? totalAmount : null,
      );

      await invoiceRepository.updateInvoice(updatedInvoice);
    }

    // STEP 6: CREATE EXPENSE TYPES
    final mockExpenseTypes = <model.ExpenseType>[
      const model.ExpenseType(name: 'Inventory Restock'),
      const model.ExpenseType(name: 'Equipment'),
      const model.ExpenseType(name: 'Utilities'),
      const model.ExpenseType(name: 'Rent'),
      const model.ExpenseType(name: 'Salaries'),
      const model.ExpenseType(name: 'Marketing'),
      const model.ExpenseType(name: 'Insurance'),
      const model.ExpenseType(name: 'Maintenance'),
      const model.ExpenseType(name: 'Office Supplies'),
      const model.ExpenseType(name: 'Transportation'),
    ];

    // Add expense types to database
    final expenseTypeIds = <int>[];
    for (final expenseType in mockExpenseTypes) {
      if (expenseType.name == 'Inventory Restock') {
        // Ensure inventory restock is always first
        expenseTypeIds.insert(0, 1);
        continue;
      }

      final savedExpenseType = await expenseTypeRepository.insertExpenseType(expenseType);
      expenseTypeIds.add(savedExpenseType.id!);
    }

    // STEP 7: CREATE ORDERS (EXPENSES/PURCHASES)
    // These represent purchases from suppliers - money going OUT of the business
    // Create 20 orders with different expense types and payment methods
    final mockOrders = <Order>[];
    // List of supplier names for payee names
    final suppliers = <String>[
      'East Hardware Wholesale',
      'Premium Tools Supply',
      'Building Materials Inc',
      'Industrial Parts Ltd',
      'City Power & Electric',
      'Metro Office Solutions',
      'National Construction Supply',
      'Quality Hardware Distributors',
      'Global Tool Company',
      'Local Lumber Yard'
    ];

    // Generate orders evenly distributed over time
    for (var i = 0; i < NUM_ORDERS; i++) {
      // Distribute orders evenly from today to DAYS_IN_PAST
      final daysAgo = (i * DAYS_IN_PAST / 2).round();
      final orderDate = currentDate.subtract(Duration(days: daysAgo));

      // Determine expense type (bias towards inventory restock)
      int expenseTypeId;
      if (i % 3 == 0) {
        expenseTypeId = expenseTypeIds[0]; // Inventory Restock
      } else {
        expenseTypeId = expenseTypeIds[i % expenseTypeIds.length];
      }

      // Determine payment method
      final paymentMethodId = paymentMethodIds[i % paymentMethodIds.length];

      // Determine creator (user)
      final creatorId = users[i % users.length].id!; // Use actual user IDs

      // Reference number (invoice/receipt number)
      final referenceNumber = 'REC${10000 + i}';

      // Determine if it's a paid expense (more recent orders are more likely to be unpaid)
      final isPaid = daysAgo > 15 ||
          (daysAgo > 7 &&
              i % 3 != 0); // Invoices older than 15 days are paid, some 7-15 day old orders paid

      // Create order object
      final order = Order(
        payeeName: suppliers[i % suppliers.length],
        expenseType: expenseTypeId,
        orderDate: orderDate,
        paymentMethod: paymentMethodId,
        referenceNumber: referenceNumber,
        memo:
            'Purchase order for ${expenseTypeId == expenseTypeIds[0] ? 'inventory restock' : mockExpenseTypes[expenseTypeIds.indexOf(expenseTypeId)].name.toLowerCase()}',
        amountDue: 0, // Will be updated after adding products
        amountPaid: isPaid ? null : 0, // Will be updated if paid
        paymentDate:
            isPaid ? orderDate.add(const Duration(days: 3)) : null, // Paid 3 days after order
        creationDate: orderDate,
        creatorId: creatorId,
      );

      // Add order to database and get ID
      final savedOrder = await orderRepository.insertOrder(order);
      final orderId = savedOrder.id!;
      mockOrders.add(savedOrder);

      // Add products or expense items to order
      var totalAmount = 0.0;

      if (expenseTypeId == expenseTypeIds[0]) {
        // For inventory restock - use actual products
        final productCount = 1 + (i % 2); // 1-4 products per order
        final selectedProducts = <int>{}; // Avoid duplicate products in same order

        for (var j = 0; j < productCount; j++) {
          // Inventory restock - prefer products with lower quantities
          final availableProducts = mockProducts
              .asMap()
              .entries
              .where((entry) => !selectedProducts.contains(entry.key))
              .toList();

          // Sort by quantity (ascending) to prefer products that need restocking
          availableProducts.sort((a, b) => a.value.quantity.compareTo(b.value.quantity));

          // Select from the lower quantity products
          final selectFrom = availableProducts.take((availableProducts.length / 2).ceil()).toList();
          final productIndex = selectFrom[(i + j) % selectFrom.length].key;

          selectedProducts.add(productIndex);

          // Get the product
          final product = mockProducts[productIndex];

          // Determine quantity for restocking
          double quantity;
          if (product.mainUnit == "piece" || product.mainUnit == "set") {
            quantity = 4.0 + (j % 10); // 10-19 for piece/set items for restocking
          } else if (product.mainUnit == "bag" || product.mainUnit == "gallon") {
            quantity = 3.0 + (j % 5); // 5-9 for heavy items
          } else {
            quantity = 2.0 + (j % 7); // 8-14 for other items
          }

          // Use purchase price as rate for orders
          final rate = product.orderCost;
          final amount = rate * quantity;
          totalAmount += amount;

          // Create order product
          final orderProduct = OrderProduct(
            orderId: orderId,
            productId: productIds[productIndex],
            productName: product.name,
            description: product.description,
            quantity: quantity.toInt(),
            rate: rate,
            amount: amount,
          );

          // Add to database
          await orderProductRepository.insertOrderProduct(orderProduct);
        }
      } else {
        // For non-restock expenses - use appropriate expense items based on expense type
        final expenseItems = <({String name, String description, double amount})>[];

        // Generate appropriate expense items based on expense type
        switch (expenseTypeIds.indexOf(expenseTypeId)) {
          case 1: // Equipment
            expenseItems.add((
              name: 'Equipment Purchase',
              description: 'New office equipment',
              amount: 5000.0 + (i * 500.0 % 5000.0),
            ));
            if (i % 3 == 0) {
              expenseItems.add((
                name: 'Equipment Installation',
                description: 'Installation services',
                amount: 800.0 + (i * 200.0 % 700.0),
              ));
            }
            break;

          case 2: // Utilities
            expenseItems.add((
              name: 'Electricity',
              description: 'Monthly electricity bill',
              amount: 2000.0 + (i * 300.0 % 1000.0),
            ));
            expenseItems.add((
              name: 'Water',
              description: 'Monthly water bill',
              amount: 800.0 + (i * 100.0 % 500.0),
            ));
            if (i % 2 == 0) {
              expenseItems.add((
                name: 'Internet',
                description: 'Monthly internet service',
                amount: 1200.0 + (i * 100.0 % 300.0),
              ));
            }
            break;

          case 3: // Rent
            expenseItems.add((
              name: 'Store Rent',
              description: 'Monthly store rent payment',
              amount: 15000.0 + (i * 1000.0 % 5000.0),
            ));
            if (i % 3 == 0) {
              expenseItems.add((
                name: 'Additional Space',
                description: 'Temporary storage space rental',
                amount: 3000.0 + (i * 500.0 % 2000.0),
              ));
            }
            break;

          case 4: // Salaries
            expenseItems.add((
              name: 'Staff Salaries',
              description: 'Monthly staff wages',
              amount: 25000.0 + (i * 2000.0 % 10000.0),
            ));
            if (i % 4 == 0) {
              expenseItems.add((
                name: 'Overtime Pay',
                description: 'Staff overtime compensation',
                amount: 5000.0 + (i * 500.0 % 3000.0),
              ));
            }
            break;

          case 5: // Marketing
            expenseItems.add((
              name: 'Advertisement',
              description: 'Local newspaper advertisement',
              amount: 3000.0 + (i * 500.0 % 2000.0),
            ));
            if (i % 2 == 0) {
              expenseItems.add((
                name: 'Promotional Materials',
                description: 'Brochures and flyers',
                amount: 1500.0 + (i * 300.0 % 1000.0),
              ));
            }
            break;

          case 6: // Insurance
            expenseItems.add((
              name: 'Business Insurance',
              description: 'Annual business insurance premium',
              amount: 12000.0 + (i * 1000.0 % 3000.0),
            ));
            break;

          case 7: // Maintenance
            expenseItems.add((
              name: 'Building Maintenance',
              description: 'General building repairs',
              amount: 2500.0 + (i * 500.0 % 2000.0),
            ));
            if (i % 2 == 0) {
              expenseItems.add((
                name: 'Equipment Service',
                description: 'Regular equipment maintenance',
                amount: 1800.0 + (i * 200.0 % 1000.0),
              ));
            }
            break;

          case 8: // Office Supplies
            expenseItems.add((
              name: 'General Office Supplies',
              description: 'Paper, pens, and stationery',
              amount: 1000.0 + (i * 200.0 % 500.0),
            ));
            if (i % 3 == 0) {
              expenseItems.add((
                name: 'Printer Supplies',
                description: 'Ink cartridges and toners',
                amount: 1200.0 + (i * 300.0 % 800.0),
              ));
            }
            break;

          case 9: // Transportation
            expenseItems.add((
              name: 'Delivery Costs',
              description: 'Product delivery expenses',
              amount: 2000.0 + (i * 400.0 % 1500.0),
            ));
            if (i % 2 == 0) {
              expenseItems.add((
                name: 'Vehicle Maintenance',
                description: 'Company vehicle servicing',
                amount: 3500.0 + (i * 500.0 % 2000.0),
              ));
            }
            break;

          default: // Miscellaneous expenses
            expenseItems.add((
              name: 'Miscellaneous Expense',
              description: 'General operational expense',
              amount: 1500.0 + (i * 300.0 % 1000.0),
            ));
        }

        // Add each expense item as an order product
        for (final item in expenseItems) {
          totalAmount += item.amount;

          // Create order item for expense item (quantity=1 for non-inventory items)
          final orderItem = OrderItem(
            orderId: orderId,
            name: item.name,
            description: item.description,
            quantity: 1, // Non-inventory items typically have quantity=1
            rate: item.amount,
            amount: item.amount,
          );

          // Add to database
          await orderItemRepository.insertOrderItem(orderItem);
        }
      }

      // Update order with total amount
      final updatedOrder = savedOrder.copyWith(
        amountDue: totalAmount,
        amountPaid: isPaid ? totalAmount : null,
      );

      await orderRepository.updateOrder(updatedOrder);
    }
  } on Object catch (e, st) {
    printBoxed("$e\n\n$st", "Seeding Error");
    showNotification.error(
      title: 'Error',
      message: 'An error occurred while seeding the database. $e',
    );
  } finally {}
}
