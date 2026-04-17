import 'package:login_flutter/domain/entities/search_plan_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';

abstract class SearchState {
  const SearchState();
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  final List<SongEntity> previewResults;

  const SearchLoading({this.previewResults = const []});
}

class SearchLoaded extends SearchState {
  final List<SongEntity> results;
  final SearchPlanEntity plan;

  const SearchLoaded({required this.results, required this.plan});
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);
}
