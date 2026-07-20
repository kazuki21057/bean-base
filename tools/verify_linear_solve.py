"""T4-0b検証スクリプト。

lib/services/math/linear_solve.dart の cholesky/choleskySolve/choleskyInverse/
choleskyLogDet と同じアルゴリズムをPythonで再実装し、numpyの結果および
statistics_feature_design.md §9.2 のテスト期待値と突き合わせて検証する。

実行方法: python tools/verify_linear_solve.py
依存: numpy (pip install numpy)
"""

import numpy as np


def cholesky(a):
    """linear_solve.dart の cholesky と同一のアルゴリズム(Cholesky-Banachiewicz)。"""
    a = np.array(a, dtype=float)
    n = a.shape[0]
    l = np.zeros((n, n))
    for i in range(n):
        for j in range(i + 1):
            s = sum(l[i, k] * l[j, k] for k in range(j))
            if i == j:
                diag = a[i, i] - s
                if diag <= 0:
                    raise ValueError("行列が正定値ではありません")
                l[i, j] = np.sqrt(diag)
            else:
                l[i, j] = (a[i, j] - s) / l[j, j]
    return l


def cholesky_solve(l, b):
    n = l.shape[0]
    b = np.array(b, dtype=float)
    # forward: L y = b
    y = np.zeros(n)
    for i in range(n):
        s = sum(l[i, k] * y[k] for k in range(i))
        y[i] = (b[i] - s) / l[i, i]
    # backward: L^T x = y
    x = np.zeros(n)
    for i in reversed(range(n)):
        s = sum(l[k, i] * x[k] for k in range(i + 1, n))
        x[i] = (y[i] - s) / l[i, i]
    return x


def cholesky_log_det(l):
    return 2 * sum(np.log(l[i, i]) for i in range(l.shape[0]))


def cholesky_inverse(l):
    n = l.shape[0]
    inv = np.zeros((n, n))
    for i in range(n):
        e = np.zeros(n)
        e[i] = 1.0
        inv[:, i] = cholesky_solve(l, e)
    return inv


def main():
    results = []

    # §9.2-1: A=[[4,2],[2,3]], b=[10,8] -> L=[[2,0],[1,sqrt(2)]], x=[1.75,1.5]
    a = [[4, 2], [2, 3]]
    b = [10, 8]
    l = cholesky(a)
    x = cholesky_solve(l, b)
    expected_l = np.array([[2, 0], [1, np.sqrt(2)]])
    expected_x = np.array([1.75, 1.5])
    print("--- case1: A=[[4,2],[2,3]], b=[10,8] ---")
    print(f"L = {l.tolist()}, expected = {expected_l.tolist()}")
    print(f"x = {x.tolist()}, expected = {expected_x.tolist()}")
    ok1 = np.allclose(l, expected_l, atol=1e-10) and np.allclose(x, expected_x, atol=1e-10)
    # numpyのL(下三角)とも一致するか
    np_l = np.linalg.cholesky(np.array(a, dtype=float))
    np_x = np.linalg.solve(a, b)
    ok1 = ok1 and np.allclose(l, np_l, atol=1e-10) and np.allclose(x, np_x, atol=1e-10)
    print("OK" if ok1 else "MISMATCH")
    print()
    results.append(ok1)

    # §9.2-2: 非正定値 [[1,2],[2,1]] -> エラー
    print("--- case2: 非正定値 [[1,2],[2,1]] ---")
    try:
        cholesky([[1, 2], [2, 1]])
        print("MISMATCH (エラーにならなかった)")
        results.append(False)
    except ValueError as e:
        print(f"raised: {e}")
        print("OK")
        results.append(True)
    print()

    # §9.2-3: choleskyLogDet(L) = ln(8)
    logdet = cholesky_log_det(l)
    expected_logdet = np.log(8)
    np_logdet = np.log(np.linalg.det(np.array(a, dtype=float)))
    print("--- case3: choleskyLogDet ---")
    print(f"logdet = {logdet}, expected = ln(8) = {expected_logdet}, numpy det logでも {np_logdet}")
    ok3 = abs(logdet - expected_logdet) < 1e-10 and abs(logdet - np_logdet) < 1e-8
    print("OK" if ok3 else "MISMATCH")
    print()
    results.append(ok3)

    # 追加検証: choleskyInverse がnumpyのinvと一致するか(複数サイズ)
    for seed in [1, 2, 3]:
        rng = np.random.default_rng(seed)
        n = 4
        raw = rng.uniform(-1, 1, size=(n, n))
        spd = raw @ raw.T + n * np.eye(n)  # 正定値になるよう構成
        l_spd = cholesky(spd)
        inv = cholesky_inverse(l_spd)
        np_inv = np.linalg.inv(spd)
        ok = np.allclose(inv, np_inv, atol=1e-8)
        print(f"--- choleskyInverse random SPD 4x4 (seed={seed}) ---")
        print(f"max diff vs numpy.linalg.inv = {np.max(np.abs(inv - np_inv)):.3e}")
        print("OK" if ok else "MISMATCH")
        print()
        results.append(ok)

    print("=" * 40)
    if all(results):
        print("ALL CHECKS PASSED")
    else:
        print("SOME CHECKS FAILED")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
