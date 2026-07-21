# T4-4a: preference_service.dart (F5好みプロファイル) の検証スクリプト。
# 設計書§12②の運用方針に従い、Dart実装前にscipyで同一アルゴリズムを検証してから
# test/preference_service_test.dartの期待値を決める。
#
# 設計書§9.6のフィクスチャ(グループA=[8,9,8,9,8]、残り=[5,6,5,6,5,6,5,6,5,6])を
# そのまま使用。
#
# 実行方法: python tools/verify_preference.py
import numpy as np
from scipy import stats

group_a = np.array([8, 9, 8, 9, 8], dtype=float)
rest = np.array([5, 6, 5, 6, 5, 6, 5, 6, 5, 6], dtype=float)

n_a, n_rest = len(group_a), len(rest)
mean_a, mean_rest = group_a.mean(), rest.mean()
var_a, var_rest = group_a.var(ddof=1), rest.var(ddof=1)  # 不偏分散 (n-1)
sd_a = np.sqrt(var_a)

print(f"group A: n={n_a}, mean={mean_a}, sd={sd_a:.6f}")
print(f"rest:    n={n_rest}, mean={mean_rest}, sd={np.sqrt(var_rest):.6f}")

# Welch t検定 (T-23, T-24)
se2 = var_a / n_a + var_rest / n_rest
t = (mean_a - mean_rest) / np.sqrt(se2)
df = se2**2 / ((var_a / n_a) ** 2 / (n_a - 1) + (var_rest / n_rest) ** 2 / (n_rest - 1))
p = 2 * (1 - stats.t.cdf(abs(t), df))
print(f"\nWelch t (T-23) = {t:.6f}")
print(f"df (T-24, Welch-Satterthwaite) = {df:.6f}")
print(f"p (two-sided) = {p:.8e}")

# scipyの直接呼び出しとの突き合わせ
tt = stats.ttest_ind(group_a, rest, equal_var=False)
print(f"\nscipy.stats.ttest_ind(equal_var=False): t={tt.statistic:.6f}, df={tt.df:.6f}, p={tt.pvalue:.8e}")

# 平均の95%信頼区間 (T-22)
t_crit = stats.t.ppf(0.975, n_a - 1)
half_width = t_crit * sd_a / np.sqrt(n_a)
print(f"\nt_{{0.975,{n_a - 1}}} = {t_crit:.6f}")
print(f"CI half-width = {half_width:.6f}")
print(f"CI = [{mean_a - half_width:.6f}, {mean_a + half_width:.6f}]")
