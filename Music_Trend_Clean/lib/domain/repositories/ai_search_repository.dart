import 'package:login_flutter/domain/entities/search_plan_entity.dart';

abstract class AiSearchRepository {
  Future<SearchPlanEntity> analyzeQuery(String query);
}
