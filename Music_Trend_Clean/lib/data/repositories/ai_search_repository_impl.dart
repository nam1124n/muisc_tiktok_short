import 'package:login_flutter/app/config/ai_config.dart';
import 'package:login_flutter/data/datasource/remote/ollama_ai_remote_data_source.dart';
import 'package:login_flutter/domain/entities/search_plan_entity.dart';
import 'package:login_flutter/domain/repositories/ai_search_repository.dart';

class AiSearchRepositoryImpl implements AiSearchRepository {
  final OllamaAiRemoteDataSource remoteDataSource;
  final List<String> localBaseUrls;
  final String localModel;
  final String cloudBaseUrl;
  final String cloudModel;

  AiSearchRepositoryImpl(
    this.remoteDataSource, {
    String? localBaseUrl,
    List<String>? localBaseUrls,
    String? localModel,
    String? cloudBaseUrl,
    String? cloudModel,
  }) : localBaseUrls = _resolveLocalBaseUrls(
         localBaseUrl: localBaseUrl,
         localBaseUrls: localBaseUrls,
       ),
       localModel = localModel ?? AiConfig.localModel,
       cloudBaseUrl = cloudBaseUrl ?? AiConfig.cloudBaseUrl,
       cloudModel = cloudModel ?? AiConfig.cloudModel;

  @override
  Future<SearchPlanEntity> analyzeQuery(String query) async {
    final localErrors = <String>[];
    Object? cloudError;

    for (final baseUrl in localBaseUrls) {
      try {
        final data = await remoteDataSource.analyzeQuery(
          baseUrl: baseUrl,
          query: query,
          model: localModel,
        );
        return _map(query, data, 'local');
      } catch (error) {
        localErrors.add('$baseUrl -> ${_cleanError(error)}');
      }
    }

    if (cloudBaseUrl.isNotEmpty) {
      try {
        final data = await remoteDataSource.analyzeQuery(
          baseUrl: cloudBaseUrl,
          query: query,
          model: cloudModel,
        );
        return _map(query, data, 'cloud');
      } catch (error) {
        cloudError = error;
      }
    }

    return SearchPlanEntity(
      originalQuery: query,
      keywords: query.toLowerCase().split(' '),
      artistHints: const [],
      titleHints: const [],
      tagHints: const [],
      provider: 'rule',
      reason: _buildFallbackReason(
        localErrors: localErrors,
        cloudError: cloudError,
      ),
    );
  }

  SearchPlanEntity _map(
    String query,
    Map<String, dynamic> data,
    String provider,
  ) {
    List<String> readList(String key) => ((data[key] as List?) ?? [])
        .map((e) => e.toString().toLowerCase())
        .toList();

    return SearchPlanEntity(
      originalQuery: query,
      keywords: readList('keywords'),
      artistHints: readList('artistHints'),
      titleHints: readList('titleHints'),
      tagHints: readList('tagHints'),
      provider: provider,
      reason: data['reason']?.toString() ?? '',
    );
  }

  String _buildFallbackReason({
    required List<String> localErrors,
    Object? cloudError,
  }) {
    final parts = <String>['Fallback search thuong'];

    if (localErrors.isNotEmpty) {
      parts.add('Local AI loi: ${localErrors.join(' | ')}');
    }

    if (cloudError != null) {
      parts.add('Cloud AI loi: ${_cleanError(cloudError)}');
    }

    return parts.join('. ');
  }

  String _cleanError(Object error) {
    const prefix = 'Exception: ';
    final message = error.toString();
    if (message.startsWith(prefix)) {
      return message.substring(prefix.length);
    }
    return message;
  }

  static List<String> _resolveLocalBaseUrls({
    String? localBaseUrl,
    List<String>? localBaseUrls,
  }) {
    final normalizedBaseUrls = [
      ...?localBaseUrls,
      ?localBaseUrl,
    ].map((value) => value.trim()).where((value) => value.isNotEmpty).toSet();

    if (normalizedBaseUrls.isNotEmpty) {
      return normalizedBaseUrls.toList();
    }

    return AiConfig.localBaseUrls;
  }
}
