import 'package:flutter/material.dart';
import 'dart:math';

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
  List<String> lastResults = []; // Теперь хранит строки с результатами всех монет за бросок

  void addBatchResult(List<String> results) {
    totalFlips += results.length;
    for (String result in results) {
      if (result == 'орёл') {
        heads++;
      } else {
        tails++;
      }
    }
    
    // Формируем строку с результатами всех монет за один бросок
    String batchResult = results.join(' · ');
    lastResults.insert(0, batchResult);
    if (lastResults.length > 5) {
      lastResults.removeLast();
    }
  }

  void reset() {
    totalFlips = 0;
    heads = 0;
    tails = 0;
    lastResults.clear();
  }

  double get headsPercentage => totalFlips > 0 ? (heads / totalFlips * 100) : 0;
  double get tailsPercentage => totalFlips > 0 ? (tails / totalFlips * 100) : 0;
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
  Statistics statistics = Statistics();

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

    int flipCount = _random.nextInt(6) + 10; // от 10 до 15
    
    // Анимация переключения изображений
    for (int i = 0; i < flipCount; i++) {
      await Future.delayed(Duration(milliseconds: 100));
      
      if (mounted) {
        setState(() {
          // Визуальное переключение для каждой монеты
          for (int j = 0; j < coinCount; j++) {
            coinResults[j] = _random.nextBool() ? 'орёл' : 'решка';
          }
        });
      }
    }

    // Финальный результат для каждой монеты
    List<String> finalResults = [];
    for (int i = 0; i < coinCount; i++) {
      String result = _random.nextBool() ? 'орёл' : 'решка';
      finalResults.add(result);
    }
    
    // Добавляем все результаты как один бросок
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
    
    // Рассчитываем позицию для каждой монеты (смещаем чуть левее для центрирования)
    double screenWidth = MediaQuery.of(context).size.width;
    double startPosition = screenWidth / 2 - size / 2 - 10; // Смещение влево на 10px
    
    if (coinCount == 1) {
      horizontalPosition = startPosition;
    } else if (coinCount == 2) {
      horizontalPosition = index == 0 
          ? startPosition - 60 
          : startPosition + 60;
    } else if (coinCount == 3) {
      if (index == 0) horizontalPosition = startPosition - 90;
      else if (index == 1) horizontalPosition = startPosition;
      else horizontalPosition = startPosition + 90;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подбрасывание монетки'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
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

// Экран статистики
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
              
              // Поля статистики
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
              
              // Последние броски
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
              
              // Кнопка сброса
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
              
              // Кнопка возврата на главный экран
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
