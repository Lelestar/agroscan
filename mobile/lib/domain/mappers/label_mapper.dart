import '../../core/constants.dart';
import '../models/diagnosis_display.dart';
import 'advice_key.dart';

/// Maps PlantVillage technical labels to French UI copy.
class LabelMapper {
  static const _plantNames = {
    'Apple': 'Pommier',
    'Blueberry': 'Bleuet',
    'Cherry': 'Cerisier',
    'Corn': 'Maïs',
    'Grape': 'Vigne',
    'Orange': 'Oranger',
    'Peach': 'Pêcher',
    'Pepper,_bell': 'Poivron',
    'Potato': 'Pomme de terre',
    'Raspberry': 'Framboisier',
    'Soybean': 'Soja',
    'Squash': 'Courge',
    'Strawberry': 'Fraisier',
    'Tomato': 'Tomate',
  };

  static const _diseaseNames = {
    'Apple_scab': 'Tavelure',
    'Black_rot': 'Pourriture noire',
    'Cedar_apple_rust': 'Rouille du cèdre',
    'Powdery_mildew': 'Oïdium',
    'Cercospora_leaf_spot Gray_leaf_spot': 'Taches foliaires',
    'Common_rust': 'Rouille commune',
    'Northern_Leaf_Blight': 'Brûlure nordique',
    'Esca_(Black_Measles)': 'Esca',
    'Leaf_blight_(Isariopsis_Leaf_Spot)': 'Brûlure foliaire',
    'Haunglongbing_(Citrus_greening)': 'Huanglongbing',
    'Bacterial_spot': 'Tache bactérienne',
    'Early_blight': 'Alternariose',
    'Late_blight': 'Mildiou',
    'Leaf_scorch': 'Brûlure des feuilles',
    'Leaf_Mold': 'Moisissure foliaire',
    'Septoria_leaf_spot': 'Septoriose',
    'Spider_mites Two-spotted_spider_mite': 'Acariens',
    'Target_Spot': 'Taches cibles',
    'Tomato_mosaic_virus': 'Virus de la mosaïque',
    'Tomato_Yellow_Leaf_Curl_Virus': 'Virus de l\'enroulement',
  };

  DiagnosisDisplay map(String rawLabel, double confidence) {
    final parts = rawLabel.split('___');
    final plantKey = parts.first;
    final condition = parts.length > 1 ? parts.sublist(1).join('___') : '';
    final plantName = _plantNames[plantKey] ?? _humanize(plantKey);
    final isHealthy = condition == 'healthy';

    String? diseaseName;
    String headline;

    if (isHealthy) {
      diseaseName = null;
      headline = 'Feuille probablement saine';
    } else {
      diseaseName = _diseaseNames[condition] ?? _humanize(condition);
      headline = '$diseaseName de la ${_plantGenitive(plantName)} suspecté';
    }

    if (confidence < AgroConstants.lowConfidenceThreshold) {
      if (isHealthy) {
        headline = 'Feuille possiblement saine';
      } else {
        final name = diseaseName ?? 'Symptôme';
        headline = '$name possible';
      }
    }

    final adviceKey = adviceKeyFromRawLabel(rawLabel);

    return DiagnosisDisplay(
      plantName: plantName,
      diseaseName: diseaseName,
      headline: headline,
      isHealthy: isHealthy,
      confidence: confidence,
      adviceKey: adviceKey,
      rawLabel: rawLabel,
    );
  }

  static String _plantGenitive(String plant) {
    if (plant == 'Tomate') return 'tomate';
    if (plant == 'Pommier') return 'pomme';
    return plant.toLowerCase();
  }

  static String _humanize(String value) =>
      value.replaceAll('_', ' ').replaceAll(',', '');
}
