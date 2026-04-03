import 'package:shared_preferences/shared_preferences.dart';

// Модель для статистики
class Statistics {
  int totalFlips = 0;
  int heads = 0;
  int tails = 0;
  List<String> lastResults = [];

  void addBatchResult(List<String> results) {
    totalFlips += results.length;
    for (String result in results) {
      if (result == 'орёл') {
        heads++;
      } else {
        tails++;
      }
    }
    
    String batchResult = results.join(' · ');
    lastResults.insert(0, batchResult);
    if (lastResults.length > 5) {
      lastResults.removeLast();
    }
    
    _saveToPreferences();
  }

  void reset() {
    totalFlips = 0;
    heads = 0;
    tails = 0;
    lastResults.clear();
    _saveToPreferences();
  }

  double get headsPercentage => totalFlips > 0 ? (heads / totalFlips * 100) : 0;
  double get tailsPercentage => totalFlips > 0 ? (tails / totalFlips * 100) : 0;

  Future<void> loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    totalFlips = prefs.getInt('totalFlips') ?? 0;
    heads = prefs.getInt('heads') ?? 0;
    tails = prefs.getInt('tails') ?? 0;
    
    List<String>? savedResults = prefs.getStringList('lastResults');
    if (savedResults != null) {
      lastResults = savedResults;
    }
  }

  Future<void> _saveToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt('totalFlips', totalFlips);
    await prefs.setInt('heads', heads);
    await prefs.setInt('tails', tails);
    await prefs.setStringList('lastResults', lastResults);
  }
}

// Модель для предсказания
class Prediction {
  String text;
  bool isLoading;
  String? error;

  Prediction({this.text = 'Нажмите кнопку для предсказания', this.isLoading = false, this.error});
}