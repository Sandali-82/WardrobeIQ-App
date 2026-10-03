import '../models/worn_log.dart';
import '../services/api_service.dart';

abstract class WornLogRepository {
  static WornLogRepository instance = _WornLogRepositoryImpl();

  Future<List<WornLog>> getRange({required DateTime from, required DateTime to});
  Future<void> log({required String outfitId, required DateTime dateWorn});
  Future<void> delete(String id);
}

class _WornLogRepositoryImpl implements WornLogRepository {
  ApiService get _api => ApiService.instance;

  @override
  Future<List<WornLog>> getRange({required DateTime from, required DateTime to}) =>
      _api.getWornLogs(from: from, to: to);

  @override
  Future<void> log({required String outfitId, required DateTime dateWorn}) =>
      _api.logWornOutfit(outfitId: outfitId, dateWorn: dateWorn);

  @override
  Future<void> delete(String id) => _api.deleteWornLog(id);
}