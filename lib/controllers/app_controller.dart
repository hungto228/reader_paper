import 'package:get/get.dart';
import '../models/book.dart';
import '../data/book_data.dart';

class AppController extends GetxController {
  final book = BookData.getSampleBook().obs;
  final coinManager = CoinManager().obs;
  final isSlidingMode = true.obs;

  void toggleReadingMode() {
    isSlidingMode.value = !isSlidingMode.value;
  }

  bool unlockChapter(int chapterId) {
    final chapter = book.value.chapters.firstWhere((c) => c.id == chapterId);
    if (!chapter.isUnlocked && coinManager.value.unlockChapter(chapter.unlockCost)) {
      chapter.isUnlocked = true;
      book.refresh();
      coinManager.refresh();
      return true;
    }
    return false;
  }

  bool canUnlockChapter(int chapterId) {
    final chapter = book.value.chapters.firstWhere((c) => c.id == chapterId);
    return !chapter.isUnlocked && coinManager.value.canUnlockChapter(chapter.unlockCost);
  }

  void addCoins(int amount) {
    coinManager.value.addCoins(amount);
    coinManager.refresh();
  }
} 