import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/app_controller.dart';
import '../models/book.dart';
import 'coin_animation.dart';

class ChapterList extends StatefulWidget {
  const ChapterList({Key? key}) : super(key: key);

  @override
  State<ChapterList> createState() => _ChapterListState();
}

class _ChapterListState extends State<ChapterList> {
  bool _isAnimating = false;
  final AppController controller = Get.find<AppController>();
  final GlobalKey _coinBalanceKey = GlobalKey();
  final Map<int, GlobalKey> _unlockButtonKeys = {};
  Offset? _coinBalancePosition;
  Offset? _unlockButtonPosition;
  Chapter? _pendingUnlockChapter;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      appBar: AppBar(
        title: Text(controller.book.value.title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Container(
            key: _coinBalanceKey,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Obx(() => Text(
                  '${controller.coinManager.value.coins}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.book.value.chapters.length,
            itemBuilder: (context, index) {
              final chapter = controller.book.value.chapters[index];
              return _buildChapterCard(context, chapter);
            },
          ),
          if (_isAnimating && _coinBalancePosition != null && _unlockButtonPosition != null)
            Positioned.fill(
              child: CoinAnimation(
                coinCount: 5,
                startPosition: _coinBalancePosition!,
                endPosition: _unlockButtonPosition!,
                onComplete: () {
                  setState(() {
                    _isAnimating = false;
                    if (_pendingUnlockChapter != null) {
                      if (controller.canUnlockChapter(_pendingUnlockChapter!.id)) {
                        controller.unlockChapter(_pendingUnlockChapter!.id);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Not enough coins!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      _pendingUnlockChapter = null;
                    }
                  });
                },
              ),
            ),
        ],
      ),
    ));
  }

  Widget _buildChapterCard(BuildContext context, Chapter chapter) {
    final isUnlocked = chapter.isUnlocked;
    final canUnlock = controller.canUnlockChapter(chapter.id);

    // Create a unique key for each unlock button
    if (!_unlockButtonKeys.containsKey(chapter.id)) {
      _unlockButtonKeys[chapter.id] = GlobalKey();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isUnlocked ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isUnlocked ? Icons.lock_open : Icons.lock,
            color: Colors.white,
          ),
        ),
        title: Text(
          chapter.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isUnlocked ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (!isUnlocked)
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${chapter.unlockCost} coins',
                    style: const TextStyle(color: Colors.amber),
                  ),
                ],
              ),
          ],
        ),
        trailing: isUnlocked
            ? const Icon(Icons.arrow_forward_ios, color: Colors.green)
            : ElevatedButton(
                key: _unlockButtonKeys[chapter.id],
                onPressed: canUnlock
                    ? () => _unlockChapter(chapter)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                ),
                child: Text('Unlock (${chapter.unlockCost})'),
              ),
        onTap: isUnlocked
            ? () => _openChapter(chapter)
            : null,
      ),
    );
  }

  void _unlockChapter(Chapter chapter) {
    _tryGetPositionsBeforeUnlock(chapter.id, chapter);
  }

  void _tryGetPositionsBeforeUnlock(int chapterId, Chapter chapter, {int retry = 2}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final coinBalanceRenderBox = _coinBalanceKey.currentContext?.findRenderObject() as RenderBox?;
      final unlockButtonRenderBox = _unlockButtonKeys[chapterId]?.currentContext?.findRenderObject() as RenderBox?;

      if (coinBalanceRenderBox != null && unlockButtonRenderBox != null) {
        // Calculate center positions more accurately
        final coinBalanceCenter = coinBalanceRenderBox.localToGlobal(
          Offset(coinBalanceRenderBox.size.width / 2, coinBalanceRenderBox.size.height / 2)
        );
        final unlockButtonCenter = unlockButtonRenderBox.localToGlobal(
          Offset(unlockButtonRenderBox.size.width / 2, unlockButtonRenderBox.size.height / 2)
        );
        
        setState(() {
          _coinBalancePosition = coinBalanceCenter;
          _unlockButtonPosition = unlockButtonCenter;
          _isAnimating = true;
          _pendingUnlockChapter = chapter;
        });
        print('Animation started with positions: $_coinBalancePosition -> $_unlockButtonPosition');
      } else if (retry > 0) {
        print('Failed to get render boxes, retrying...');
        Future.delayed(const Duration(milliseconds: 50), () {
          _tryGetPositionsBeforeUnlock(chapterId, chapter, retry: retry - 1);
        });
      } else {
        print('Failed to get render boxes after retries');
      }
    });
  }
  void _openChapter(Chapter chapter) {
    Get.to(() => ReadingScreen(chapter: chapter));
  }
}

class ReadingScreen extends StatelessWidget {
  final Chapter chapter;

  const ReadingScreen({Key? key, required this.chapter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AppController controller = Get.find<AppController>();
    return Obx(() => Scaffold(
      appBar: AppBar(
        title: Text(chapter.title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              controller.isSlidingMode.value ? Icons.view_agenda : Icons.view_column,
            ),
            onPressed: () {
              controller.toggleReadingMode();
            },
            tooltip: 'Toggle reading mode',
          ),
        ],
      ),
      body: controller.isSlidingMode.value
          ? _buildSlidingMode()
          : _buildScrollingMode(),
    ));
  }

  Widget _buildSlidingMode() {
    final pages = _splitContentIntoPages(chapter.content);
    return PageView.builder(
      itemCount: pages.length,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    pages[index],
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Page ${index + 1} of ${pages.length}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScrollingMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Text(
        chapter.content,
        style: const TextStyle(
          fontSize: 18,
          height: 1.6,
        ),
      ),
    );
  }

  List<String> _splitContentIntoPages(String content) {
    const wordsPerPage = 300;
    final words = content.split(' ');
    final pages = <String>[];
    for (int i = 0; i < words.length; i += wordsPerPage) {
      final end = (i + wordsPerPage < words.length) ? i + wordsPerPage : words.length;
      pages.add(words.sublist(i, end).join(' '));
    }
    return pages;
  }
} 