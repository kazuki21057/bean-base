import 'package:json_annotation/json_annotation.dart';

part 'analysis_snapshot.g.dart';

/// 統計解析結果の履歴スナップショット (設計書§7.2)。
///
/// モデル自体はT4-1d(データ基盤/F6)でDataService配線の一部として先行導入する。
/// 実際に生成・保存するロジック(PreferenceService.build()結果の自動保存等)は
/// T4-4b(F5)以降で実装する。
@JsonSerializable()
class AnalysisSnapshot {
  @JsonKey(defaultValue: '', fromJson: _parseString)
  final String id;
  @JsonKey(fromJson: _parseDateTime)
  final DateTime createdAt;
  @JsonKey(defaultValue: '')
  final String type;
  @JsonKey(fromJson: _parseInt)
  final int dataCount;
  @JsonKey(defaultValue: '')
  final String payloadJson;

  AnalysisSnapshot({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.dataCount,
    required this.payloadJson,
  });

  factory AnalysisSnapshot.fromJson(Map<String, dynamic> json) =>
      _$AnalysisSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisSnapshotToJson(this);

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      if (value.trim().isEmpty) return DateTime.now();
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) {
      if (value.trim().isEmpty) return 0;
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  AnalysisSnapshot copyWith({
    String? id,
    DateTime? createdAt,
    String? type,
    int? dataCount,
    String? payloadJson,
  }) {
    return AnalysisSnapshot(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      dataCount: dataCount ?? this.dataCount,
      payloadJson: payloadJson ?? this.payloadJson,
    );
  }
}
