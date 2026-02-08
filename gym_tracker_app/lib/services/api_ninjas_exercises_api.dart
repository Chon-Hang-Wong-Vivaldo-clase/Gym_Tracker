import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:gym_tracker_app/models/exercise.dart';

class ApiNinjasExercisesApi {
  ApiNinjasExercisesApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://api.api-ninjas.com/v1/exercises';

  Future<List<Exercise>> fetchExercises({
    required String apiKey,
    String? name,
    String? type,
    String? muscle,
    String? difficulty,
    List<String>? equipments,
    int? offset,
  }) async {
    final query = <String, String>{};
    if (name != null && name.trim().isNotEmpty) query['name'] = name.trim();
    if (type != null && type.trim().isNotEmpty) query['type'] = type.trim();
    if (muscle != null && muscle.trim().isNotEmpty) query['muscle'] = muscle.trim();
    if (difficulty != null && difficulty.trim().isNotEmpty) {
      query['difficulty'] = difficulty.trim();
    }
    if (equipments != null && equipments.isNotEmpty) {
      query['equipments'] =
          equipments.map((e) => e.trim()).where((e) => e.isNotEmpty).join(',');
    }
    if (offset != null && offset >= 0) query['offset'] = offset.toString();

    final uri = Uri.parse(_baseUrl).replace(queryParameters: query.isEmpty ? null : query);
    final res = await _client.get(
      uri,
      headers: {
        'X-Api-Key': apiKey,
        'Accept': 'application/json',
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API Ninjas error ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw Exception('Unexpected response type');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map((json) => _mapExercise(json))
        .whereType<Exercise>()
        .toList();
  }

  Exercise? _mapExercise(Map<String, dynamic> json) {
    final name = json['name'];
    if (name == null) return null;

    final muscle = json['muscle']?.toString();
    final type = json['type']?.toString();
    final idSource = _buildIdSource(name.toString(), muscle, type);

    return Exercise(
      idSource: idSource,
      name: name.toString(),
      description: json['instructions']?.toString(),
      muscleGroup: muscle,
      type: type,
      difficulty: json['difficulty']?.toString(),
      equipment: _parseEquipment(json['equipment'] ?? json['equipments']),
      safetyInfo: json['safety_info']?.toString(),
      instructions: json['instructions']?.toString(),
    );
  }

  List<String>? _parseEquipment(Object? raw) {
    if (raw == null) return null;
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  String _buildIdSource(String name, String? muscle, String? type) {
    final base = [name, muscle, type].where((v) => v != null && v.trim().isNotEmpty).join('|');
    return base.isEmpty ? name : base;
  }
}
