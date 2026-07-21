# T4-3a: PCA(F2)の相関行列ベース化 (statistics_service.dart calculatePca) の
# 検証スクリプト。設計書§12②の運用方針に従い、Dart実装前にnumpyで同一アルゴリズムを
# 検証してからtest/statistics_service_test.dartの期待値を決める。
#
# test/statistics_service_test.dart の3件フィクスチャ(Fragrance/Acidity/
# Bitterness/Sweetness/Complexity/Flavor)をそのまま使用。
#
# 実行方法: python tools/verify_pca.py
import numpy as np

# featureNames = ['Fragrance', 'Acidity', 'Bitterness', 'Sweetness', 'Complexity', 'Flavor']
records = np.array([
    [7, 7, 7, 7, 7, 7],  # record 1
    [8, 8, 6, 8, 8, 8],  # record 2
    [6, 6, 8, 6, 6, 6],  # record 3
], dtype=float)

n, m = records.shape
means = records.mean(axis=0)
stds = records.std(axis=0, ddof=1)  # 不偏標準偏差 (n-1)
print("means:", means)
print("stds:", stds)

z = (records - means) / stds
r = z.T @ z / (n - 1)
print("\ncorrelation matrix R:")
print(np.round(r, 6))

eigenvalues, eigenvectors = np.linalg.eigh(r)
order = np.argsort(eigenvalues)[::-1]
eigenvalues = eigenvalues[order]
eigenvectors = eigenvectors[:, order]

print("\neigenvalues (descending):", np.round(eigenvalues, 6))
print("sum of eigenvalues (should equal m=%d):" % m, np.round(eigenvalues.sum(), 6))

contribution_ratios = eigenvalues / m
cumulative = np.cumsum(contribution_ratios)
print("\ncontribution ratios (T-13):", np.round(contribution_ratios, 6))
print("cumulative ratios (T-14):", np.round(cumulative, 6))

print("\nPC1 eigenvector:", np.round(eigenvectors[:, 0], 6))
print("PC2 eigenvector:", np.round(eigenvectors[:, 1], 6))

loadings_pc1 = eigenvectors[:, 0] * np.sqrt(max(eigenvalues[0], 0.0))
loadings_pc2 = eigenvectors[:, 1] * np.sqrt(max(eigenvalues[1], 0.0))
print("\nPC1 loadings (T-15):", np.round(loadings_pc1, 6))
print("PC2 loadings (T-15):", np.round(loadings_pc2, 6))

scores = z @ eigenvectors[:, :2]
print("\nPC1/PC2 scores (T-12) per record:")
print(np.round(scores, 6))
