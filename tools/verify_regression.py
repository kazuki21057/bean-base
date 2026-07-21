"""T4-2a/2b(F1重回帰分析)のテスト期待値をnumpyで検証・算出するスクリプト。
設計書§9.4に記載の固定10行データに対する期待値が、Dart実装とは独立の
経路(numpy.linalg.lstsq)で導出した値と一致するかを確認するために使う
(§12②の運用方針: Python検証スクリプトを作成しローカル実行する)。

2026-07-21: 設計書§9.4に記載の期待値(β0=1.02667等)が、このデータの実際の
最小二乗解と一致しないことが判明(Node.jsのガウス消去でも同じ結果を確認済み)。
本スクリプトの出力を正としてstatistics_feature_design.md §9.4と
test/regression_service_test.dartを更新する。
"""
import numpy as np

x1 = np.array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], dtype=float)
x2 = np.array([2, 1, 4, 3, 6, 5, 8, 7, 10, 9], dtype=float)
y = np.array([3.1, 3.9, 6.2, 6.8, 9.1, 9.9, 12.2, 12.8, 15.1, 15.9])

X = np.column_stack([np.ones(10), x1, x2])
n, p1 = X.shape
p = p1 - 1

beta, _, _, _ = np.linalg.lstsq(X, y, rcond=None)
fitted = X @ beta
resid = y - fitted
rss = float(np.sum(resid ** 2))
df = n - p - 1
sigma2 = rss / df
sigma_hat = float(np.sqrt(sigma2))

xtx_inv = np.linalg.inv(X.T @ X)
se = np.sqrt(sigma2 * np.diag(xtx_inv))

ybar = y.mean()
tss = float(np.sum((y - ybar) ** 2))
r2 = 1 - rss / tss
adj_r2 = 1 - (1 - r2) * (n - 1) / df
aic = n * np.log(rss / n) + 2 * (p + 2)

print("beta:", beta)
print("se:", se)
print("rss:", rss, "sigma_hat:", sigma_hat)
print("r2:", r2, "adj_r2:", adj_r2)
print("aic:", aic)

# 完全共線データ(x2=2*x1)の検証: 特異行列になることを確認
x1b = np.array([1, 2, 3, 4, 5], dtype=float)
x2b = 2 * x1b
Xb = np.column_stack([np.ones(5), x1b, x2b])
rank = np.linalg.matrix_rank(Xb)
print("collinear rank (should be < 3):", rank)

# y=2xの完全適合データ
x1c = np.array([1, 2, 3, 4, 5], dtype=float)
yc = 2 * x1c
Xc = np.column_stack([np.ones(5), x1c])
betac, _, _, _ = np.linalg.lstsq(Xc, yc, rcond=None)
residc = yc - Xc @ betac
print("perfect fit beta:", betac, "resid:", residc)
