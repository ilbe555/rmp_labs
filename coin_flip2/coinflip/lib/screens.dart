import 'package:flutter/material.dart';
import 'view_models.dart';
import 'coin_api_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late MainViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = MainViewModel(
      statistics: Statistics(),
      apiService: ApiService(),
    );
    viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  children: List.generate(viewModel.coinCount, (index) => buildCoin(index)),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Результаты бросков
              if (viewModel.coinCount > 1)
                Column(
                  children: [
                    const Text('Результаты:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 10,
                      children: viewModel.coinResults.asMap().entries.map((entry) {
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
                    viewModel.coinResults[0],
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Кнопка броска
              ElevatedButton(
                onPressed: viewModel.isFlipping ? null : () => viewModel.flipCoins(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                ),
                child: Text(
                  viewModel.isFlipping ? 'Бросаем...' : 'Бросить монету',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Счетчик монет
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Количество монет: ${viewModel.coinCount}',
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
                          onPressed: viewModel.isFlipping ? null : viewModel.decrementCoins,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: viewModel.isFlipping ? null : viewModel.incrementCoins,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Блок предсказания
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
                    
                    if (viewModel.prediction.isLoading)
                      const CircularProgressIndicator()
                    else if (viewModel.prediction.error != null)
                      Text(
                        viewModel.prediction.error!,
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
                          '"${viewModel.prediction.text}"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 15),
                    
                    ElevatedButton.icon(
                      onPressed: viewModel.prediction.isLoading ? null : () => viewModel.getPrediction(),
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
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StatsScreen(
                        statistics: viewModel.statistics,
                      ),
                    ),
                  );
                  viewModel.refreshStatistics();
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

  Widget buildCoin(int index) {
    double size = viewModel.coinCount == 1 ? 150.0 : (viewModel.coinCount == 2 ? 100.0 : 80.0);
    double horizontalPosition = 0.0;
    
    double screenWidth = MediaQuery.of(context).size.width;
    double startPosition = screenWidth / 2 - size / 2 - 10; 
    
    if (viewModel.coinCount == 1) {
      horizontalPosition = startPosition;
    } else if (viewModel.coinCount == 2) {
      horizontalPosition = index == 0 
          ? startPosition - 60 
          : startPosition + 60;
    } else if (viewModel.coinCount == 3) {
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
        child: viewModel.coinResults[index] == 'орёл'
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
}

class StatsScreen extends StatefulWidget {
  final Statistics statistics;

  const StatsScreen({super.key, required this.statistics});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late StatsViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = StatsViewModel(statistics: widget.statistics);
  }

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
                onPressed: () async {
                  await viewModel.reset();
                  setState(() {});
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