import 'package:flutter_test/flutter_test.dart';
import 'package:easthardware_pms/utils/levenshtein.dart';

void main() {
  group('Levenshtein Distance Tests', () {
    test('identical strings should have distance 0', () {
      expect(Levenshtein.distance('hello', 'hello'), equals(0.0));
      expect(Levenshtein.distance('', ''), equals(0.0));
      expect(Levenshtein.distance('a', 'a'), equals(0.0));
      expect(Levenshtein.distance('test123', 'test123'), equals(0.0));
    });

    test('empty string edge cases', () {
      expect(Levenshtein.distance('', 'hello'), equals(5.0));
      expect(Levenshtein.distance('hello', ''), equals(5.0));
      expect(Levenshtein.distance('', 'a'), equals(1.0));
      expect(Levenshtein.distance('a', ''), equals(1.0));
    });

    test('single character differences', () {
      expect(Levenshtein.distance('a', 'b'), equals(1.0));
      expect(Levenshtein.distance('cat', 'bat'), equals(1.0));
      expect(Levenshtein.distance('hello', 'hallo'), equals(1.0));
    });

    test('insertion operations', () {
      expect(Levenshtein.distance('cat', 'cats'), equals(1.0));
      expect(Levenshtein.distance('hello', 'hellos'), equals(1.0));
      expect(Levenshtein.distance('ab', 'abc'), equals(1.0));
      expect(Levenshtein.distance('test', 'testing'), equals(3.0));
    });

    test('deletion operations', () {
      expect(Levenshtein.distance('cats', 'cat'), equals(1.0));
      expect(Levenshtein.distance('hellos', 'hello'), equals(1.0));
      expect(Levenshtein.distance('abc', 'ab'), equals(1.0));
      expect(Levenshtein.distance('testing', 'test'), equals(3.0));
    });

    test('substitution operations', () {
      expect(Levenshtein.distance('cat', 'car'), equals(1.0));
      expect(Levenshtein.distance('hello', 'jello'), equals(1.0));
      expect(Levenshtein.distance('abc', 'xyz'), equals(3.0));
    });

    test('complex transformations', () {
      expect(Levenshtein.distance('kitten', 'sitting'), equals(3.0));
      expect(Levenshtein.distance('saturday', 'sunday'), equals(3.0));
      expect(Levenshtein.distance('intention', 'execution'), equals(5.0));
    });

    test('case sensitivity', () {
      expect(Levenshtein.distance('Hello', 'hello'), equals(1.0));
      expect(Levenshtein.distance('TEST', 'test'), equals(4.0));
      expect(Levenshtein.distance('CamelCase', 'camelcase'), equals(2.0));
    });

    test('maximum distance parameter', () {
      // Should return early if distance exceeds maximum
      expect(Levenshtein.distance('hello', 'world', 3.0), greaterThan(3.0));
      expect(Levenshtein.distance('abc', 'xyz', 2.0), greaterThan(2.0));
      
      // Should return actual distance if within maximum
      expect(Levenshtein.distance('cat', 'bat', 5.0), equals(1.0));
      expect(Levenshtein.distance('hello', 'hallo', 5.0), equals(1.0));
    });

    test('string order independence', () {
      // Distance should be the same regardless of parameter order
      expect(
        Levenshtein.distance('hello', 'world'),
        equals(Levenshtein.distance('world', 'hello')),
      );
      expect(
        Levenshtein.distance('abc', 'def'),
        equals(Levenshtein.distance('def', 'abc')),
      );
    });

    test('special characters and numbers', () {
      expect(Levenshtein.distance('hello!', 'hello?'), equals(1.0));
      expect(Levenshtein.distance('test123', 'test456'), equals(3.0));
      expect(Levenshtein.distance('a@b.com', 'a@c.com'), equals(1.0));
      expect(Levenshtein.distance('file.txt', 'file.pdf'), equals(3.0));
    });

    test('unicode characters', () {
      expect(Levenshtein.distance('café', 'cafe'), equals(1.0));
      expect(Levenshtein.distance('naïve', 'naive'), equals(1.0));
      expect(Levenshtein.distance('🙂', '😊'), equals(1.0));
    });

    test('long strings performance', () {
      final longString1 = 'a' * 100;
      final longString2 = 'b' * 100;
      
      // Should complete in reasonable time
      final stopwatch = Stopwatch()..start();
      final distance = Levenshtein.distance(longString1, longString2);
      stopwatch.stop();
      
      expect(distance, equals(100.0));
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast
    });
  });

  group('Levenshtein rankItems Tests', () {
    test('empty input handling', () async {
      final emptyItems = <String>[];
      final result = await Levenshtein.rankItems(
        emptyItems,
        'test',
        (item) => [item],
      );
      expect(result, isEmpty);

      final items = ['apple', 'banana'];
      final emptyQuery = await Levenshtein.rankItems(
        items,
        '',
        (item) => [item],
      );
      expect(emptyQuery, equals(items));
    });

    test('exact matches get highest priority (score 0)', () async {
      final items = ['apple', 'application', 'app'];
      final result = await Levenshtein.rankItems(
        items,
        'app',
        (item) => [item],
      );
      
      expect(result.first, equals('app')); // Exact match should be first
    });

    test('substring matches prioritized over levenshtein', () async {
      final items = ['application', 'cat', 'bat']; // 'cat' and 'bat' have distance 1 from 'app', but 'application' contains 'app'
      final result = await Levenshtein.rankItems(
        items,
        'app',
        (item) => [item],
      );
      
      expect(result.first, equals('application')); // Substring match should beat Levenshtein distance
    });

    test('ranking by substring quality', () async {
      final items = ['app store', 'application', 'happy']; // Different substring match qualities
      final result = await Levenshtein.rankItems(
        items,
        'app',
        (item) => [item],
      );
      
      // 'app store' should rank higher than 'application' (better coverage)
      // 'happy' contains 'app' but with less coverage
      expect(result.indexOf('app store'), lessThan(result.indexOf('application')));
      expect(result.indexOf('application'), lessThan(result.indexOf('happy')));
    });

    test('token-based substring matching', () async {
      final items = ['john smith', 'jane doe', 'bob johnson'];
      final result = await Levenshtein.rankItems(
        items,
        'john doe',
        (item) => [item],
      );
      
      // Both 'john smith' and 'bob johnson' contain 'john'
      // 'jane doe' contains 'doe'
      // All should be found via substring matching
      expect(result, contains('john smith'));
      expect(result, contains('jane doe'));
      expect(result, contains('bob johnson'));
    });

    test('levenshtein fallback for no substring matches', () async {
      final items = ['cat', 'bat', 'rat', 'elephant'];
      final result = await Levenshtein.rankItems(
        items,
        'hat', // No exact or substring matches, falls back to Levenshtein
        (item) => [item],
      );
      
      // Should be ordered by Levenshtein distance from 'hat'
      expect(result.first, isIn(['cat', 'bat', 'rat'])); // Distance 1
      expect(result.last, equals('elephant')); // Highest distance
    });

    test('multiple factors per item with mixed matching', () async {
      final items = [
        {'name': 'John Application Developer', 'email': 'john@test.com'},
        {'name': 'Jane Smith', 'email': 'jane@app.com'},
        {'name': 'Bob Johnson', 'email': 'bob@example.com'},
      ];
      
      final result = await Levenshtein.rankItems(
        items,
        'app',
        (item) => [item['name']!, item['email']!],
      );
      
      // Should prioritize substring matches in name/email over Levenshtein distance
      final firstResult = result.first;
      expect(
        firstResult['name']!.toLowerCase().contains('app') || 
        firstResult['email']!.toLowerCase().contains('app'),
        isTrue,
      );
    });

    test('case insensitive substring matching', () async {
      final items = ['Apple Store', 'HAPPY HOUR', 'application'];
      final result = await Levenshtein.rankItems(
        items,
        'app',
        (item) => [item],
      );
      
      // All contain 'app' in different cases
      expect(result, contains('Apple Store'));
      expect(result, contains('HAPPY HOUR'));
      expect(result, contains('application'));
    });

    test('custom comparator for tie-breaking within same score range', () async {
      final items = ['zapp', 'bapp', 'aapp']; // All have same substring match quality
      final result = await Levenshtein.rankItems(
        items,
        'app',
        (item) => [item],
        (a, b) => a.compareTo(b), // Alphabetical order for ties
      );
      
      // Should be sorted alphabetically within the same score range
      expect(result, equals(['aapp', 'bapp', 'zapp']));
    });

    test('minimum token length filtering', () async {
      final items = ['abc', 'application', 'test'];
      final result = await Levenshtein.rankItems(
        items,
        'a b app', // 'a' and 'b' are too short for token matching
        (item) => [item],
      );
      
      // Should find 'application' via 'app' token, others via Levenshtein
      expect(result.first, equals('application'));
    });
  });

  group('Levenshtein convenience methods', () {
    test('searchStrings method', () async {
      final strings = ['apple', 'application', 'banana', 'app'];
      final result = await Levenshtein.searchStrings(strings, 'app');
      
      expect(result.first, equals('app')); // Exact match first
      expect(result, contains('apple'));
      expect(result, contains('application'));
    });

    test('searchAdvanced method', () async {
      final products = [
        {'name': 'iPhone', 'category': 'Electronics'},
        {'name': 'MacBook', 'category': 'Computers'},
        {'name': 'Phone Case', 'category': 'Accessories'},
      ];
      
      final result = await Levenshtein.searchAdvanced(
        products,
        'phone',
        fields: (p) => [p['name']!, p['category']!],
        maxResults: 10,
      );
      
      expect(result.length, lessThanOrEqualTo(10));
      // Should find items with 'phone' in name
      expect(result.any((p) => p['name']!.toLowerCase().contains('phone')), isTrue);
    });
  });
}
