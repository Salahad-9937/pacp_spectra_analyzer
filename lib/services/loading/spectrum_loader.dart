import '../../domain/models.dart';

abstract class SpectrumLoader {
  Future<SpectrumData> load(String path);
}