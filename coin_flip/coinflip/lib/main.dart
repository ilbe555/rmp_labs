import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Виртуальная монетка',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

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

// Главный экран
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int coinCount = 1;
  List<String> coinResults = ['решка'];
  bool isFlipping = false;
  final Random _random = Random();
  late Statistics statistics;
  bool _isLoading = true;
  
  // Для API предсказаний
  Prediction prediction = Prediction();

  @override
  void initState() {
    super.initState();
    statistics = Statistics();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    await statistics.loadFromPreferences();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Метод для получения предсказания из API
  Future<void> getPrediction() async {
    setState(() {
      prediction.isLoading = true;
      prediction.error = null;
    });

    try {
      // Используем бесплатное API советов
      final response = await http.get(
        Uri.parse('https://api.adviceslip.com/advice'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          prediction.text = data['slip']['advice'];
          prediction.isLoading = false;
        });
      } else {
        throw Exception('Ошибка загрузки');
      }
    } catch (e) {
      setState(() {
        prediction.error = 'Не удалось получить предсказание';
        prediction.isLoading = false;
        prediction.text = 'Попробуйте позже';
      });
    }
  }

  void incrementCoins() {
    if (coinCount < 3) {
      setState(() {
        coinCount++;
        coinResults.add('решка');
      });
    }
  }

  void decrementCoins() {
    if (coinCount > 1) {
      setState(() {
        coinCount--;
        coinResults.removeLast();
      });
    }
  }

  Future<void> flipCoins() async {
    if (isFlipping) return;

    setState(() {
      isFlipping = true;
    });

    int flipCount = _random.nextInt(6) + 10;
    
    for (int i = 0; i < flipCount; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        setState(() {
          for (int j = 0; j < coinCount; j++) {
            coinResults[j] = _random.nextBool() ? 'орёл' : 'решка';
          }
        });
      }
    }

    List<String> finalResults = [];
    for (int i = 0; i < coinCount; i++) {
      String result = _random.nextBool() ? 'орёл' : 'решка';
      finalResults.add(result);
    }
    
    statistics.addBatchResult(finalResults);

    if (mounted) {
      setState(() {
        coinResults = finalResults;
        isFlipping = false;
      });
    }
  }

  Widget buildCoin(int index) {
    double size = coinCount == 1 ? 150.0 : (coinCount == 2 ? 100.0 : 80.0);
    double horizontalPosition = 0.0;
    
    double screenWidth = MediaQuery.of(context).size.width;
    double startPosition = screenWidth / 2 - size / 2 - 10; 
    
    if (coinCount == 1) {
      horizontalPosition = startPosition;
    } else if (coinCount == 2) {
      horizontalPosition = index == 0 
          ? startPosition - 60 
          : startPosition + 60;
    } else if (coinCount == 3) {
      if (index == 0) {
        horizontalPosition = startPosition - 90;
      } else if (index == 1) {
        horizontalPosition = startPosition;
      } else {
        horizontalPosition = startPosition + 90;
      }
    }

    return Positioned(
      left: horizontalPosition,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.amber,
          border: Border.all(color: Colors.brown, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: coinResults[index] == 'орёл'
            ? _buildEagle(size)
            : Center(
                child: Text(
                  '1',
                  style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }

  Widget _buildEagle(double size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: size * 0.13,
            height: size * 0.13,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
          ),
          SizedBox(height: size * 0.03),
          Container(
            width: size * 0.2,
            height: size * 0.1,
            decoration: BoxDecoration(
              color: Colors.brown,
              borderRadius: BorderRadius.circular(size * 0.03),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Подбрасывание монетки'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Контейнер для монет
              SizedBox(
                height: 170,
                child: Stack(
                  children: List.generate(coinCount, (index) => buildCoin(index)),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Результаты бросков
              if (coinCount > 1)
                Column(
                  children: [
                    const Text('Результаты:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 10,
                      children: coinResults.asMap().entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            'Монета ${entry.key + 1}: ${entry.value}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    coinResults[0],
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Кнопка броска
              ElevatedButton(
                onPressed: isFlipping ? null : flipCoins,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                ),
                child: Text(
                  isFlipping ? 'Бросаем...' : 'Бросить монету',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Счетчик монет
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Количество монет: $coinCount',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: isFlipping ? null : decrementCoins,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: isFlipping ? null : incrementCoins,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // НОВЫЙ БЛОК: Предсказание дня из API
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.purple, width: 2),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🌟 ПРЕДСКАЗАНИЕ ДНЯ 🌟',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Отображение предсказания или загрузки/ошибки
                    if (prediction.isLoading)
                      const CircularProgressIndicator()
                    else if (prediction.error != null)
                      Text(
                        prediction.error!,
                        style: const TextStyle(color: Colors.red),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '"${prediction.text}"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 15),
                    
                    // Кнопка получения предсказания
                    ElevatedButton.icon(
                      onPressed: prediction.isLoading ? null : getPrediction,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Получить предсказание'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Кнопка перехода на статистику
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StatsScreen(statistics: statistics),
                    ),
                  ).then((_) => setState(() {}));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                ),
                child: const Text(
                  'Статистика',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Экран статистики (без изменений)
class StatsScreen extends StatefulWidget {
  final Statistics statistics;

  const StatsScreen({super.key, required this.statistics});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'СТАТИСТИКА',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              
              const SizedBox(height: 30),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      'Всего бросков: ${widget.statistics.totalFlips}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Количество решек: ${widget.statistics.tails}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Количество орлов: ${widget.statistics.heads}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Процент орёл/решка: ${widget.statistics.headsPercentage.toStringAsFixed(1)}% / ${widget.statistics.tailsPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              const Text(
                'Последние броски:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              
              const SizedBox(height: 10),
              
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: widget.statistics.lastResults.isEmpty
                      ? [const Text('Нет бросков', style: TextStyle(fontSize: 16))]
                      : widget.statistics.lastResults.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Text(
                              'Бросок ${entry.key + 1}: ${entry.value}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
                ),
              ),
              
              const SizedBox(height: 30),
              
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    widget.statistics.reset();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                ),
                child: const Text(
                  'Сброс',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              
              const SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                ),
                child: const Text(
                  'Монетка',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}