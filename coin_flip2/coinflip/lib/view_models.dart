import 'dart:math';
import 'package:flutter/material.dart';
import 'coin_models.dart';
import 'coin_api_service.dart';

export 'coin_models.dart'; // чтобы экраны могли использовать Statistics и Prediction

class MainViewModel extends ChangeNotifier {
  final Statistics statistics;
  final ApiService apiService;

  int coinCount = 1;
  List<String> coinResults = ['решка'];
  bool isFlipping = false;
  Prediction prediction = Prediction();

  final Random _random = Random();

  MainViewModel({required this.statistics, required this.apiService}) {
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    await statistics.loadFromPreferences();
    notifyListeners();
  }

  void incrementCoins() {
    if (coinCount < 3) {
      coinCount++;
      coinResults.add('решка');
      notifyListeners();
    }
  }

  void decrementCoins() {
    if (coinCount > 1) {
      coinCount--;
      coinResults.removeLast();
      notifyListeners();
    }
  }

  Future<void> flipCoins() async {
    if (isFlipping) return;

    isFlipping = true;
    notifyListeners();

    int flipCount = _random.nextInt(6) + 10;
    
    for (int i = 0; i < flipCount; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      
      for (int j = 0; j < coinCount; j++) {
        coinResults[j] = _random.nextBool() ? 'орёл' : 'решка';
      }
      notifyListeners();
    }

    List<String> finalResults = [];
    for (int i = 0; i < coinCount; i++) {
      String result = _random.nextBool() ? 'орёл' : 'решка';
      finalResults.add(result);
    }
    
    statistics.addBatchResult(finalResults);
    coinResults = finalResults;
    isFlipping = false;
    notifyListeners();
  }

  Future<void> getPrediction() async {
    prediction.isLoading = true;
    prediction.error = null;
    notifyListeners();

    final advice = await apiService.getPrediction();
    if (advice != null) {
      prediction.text = advice;
      prediction.isLoading = false;
    } else {
      prediction.error = 'Не удалось получить предсказание';
      prediction.isLoading = false;
      prediction.text = 'Попробуйте позже';
    }
    notifyListeners();
  }

  void refreshStatistics() {
    notifyListeners();
  }
}

class StatsViewModel {
  final Statistics statistics;

  StatsViewModel({required this.statistics});

  Future<void> reset() async {
    statistics.reset();
  }
}