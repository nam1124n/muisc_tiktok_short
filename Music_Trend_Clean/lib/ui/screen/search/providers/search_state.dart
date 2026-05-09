import 'package:equatable/equatable.dart';
import 'package:login_flutter/domain/entities/search_plan_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';

enum SearchStatus { idle, searching, loaded, empty, error }

const _searchNoChange = Object();

class SearchState extends Equatable {
  const SearchState({
    required this.status,
    required this.query,
    required this.results,
    required this.plan,
    required this.errorMessage,
  });

  const SearchState.idle()
    : this(
        status: SearchStatus.idle,
        query: '',
        results: const [],
        plan: null,
        errorMessage: null,
      );

  final SearchStatus status;
  final String query;
  final List<SongEntity> results;
  final SearchPlanEntity? plan;
  final String? errorMessage;

  bool get isIdle => status == SearchStatus.idle;

  bool get isSearching => status == SearchStatus.searching;

  bool get hasResults => status == SearchStatus.loaded && results.isNotEmpty;

  bool get isEmpty => status == SearchStatus.empty;

  bool get hasError =>
      status == SearchStatus.error &&
      errorMessage != null &&
      errorMessage!.trim().isNotEmpty;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<SongEntity>? results,
    Object? plan = _searchNoChange,
    Object? errorMessage = _searchNoChange,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      plan: plan == _searchNoChange ? this.plan : plan as SearchPlanEntity?,
      errorMessage: errorMessage == _searchNoChange
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, query, results, plan, errorMessage];
}
