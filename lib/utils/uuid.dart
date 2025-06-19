class UUID {
  static String generate(String string) {
    final words =
        string.split(' ').where((word) => word.isNotEmpty).map((word) => word.trim()).toList();

    final result = words.map((word) {
      // Keep numbers and words that only contain consonants
      if (RegExp(r'^[bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ0-9]+$').hasMatch(word)) {
        return word;
      }

      // If word starts with vowel, keep it
      final startsWithVowel = RegExp(r'^[aeiouAEIOU]').hasMatch(word);
      final firstChar = startsWithVowel ? word[0] : '';

      // Remove vowels from rest of word
      final restOfWord = startsWithVowel ? word.substring(1) : word;
      final consonants = restOfWord.replaceAll(RegExp(r'[aeiouAEIOU]'), '');

      if (consonants.length <= 3) return firstChar + consonants;

      // Keep first consonant, last consonant, and up to 2 middle consonants
      final first = consonants[0];
      final last = consonants[consonants.length - 1];
      final middle = consonants.substring(1, consonants.length - 1);
      final middlePart = middle.length <= 2 ? middle : middle.substring(0, 2);

      return firstChar + first + middlePart + last;
    }).where((word) => word.isNotEmpty);

    return result.join('-').toUpperCase();
  }
}
