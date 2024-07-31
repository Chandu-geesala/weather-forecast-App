import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neonflake/services/api_services.dart';
import 'package:neonflake/models/weather_model.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

extension Capitalize on String {
  String get capitalizeFirstLetter {
    if (this == null || this.isEmpty) {
      return this;
    }
    return this[0].toUpperCase() + this.substring(1).toLowerCase();
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _cityController = TextEditingController();
  final ApiService _apiService = ApiService();
  Weather? _weather;
  List<Forecast>? _forecast;
  bool _isLoading = false;
  List<String> _citySuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadSavedCity();
  }

  Future<void> _loadSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString('selected_city');
    if (savedCity != null) {
      _fetchWeatherData(savedCity);
    }
  }

  Future<void> _fetchWeatherData(String city) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final weather = await _apiService.fetchCurrentWeather(city);
      final forecast = await _apiService.fetch5DayForecast(city);
      setState(() {
        _weather = weather;
        _forecast = forecast;
      });
      _saveWeatherData(weather, forecast);
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load weather data: $e'),
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveWeatherData(Weather weather, List<Forecast> forecast) async {
    final weatherBox = await Hive.openBox('weatherBox');
    weatherBox.put('weather', weather);
    weatherBox.put('forecast', forecast);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('selected_city', weather.cityName);
  }

  String _getEmojiForDescription(String description) {
    switch (description.toLowerCase()) {
      case 'clear sky':
        return '☀️';
      case 'few clouds':
        return '🌤';
      case 'scattered clouds':
        return '☁️';
      case 'broken clouds':
        return '🌥';
      case 'shower rain':
        return '🌧';
      case 'rain':
        return '🌦';
      case 'thunderstorm':
        return '⛈';
      case 'snow':
        return '❄️';
      case 'mist':
        return '🌫';
      case 'light rain':
        return '🌦';
      case 'overcast clouds':
        return '☁️';
      case 'moderate rain':
        return '🌧';
      default:
        return '🌈';
    }
  }

  Future<void> _fetchCitySuggestions(String query) async {
    try {
      final suggestions = await _apiService.fetchCitySuggestions(query);
      setState(() {
        _citySuggestions = suggestions;
      });
    } catch (e) {
      print("Error fetching city suggestions: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundShapes(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 50),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.isEmpty) {
                    return [];
                  }
                  await _fetchCitySuggestions(textEditingValue.text);
                  return _citySuggestions;
                },
                onSelected: (String selectedCity) {
                  _fetchWeatherData(selectedCity);
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Enter city name',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      child: Container(
                        width: MediaQuery.of(context).size.width - 32,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              onTap: () {
                                onSelected(option);
                              },
                              title: Text(option),
                              tileColor: Colors.white,
                              leading: Icon(Icons.location_city),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              if (_isLoading) ...[
                Center(
                  child: CircularProgressIndicator(),
                ),
              ] else if (_weather != null) ...[
                Text(
                  _weather!.cityName,
                  style: TextStyle(fontSize: 27, color: Colors.white),
                ),
                Text(
                  '${_weather!.temperature.round()}°C',
                  style: TextStyle(fontSize: 46, color: Colors.white),
                ),
                Text(
                  '${_weather!.description.capitalizeFirstLetter} ${_getEmojiForDescription(_weather!.description)}',
                  style: TextStyle(fontSize: 32, color: Colors.white),
                ),
                SizedBox(height: 20),
                Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _forecast?.length ?? 0,
                    itemBuilder: (context, index) {
                      final forecast = _forecast![index];
                      return Container(
                        width: 50,
                        margin: EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat.Hm().format(DateTime.parse(forecast.dateTime)),
                              style: TextStyle(color: Colors.black),
                            ),
                            Text(
                              _getEmojiForDescription(forecast.description),
                              style: TextStyle(color: Colors.black),
                            ),
                            Text(
                              '${forecast.temperature.round()}°C',
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _forecast?.length ?? 0,
                    itemBuilder: (context, index) {
                      final forecast = _forecast![index];
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          title: Text(
                            DateFormat.yMMMd().format(DateTime.parse(forecast.dateTime)),
                            style: TextStyle(color: Colors.black),
                          ),
                          subtitle: Text(
                            'Temp: ${forecast.temperature.round()}°C, ${_getEmojiForDescription(forecast.description)} ${forecast.description.capitalizeFirstLetter}',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class BackgroundShapes extends StatefulWidget {
  const BackgroundShapes({
    required this.child,
  });

  final Widget child;

  @override
  State<BackgroundShapes> createState() => _BackgroundShapesState();
}

class _BackgroundShapesState extends State<BackgroundShapes>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);
    _controller.repeat(reverse: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: BackgroundPainter(_animation),
                child: Container(),
              );
            },
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(
              color: Colors.black.withOpacity(0.1),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class BackgroundPainter extends CustomPainter {
  final Animation<double> _animation;

  BackgroundPainter(this._animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white,
          Colors.blue,
        ],
        stops: [_animation.value, _animation.value],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
