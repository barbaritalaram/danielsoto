import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}


class ColmenaData {
  final double peso;
  final String fechaHora;
  final String color;
  final double porcentaje;

  ColmenaData({
    required this.peso,
    required this.fechaHora,
    required this.color,
    required this.porcentaje,
  });

  factory ColmenaData.fromJson(Map<dynamic, dynamic> json) {
    return ColmenaData(
      peso: json['peso'].toDouble(),
      fechaHora: json['fechaHora'],
      color: json['color'],
      porcentaje: json['porcentaje'].toDouble(),
    );
  }
}

class ColmenaProvider extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('colmenas/colmena1');
  ColmenaData? _ultimoDato;
  List<ColmenaData> _historial = [];
  double _umbralAlerta = 80.0; // Porcentaje de umbral para alerta

  ColmenaData? get ultimoDato => _ultimoDato;
  List<ColmenaData> get historial => _historial;
  double get umbralAlerta => _umbralAlerta;

  ColmenaProvider() {
    _database.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = ColmenaData.fromJson(event.snapshot.value as Map<dynamic, dynamic>);
        _ultimoDato = data;
        _historial.add(data);
        if (_historial.length > 10) _historial.removeAt(0);
        notifyListeners();
      }
    });
  }

  void setUmbralAlerta(double valor) {
    _umbralAlerta = valor;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ColmenaProvider(),
      child: MaterialApp(
        title: 'Monitor de Colmena',
        theme: ThemeData(
          primarySwatch: Colors.amber,
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor de Colmena'),
        centerTitle: true,
      ),
      body: Consumer<ColmenaProvider>(
        builder: (context, colmenaProvider, child) {
          final ultimoDato = colmenaProvider.ultimoDato;
          
          if (ultimoDato == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Verificar si se superó el umbral
          if (ultimoDato.porcentaje > colmenaProvider.umbralAlerta) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('¡Alerta!'),
                  content: Text('El peso ha superado el ${colmenaProvider.umbralAlerta}% del umbral'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Última lectura: ${ultimoDato.fechaHora}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Peso: ${ultimoDato.peso.toStringAsFixed(2)} kg',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Porcentaje: ${ultimoDato.porcentaje.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 20,
                            color: _getColorPorPorcentaje(ultimoDato.porcentaje),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Historial de Pesos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: colmenaProvider.historial
                              .asMap()
                              .entries
                              .map((e) => FlSpot(
                                    e.key.toDouble(),
                                    e.value.peso,
                                  ))
                              .toList(),
                          isCurved: true,
                          color: Colors.amber,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Configuración de Umbral',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: colmenaProvider.umbralAlerta,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '${colmenaProvider.umbralAlerta.toStringAsFixed(0)}%',
                          onChanged: (value) {
                            colmenaProvider.setUmbralAlerta(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getColorPorPorcentaje(double porcentaje) {
    if (porcentaje < 25) return Colors.red;
    if (porcentaje < 50) return Colors.orange;
    if (porcentaje < 75) return Colors.yellow;
    return Colors.green;
  }
} 