import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neonflake/models/weather_model.dart';

class ApiService {
  final String apiKey = 'Your_api';
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<Weather> fetchCurrentWeather(String city) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather?q=$city&appid=$apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      print("Current Weather Response: ${response.body}");
      return Weather.fromJson(json.decode(response.body));
    } else {
      print("Failed to load Weather data: Try Searching Other City (●'◡'●)");
      throw Exception('Failed to load weather data');
    }
  }

  Future<List<Forecast>> fetch5DayForecast(String city) async {
    final response = await http.get(
      Uri.parse('$baseUrl/forecast?q=$city&appid=$apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      print("5-Day Forecast Response: ${response.body}");
      List<dynamic> forecastList = json.decode(response.body)['list'];
      return forecastList.map((data) => Forecast.fromJson(data)).toList();
    } else {
      print("Failed to load forecast data: Try Searching Other City (●'◡'●)");
      throw Exception('Failed to load forecast data');
    }
  }

  Future<List<String>> fetchCitySuggestions(String query) async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$apiKey'),
    );

    if (response.statusCode == 200) {
      print("City Suggestions Response: ${response.body}");
      List<dynamic> cityList = json.decode(response.body);
      return cityList.map((city) => city['name'] as String).toList();
    } else {
      print("Failed to load city suggestions");
      throw Exception('Failed to load city suggestions');
    }
  }
}
