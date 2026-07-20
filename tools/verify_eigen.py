"""T4-0a検証スクリプト。

lib/services/math/eigen.dart の eigenSymmetric (古典的巡回Jacobi法) と同じ
アルゴリズムをPythonで再実装し、numpy.linalg.eigh (LAPACK) の結果と突き合わせて、
statistics_feature_design.md §9.1 のテスト期待値が正しいことを検証する。

実行方法: python tools/verify_eigen.py
依存: numpy (pip install numpy)
"""

import numpy as np


def jacobi_eigen(a, max_sweeps=50, tol=1e-12):
    """eigen.dart の eigenSymmetric と同一のアルゴリズム(検証用Python移植)。"""
    a = np.array(a, dtype=float)
    n = a.shape[0]
    if not np.allclose(a, a.T, atol=0, rtol=0):
        raise ValueError("対称行列ではありません")

    m = a.copy()
    v = np.eye(n)

    def off_norm():
        s = 0.0
        for p in range(n):
            for q in range(p + 1, n):
                s += m[p, q] ** 2
        return np.sqrt(s)

    converged = n <= 1
    for _ in range(max_sweeps):
        if converged:
            break
        for p in range(n - 1):
            for q in range(p + 1, n):
                apq = m[p, q]
                if apq == 0.0:
                    continue
                theta = (m[q, q] - m[p, p]) / (2 * apq)
                sign = 1.0 if theta >= 0 else -1.0
                t = sign / (abs(theta) + np.sqrt(theta * theta + 1))
                c = 1.0 / np.sqrt(t * t + 1)
                s = t * c

                app, aqq = m[p, p], m[q, q]
                m[p, p] = c * c * app - 2 * s * c * apq + s * s * aqq
                m[q, q] = s * s * app + 2 * s * c * apq + c * c * aqq
                m[p, q] = 0.0
                m[q, p] = 0.0

                for i in range(n):
                    if i == p or i == q:
                        continue
                    aip, aiq = m[i, p], m[i, q]
                    m[i, p] = c * aip - s * aiq
                    m[p, i] = m[i, p]
                    m[i, q] = s * aip + c * aiq
                    m[q, i] = m[i, q]

                for i in range(n):
                    vip, viq = v[i, p], v[i, q]
                    v[i, p] = c * vip - s * viq
                    v[i, q] = s * vip + c * viq

        normA = np.linalg.norm(m, "fro")
        threshold = tol * (normA if normA != 0 else 1.0)
        if off_norm() < threshold:
            converged = True

    if not converged:
        raise RuntimeError("Jacobi法が収束しませんでした")

    eigenvalues = np.diag(m).copy()
    order = np.argsort(-eigenvalues)
    return eigenvalues[order], v[:, order]


def check(label, a, expected_vals, atol_vals):
    vals, vecs = jacobi_eigen(a)
    np_vals, np_vecs = np.linalg.eigh(np.array(a, dtype=float))
    np_order = np.argsort(-np_vals)
    np_vals = np_vals[np_order]

    print(f"--- {label} ---")
    print(f"jacobi eigenvalues : {vals}")
    print(f"numpy  eigenvalues : {np_vals}")
    print(f"expected (design)  : {expected_vals}")
    ok = np.allclose(vals, expected_vals, atol=atol_vals) and np.allclose(
        vals, np_vals, atol=1e-8
    )
    print("OK" if ok else "MISMATCH")
    print()
    return ok


def check_properties(label, a, seed):
    rng = np.random.default_rng(seed)
    vals, vecs = jacobi_eigen(a)
    n = len(vals)

    max_residual = 0.0
    for i in range(n):
        residual = np.max(np.abs(np.array(a) @ vecs[:, i] - vals[i] * vecs[:, i]))
        max_residual = max(max_residual, residual)

    max_offdiag_dot = 0.0
    for i in range(n):
        for j in range(n):
            if i == j:
                continue
            max_offdiag_dot = max(max_offdiag_dot, abs(np.dot(vecs[:, i], vecs[:, j])))

    trace_diff = abs(np.sum(vals) - np.trace(a))

    print(f"--- {label} ---")
    print(f"max ||A*v_i - lambda_i*v_i||_inf = {max_residual:.3e} (< 1e-8 ?)")
    print(f"max |v_i . v_j| (i!=j)           = {max_offdiag_dot:.3e} (< 1e-8 ?)")
    print(f"|sum(lambda) - trace(A)|         = {trace_diff:.3e} (< 1e-8 ?)")
    ok = max_residual < 1e-8 and max_offdiag_dot < 1e-8 and trace_diff < 1e-8
    print("OK" if ok else "MISMATCH")
    print()
    return ok


def main():
    results = []

    # §9.1-1: [[2,1],[1,2]] -> eigenvalues [3,1]
    results.append(check("case1: [[2,1],[1,2]]", [[2, 1], [1, 2]], [3, 1], 1e-10))
    vals, vecs = jacobi_eigen([[2, 1], [1, 2]])
    expected_vec = np.array([1 / np.sqrt(2), 1 / np.sqrt(2)])
    vec_ok = np.allclose(np.abs(vecs[:, 0]), np.abs(expected_vec), atol=1e-8)
    print(f"case1 eigenvector(lambda=3) = {vecs[:, 0]}, expected(abs) = {expected_vec}")
    print("OK" if vec_ok else "MISMATCH")
    print()
    results.append(vec_ok)

    # §9.1-2: diag(4,2,1) -> eigenvalues [4,2,1], eigenvectors = identity columns
    results.append(
        check(
            "case2: diag(4,2,1)",
            [[4, 0, 0], [0, 2, 0], [0, 0, 1]],
            [4, 2, 1],
            1e-10,
        )
    )
    _, vecs2 = jacobi_eigen([[4, 0, 0], [0, 2, 0], [0, 0, 1]])
    identity_ok = np.allclose(np.abs(vecs2), np.eye(3), atol=1e-8)
    print(f"case2 eigenvectors =\n{vecs2}\nexpected = identity")
    print("OK" if identity_ok else "MISMATCH")
    print()
    results.append(identity_ok)

    # §9.1-3: property checks on random symmetric matrices (generic, several seeds)
    for seed in [1, 7, 42, 123]:
        rng = np.random.default_rng(seed)
        raw = rng.uniform(-1, 1, size=(6, 6))
        sym = (raw + raw.T) / 2
        results.append(check_properties(f"case3: random 6x6 symmetric (seed={seed})", sym, seed))

    print("=" * 40)
    if all(results):
        print("ALL CHECKS PASSED")
    else:
        print("SOME CHECKS FAILED")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
