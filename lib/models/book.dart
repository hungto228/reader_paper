class Chapter {
  final int id;
  final String title;
  final String content;
  final int unlockCost;
  bool isUnlocked;

  Chapter({
    required this.id,
    required this.title,
    required this.content,
    required this.unlockCost,
    this.isUnlocked = false,
  });
}

class Book {
  final String title;
  final String author;
  final List<Chapter> chapters;

  Book({
    required this.title,
    required this.author,
    required this.chapters,
  });
}

class CoinManager {
  int _coins = 100; // Start with 100 coins

  int get coins => _coins;

  bool canUnlockChapter(int cost) {
    return _coins >= cost;
  }

  bool unlockChapter(int cost) {
    if (canUnlockChapter(cost)) {
      _coins -= cost;
      return true;
    }
    return false;
  }

  void addCoins(int amount) {
    _coins += amount;
  }
} 