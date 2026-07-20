import '../models/origin_master.dart';
import 'data_service.dart';

/// 産地文字列の正規化辞書(設計書§3.3、完全一致・前後空白除去・大文字小文字無視)。
const originAliasMap = {
  'エチオピア': 'ET', 'ethiopia': 'ET', 'ケニア': 'KE', 'kenya': 'KE',
  'ブラジル': 'BR', 'brazil': 'BR', 'コロンビア': 'CO', 'colombia': 'CO',
  'グアテマラ': 'GT', 'guatemala': 'GT', 'コスタリカ': 'CR',
  'ホンジュラス': 'HN', 'ペルー': 'PE', 'タンザニア': 'TZ',
  'ルワンダ': 'RW', 'インドネシア': 'ID', 'マンデリン': 'ID',
  'ベトナム': 'VN', 'インド': 'IN', 'イエメン': 'YE', 'ブレンド': 'XX',
};

class MigrationResult {
  final int totalBeans;
  final int alreadyMapped;
  final int matched;
  final List<String> unmatchedOrigins;

  MigrationResult({
    required this.totalBeans,
    required this.alreadyMapped,
    required this.matched,
    required this.unmatchedOrigins,
  });
}

/// 産地の名寄せ移行 (T4-1f、設計書§3.3)。
class MigrationService {
  /// 冪等な自動移行。`originId`が既に入っている豆はスキップする。
  /// `origin`文字列を[originAliasMap]で正規化・突合し、一致すれば`originId`を
  /// 更新する。突合できなかった`origin`文字列は[MigrationResult.unmatchedOrigins]
  /// に集約する(ユーザーが[confirmManualMapping]で手動確定する)。
  Future<MigrationResult> runAutoMigration(DataService dataService) async {
    final beans = await dataService.getBeans();
    final origins = await dataService.fetchOriginMasters();
    final originByCountryCode = {for (final o in origins) o.countryCode: o};

    var alreadyMapped = 0;
    var matched = 0;
    final unmatched = <String>{};

    for (final bean in beans) {
      if (bean.originId.isNotEmpty) {
        alreadyMapped++;
        continue;
      }
      final originText = bean.origin.trim();
      if (originText.isEmpty) continue;

      final code =
          originAliasMap[originText] ?? originAliasMap[originText.toLowerCase()];
      final resolved = code != null ? originByCountryCode[code] : null;

      if (resolved != null) {
        await dataService.updateBean(bean.copyWith(originId: resolved.id));
        matched++;
      } else {
        unmatched.add(originText);
      }
    }

    return MigrationResult(
      totalBeans: beans.length,
      alreadyMapped: alreadyMapped,
      matched: matched,
      unmatchedOrigins: unmatched.toList()..sort(),
    );
  }

  /// 自動突合できなかった[originText]を、ユーザーが選んだ[origin]へ手動で確定する。
  /// 該当する`origin`文字列を持つ豆(`originId`未設定のもの)すべての`originId`を更新し、
  /// 更新件数を返す。
  Future<int> confirmManualMapping(
    DataService dataService,
    String originText,
    OriginMaster origin,
  ) async {
    final beans = await dataService.getBeans();
    var count = 0;
    for (final bean in beans) {
      if (bean.originId.isNotEmpty) continue;
      if (bean.origin.trim() != originText) continue;
      await dataService.updateBean(bean.copyWith(originId: origin.id));
      count++;
    }
    return count;
  }
}
