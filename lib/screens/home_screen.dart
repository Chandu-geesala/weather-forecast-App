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
  bool _isLoading = false; // Flag to manage loading state
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
      _isLoading = true; // Show loading animation
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
        _isLoading = false; // Hide loading animation
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
      case 'heavy intensity rain':
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
        return '🌈'; // Default emoji
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
              SizedBox(height: 50), // Indentation above the search bar
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              if (_isLoading) ...[
                Center(
                  child: CircularProgressIndicator(), // Loading animation
                ),
              ] else if (_weather != null) ...[
                Text(
                  _weather!.cityName,
                  style: TextStyle(fontSize: 27, color: Colors.white),
                ),
                Text(
                  '${_weather!.temperature.round()}°C', // Rounded temperature
                  style: TextStyle(fontSize: 46, color: Colors.white),
                ),
                Text(
                  '${_weather!.description.capitalizeFirstLetter} ${_getEmojiForDescription(_weather!.description)}', // Capitalize the first letter of the description and append the emoji
                  style: TextStyle(fontSize: 25, color: Colors.white),
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
                              DateFormat.Hm().format(DateTime.parse(forecast.dateTime)), // Hourly time without seconds
                              style: TextStyle(color: Colors.black),
                            ),
                            Text(
                              _getEmojiForDescription(forecast.description),
                              style: TextStyle(color: Colors.black),
                            ),
                            Text(
                              '${forecast.temperature.round()}°C', // Rounded temperature
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
                            DateFormat.yMMMd().format(DateTime.parse(forecast.dateTime)), // Date
                            style: TextStyle(color: Colors.black),
                          ),
                          subtitle: Text(
                            'Temp: ${forecast.temperature.round()}°C, ${_getEmojiForDescription(forecast.description)} ${forecast.description.capitalizeFirstLetter}', // Rounded temperature, capitalized description, and emoji
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
    _controller.removeStatusListener((status) {});
    _controller.dispose();
    super.dispose();
  }
}

class BackgroundPainter extends CustomPainter {
  final Animation<double> animation;

  const BackgroundPainter(this.animation);

  Offset getOffset(Path path) {
    final pms = path.computeMetrics(forceClosed: false).elementAt(0);
    final length = pms.length;
    final offset = pms.getTangentForOffset(length * animation.value)!.position;
    return offset;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.maskFilter = const MaskFilter.blur(
      BlurStyle.normal,
      30,
    );
    drawShape1(canvas, size, paint, Colors.white);
    drawShape2(canvas, size, paint, Colors.white);
    drawShape3(canvas, size, paint, Colors.blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }

  void drawShape1(
      Canvas canvas,
      Size size,
      Paint paint,
      Color color,
      ) {
    paint.color = color;
    Path path = Path();

    path.moveTo(size.width, 0);
    path.quadraticBezierTo(
      size.width / 2,
      size.height / 2,
      -100,
      size.height / 4,
    );

    final offset = getOffset(path);
    canvas.drawCircle(offset, 150, paint);
  }

  void drawShape2(
      Canvas canvas,
      Size size,
      Paint paint,
      Color color,
      ) {
    paint.color = color;
    Path path = Path();

    path.moveTo(size.width, size.height);
    path.quadraticBezierTo(
      size.width / 2,
      size.height / 2,
      size.width * 0.9,
      size.height * 0.9,
    );

    final offset = getOffset(path);
    canvas.drawCircle(offset, 250, paint);
  }

  void drawShape3(
      Canvas canvas,
      Size size,
      Paint paint,
      Color color,
      ) {
    paint.color = color;
    Path path = Path();

    path.moveTo(0, 0);
    path.quadraticBezierTo(
      0,
      size.height,
      size.width / 3,
      size.height / 3,
    );

    final offset = getOffset(path);
    canvas.drawCircle(offset, 250, paint);
  }
}
