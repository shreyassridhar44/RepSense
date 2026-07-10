/// Pure utility class for unit conversions
class UnitConverter {
  UnitConverter._();

  // Height conversions
  static double cmToInches(double cm) => cm / 2.54;
  static double inchesToCm(double inches) => inches * 2.54;

  static ({int feet, int inches}) cmToFeetInches(double cm) {
    final totalInches = cmToInches(cm).round();
    return (feet: totalInches ~/ 12, inches: totalInches % 12);
  }

  static double feetInchesToCm(int feet, int inches) {
    return inchesToCm((feet * 12 + inches).toDouble());
  }

  // Weight conversions
  static double kgToLbs(double kg) => kg * 2.20462;
  static double lbsToKg(double lbs) => lbs / 2.20462;

  // Display formatting
  static String formatHeightMetric(double cm) => '${cm.round()} cm';

  static String formatHeightImperial(double cm) {
    final converted = cmToFeetInches(cm);
    return "${converted.feet}'${converted.inches}\"";
  }

  static String formatWeightMetric(double kg) => '${kg.round()} kg';
  static String formatWeightImperial(double kg) => '${kgToLbs(kg).round()} lbs';
}
