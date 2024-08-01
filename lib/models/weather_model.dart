import 'package:hive/hive.dart';

part 'weather_model.g.dart';

@HiveType(typeId: 0)
class Weather {
  @HiveField(0)
  final String cityName;

  @HiveField(1)
  final double temperature;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final List<Forecast> forecast;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.forecast,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'],
      temperature: json['main']['temp'],
      description: json['weather'][0]['description'],
      forecast: [], // Will be updated later
    );
  }
}

@HiveType(typeId: 1)
class Forecast {
  @HiveField(0)
  final String dateTime;

  @HiveField(1)
  final double temperature;

  @HiveField(2)
  final String description;

  Forecast({
    required this.dateTime,
    required this.temperature,
    required this.description,
  });

  factory Forecast.fromJson(Map<String, dynamic> json) {
    return Forecast(
      dateTime: json['dt_txt'],
      temperature: json['main']['temp'],
      description: json['weather'][0]['description'],
    );
  }
}
