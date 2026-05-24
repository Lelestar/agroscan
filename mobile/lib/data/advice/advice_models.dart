class AdviceSymptom {
  const AdviceSymptom({required this.text, this.isPrimary = false});

  final String text;
  final bool isPrimary;

  factory AdviceSymptom.fromJson(Map<String, dynamic> json) => AdviceSymptom(
        text: json['text'] as String,
        isPrimary: json['isPrimary'] as bool? ?? false,
      );
}

class AdviceStep {
  const AdviceStep({required this.title, required this.description});

  final String title;
  final String description;

  factory AdviceStep.fromJson(Map<String, dynamic> json) => AdviceStep(
        title: json['title'] as String,
        description: json['description'] as String,
      );
}

class DiseaseAdvice {
  const DiseaseAdvice({
    required this.key,
    required this.title,
    required this.category,
    required this.description,
    required this.symptoms,
    required this.steps,
    required this.disclaimer,
  });

  final String key;
  final String title;
  final String category;
  final String description;
  final List<AdviceSymptom> symptoms;
  final List<AdviceStep> steps;
  final String disclaimer;

  factory DiseaseAdvice.fromJson(Map<String, dynamic> json) => DiseaseAdvice(
        key: json['key'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        description: json['description'] as String,
        symptoms: (json['symptoms'] as List<dynamic>)
            .map((e) => AdviceSymptom.fromJson(e as Map<String, dynamic>))
            .toList(),
        steps: (json['steps'] as List<dynamic>)
            .map((e) => AdviceStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        disclaimer: json['disclaimer'] as String,
      );
}
