class Exercise {
  Exercise({
    required this.idSource,
    required this.name,
    this.description,
    this.mediaUrl,
    this.muscleGroup,
    this.type,
    this.difficulty,
    this.equipment,
    this.safetyInfo,
    this.instructions,
    this.source = 'api_ninjas',
  });

  final String idSource;
  final String name;
  final String? description;
  final String? mediaUrl;
  final String? muscleGroup;
  final String? type;
  final String? difficulty;
  final List<String>? equipment;
  final String? safetyInfo;
  final String? instructions;
  final String source;

  Map<String, Object?> toJson() => {
        'idSource': idSource,
        'source': source,
        'name': name,
        'description': description,
        'mediaUrl': mediaUrl,
        'muscleGroup': muscleGroup,
        'type': type,
        'difficulty': difficulty,
        'equipment': equipment,
        'safetyInfo': safetyInfo,
        'instructions': instructions,
      };
}
