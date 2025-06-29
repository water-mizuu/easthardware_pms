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
import 'package:easthardware_pms/domain/models/payment_method.dart' as model;
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
const int NUM_ORDERS = 80; // Increased from 20
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

    // STEP 3: CREATE PRODUCTS
    final mockProducts = [
      // Hardware Tools
      Product(
        sku: "HT-001",
        name: "Hammer - 16oz Claw",
        categoryId: categoryIds[0],
        description: "Standard 16oz claw hammer with fiberglass handle, "
            "suitable for general construction and household repairs.",
        salePrice: 450.00,
        orderCost: 280.00,
        quantity: 35.0,
        mainUnit: "piece",
        criticalLevel: 5.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 180.0,
        fastMovingStockThreshold: 15.0,
        creationDate: "2025-05-01",
        creatorId: users[0].id!, // Use actual user ID
        archiveStatus: 0,
      ),
      Product(
        sku: "HT-002",
        name: "Screwdriver Set - 10pc",
        categoryId: categoryIds[0],
        description: "10-piece screwdriver set with various "
            "sizes of flathead and Phillips head screwdrivers.",
        salePrice: 850.00,
        orderCost: 520.00,
        quantity: 20.0,
        mainUnit: "set",
        criticalLevel: 3.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 150.0,
        fastMovingStockThreshold: 8.0,
        creationDate: "2025-05-01",
        creatorId: users[0].id!, // Use actual user ID
        archiveStatus: 0,
      ),
      Product(
        sku: "HT-003",
        name: "Drill Machine - 650W",
        categoryId: categoryIds[0],
        description: "Heavy-duty 650W power drill with variable "
            "speed control, suitable for wood, metal, and concrete.",
        salePrice: 3200.00,
        orderCost: 1900.00,
        quantity: 12.0,
        mainUnit: "piece",
        criticalLevel: 2.0,
        minReorderDelay: 10,
        maxReorderDelay: 14,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 4.0,
        creationDate: "2025-05-01",
        creatorId: usersIdOffset + 1,
        archiveStatus: 0,
      ),
      // Building Materials
      Product(
        sku: "BM-001",
        name: "Cement - 40kg",
        categoryId: categoryIds[1],
        description: "40kg bag of Portland cement, suitable for "
            "concrete mixing and general construction.",
        salePrice: 320.00,
        orderCost: 240.00,
        quantity: 150.0,
        mainUnit: "bag",
        criticalLevel: 20.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 90.0,
        fastMovingStockThreshold: 30.0,
        creationDate: "2025-05-02",
        creatorId: usersIdOffset + 2,
        archiveStatus: 0,
      ),
      Product(
        sku: "BM-002",
        name: "Construction Sand - 50kg",
        categoryId: categoryIds[1],
        description: "50kg bag of washed construction sand for concrete mixing.",
        salePrice: 130.00,
        orderCost: 85.00,
        quantity: 200.0,
        mainUnit: "bag",
        criticalLevel: 30.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 40.0,
        creationDate: "2025-05-02",
        creatorId: usersIdOffset + 2,
        archiveStatus: 0,
      ),
      // Plumbing
      Product(
        sku: "PL-001",
        name: "PVC Pipe - 1/2\" x 3m",
        categoryId: categoryIds[2],
        description: "3-meter length of 1/2-inch PVC pipe for residential plumbing.",
        salePrice: 95.00,
        orderCost: 60.00,
        quantity: 80.0,
        mainUnit: "length",
        criticalLevel: 10.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 100.0,
        fastMovingStockThreshold: 20.0,
        creationDate: "2025-05-03",
        creatorId: usersIdOffset + 3,
        archiveStatus: 0,
      ),
      Product(
        sku: "PL-002",
        name: "Basin Wrench",
        categoryId: categoryIds[2],
        description: "Adjustable basin wrench for tight spaces under sinks.",
        salePrice: 550.00,
        orderCost: 350.00,
        quantity: 15.0,
        mainUnit: "piece",
        criticalLevel: 3.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 5.0,
        creationDate: "2025-05-03",
        creatorId: usersIdOffset + 3,
        archiveStatus: 0,
      ),
      Product(
        sku: "PL-003",
        name: "Toilet Flush Mechanism",
        categoryId: categoryIds[2],
        description: "Universal toilet tank flush valve replacement kit.",
        salePrice: 380.00,
        orderCost: 220.00,
        quantity: 25.0,
        mainUnit: "set",
        criticalLevel: 5.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 90.0,
        fastMovingStockThreshold: 8.0,
        creationDate: "2025-05-03",
        creatorId: usersIdOffset + 3,
        archiveStatus: 0,
      ),
      // Electrical
      Product(
        sku: "EL-001",
        name: "Extension Cord - 5m",
        categoryId: categoryIds[3],
        description: "5-meter heavy-duty extension cord with 3 outlets.",
        salePrice: 420.00,
        orderCost: 265.00,
        quantity: 30.0,
        mainUnit: "piece",
        criticalLevel: 5.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 100.0,
        fastMovingStockThreshold: 10.0,
        creationDate: "2025-05-04",
        creatorId: usersIdOffset + 1,
        archiveStatus: 0,
      ),
      Product(
        sku: "EL-002",
        name: "LED Bulb - 9W",
        categoryId: categoryIds[3],
        description: "9W LED light bulb, warm white, E27 base.",
        salePrice: 75.00,
        orderCost: 45.00,
        quantity: 100.0,
        mainUnit: "piece",
        criticalLevel: 15.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 150.0,
        fastMovingStockThreshold: 25.0,
        creationDate: "2025-05-04",
        creatorId: usersIdOffset + 1,
        archiveStatus: 0,
      ),
      Product(
        sku: "EL-003",
        name: "Circuit Breaker - 15A",
        categoryId: categoryIds[3],
        description: "15-amp single-pole circuit breaker for residential panels.",
        salePrice: 250.00,
        orderCost: 150.00,
        quantity: 40.0,
        mainUnit: "piece",
        criticalLevel: 8.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 12.0,
        creationDate: "2025-05-04",
        creatorId: usersIdOffset + 1,
        archiveStatus: 0,
      ),
      // Painting Supplies
      Product(
        sku: "PS-001",
        name: "Interior Paint - 1 Gallon",
        categoryId: categoryIds[4],
        description: "Premium interior latex paint, white, 1 gallon.",
        salePrice: 1150.00,
        orderCost: 720.00,
        quantity: 25.0,
        mainUnit: "gallon",
        criticalLevel: 5.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 90.0,
        fastMovingStockThreshold: 8.0,
        creationDate: "2025-05-05",
        creatorId: usersIdOffset + 2,
        archiveStatus: 0,
      ),
      Product(
        sku: "PS-002",
        name: "Paint Roller Set",
        categoryId: categoryIds[4],
        description: "9-inch roller with frame and tray.",
        salePrice: 280.00,
        orderCost: 170.00,
        quantity: 35.0,
        mainUnit: "set",
        criticalLevel: 7.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 100.0,
        fastMovingStockThreshold: 10.0,
        creationDate: "2025-05-05",
        creatorId: usersIdOffset + 2,
        archiveStatus: 0,
      ),
      // Safety & Security
      Product(
        sku: "SS-001",
        name: "Door Lock Set",
        categoryId: categoryIds[5],
        description: "Deadbolt and handle set for exterior doors.",
        salePrice: 1350.00,
        orderCost: 850.00,
        quantity: 18.0,
        mainUnit: "set",
        criticalLevel: 4.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 6.0,
        creationDate: "2025-05-06",
        creatorId: usersIdOffset + 3,
        archiveStatus: 0,
      ),
      Product(
        sku: "SS-002",
        name: "Smoke Detector",
        categoryId: categoryIds[5],
        description: "Battery-operated smoke detector with test button.",
        salePrice: 650.00,
        orderCost: 400.00,
        quantity: 30.0,
        mainUnit: "piece",
        criticalLevel: 6.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 150.0,
        fastMovingStockThreshold: 9.0,
        creationDate: "2025-05-06",
        creatorId: usersIdOffset + 3,
        archiveStatus: 0,
      ),
      Product(
        sku: "SS-003",
        name: "Work Gloves",
        categoryId: categoryIds[5],
        description: "Heavy-duty leather work gloves, medium size.",
        salePrice: 180.00,
        orderCost: 110.00,
        quantity: 50.0,
        mainUnit: "pair",
        criticalLevel: 10.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 120.0,
        fastMovingStockThreshold: 15.0,
        creationDate: "2025-05-06",
        creatorId: usersIdOffset + 3,
        archiveStatus: 0,
      ),
      // Automotive
      Product(
        sku: "AU-001",
        name: "Motor Oil - 1L",
        categoryId: categoryIds[6],
        description: "Synthetic motor oil 10W-30, 1 liter.",
        salePrice: 420.00,
        orderCost: 260.00,
        quantity: 45.0,
        mainUnit: "bottle",
        criticalLevel: 8.0,
        minReorderDelay: 7,
        maxReorderDelay: 14,
        deadStockThreshold: 100.0,
        fastMovingStockThreshold: 12.0,
        creationDate: "2025-05-07",
        creatorId: usersIdOffset + 1,
        archiveStatus: 0,
      ),
      Product(
        sku: "AU-002",
        name: "Windshield Wiper - 18\"",
        categoryId: categoryIds[6],
        description: "18-inch universal windshield wiper blade.",
        salePrice: 220.00,
        orderCost: 135.00,
        quantity: 40.0,
        mainUnit: "piece",
        criticalLevel: 10.0,
        minReorderDelay: 5,
        maxReorderDelay: 10,
        deadStockThreshold: 150.0,
        fastMovingStockThreshold: 15.0,
        creationDate: "2025-05-07",
        creatorId: usersIdOffset + 1,
        archiveStatus: 0,
      ),
      Product(
        sku: "AU-003",
        name: "Car Battery",
        categoryId: categoryIds[6],
        description: "12V car battery, 60Ah capacity.",
        salePrice: 3650.00,
        orderCost: 2400.00,
        quantity: 12.0,
        mainUnit: "piece",
        criticalLevel: 3.0,
        minReorderDelay: 10,
        maxReorderDelay: 14,
        deadStockThreshold: 90.0,
        fastMovingStockThreshold: 4.0,
        creationDate: "2025-05-07",
        creatorId: usersIdOffset + 1,
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
    final mockPaymentMethods = <model.PaymentMethod>[
      model.PaymentMethod(name: 'Cash'),
      model.PaymentMethod(name: 'Credit Card'),
      model.PaymentMethod(name: 'Bank Transfer'),
      model.PaymentMethod(name: 'Mobile Payment'),
      model.PaymentMethod(name: 'Check'),
      model.PaymentMethod(name: 'Store Credit'),
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
      final daysAgo = (i * DAYS_IN_PAST / NUM_ORDERS).round();
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
        final productCount = 1 + (i % 4); // 1-4 products per order
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
            quantity = 10.0 + (j % 10); // 10-19 for piece/set items for restocking
          } else if (product.mainUnit == "bag" || product.mainUnit == "gallon") {
            quantity = 5.0 + (j % 5); // 5-9 for heavy items
          } else {
            quantity = 8.0 + (j % 7); // 8-14 for other items
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
            quantity: 1.0, // Non-inventory items typically have quantity=1
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
