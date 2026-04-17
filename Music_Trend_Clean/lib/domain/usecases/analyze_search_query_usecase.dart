import 'package:login_flutter/domain/entities/search_plan_entity.dart';
import 'package:login_flutter/domain/repositories/ai_search_repository.dart';

class AnalyzeSearchQueryUseCase {
  final AiSearchRepository repository;
  AnalyzeSearchQueryUseCase(this.repository);

  Future<SearchPlanEntity> call(String query) {
    return repository.analyzeQuery(query);
  }
}
