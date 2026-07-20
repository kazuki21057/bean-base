"""T4-0c検証スクリプト。

lib/services/math/distributions.dart と同じアルゴリズム
(Abramowitz-Stegun近似のerf、Lanczos近似のlogGamma、Lentz法の連分数展開による
正則化不完全ベータ関数、二分法のtQuantile)をPythonで再実装し、scipyの結果および
statistics_feature_design.md §9.3 のテスト期待値と突き合わせて検証する。

実行方法: python tools/verify_distributions.py
依存: numpy, scipy (pip install numpy scipy)
"""

import math

import numpy as np
from scipy import special as sp
from scipy import stats


def erf(x):
    """Abramowitz & Stegun 7.1.26 (|誤差|<1.5e-7)。x=0 は多項式近似の丸め誤差
    (係数の和が1にわずかに満たない)で~1e-9の残差が出るため厳密値0を特別扱いする。"""
    if x == 0.0:
        return 0.0
    sign = 1.0 if x >= 0 else -1.0
    x = abs(x)
    p = 0.3275911
    a1, a2, a3, a4, a5 = (
        0.254829592,
        -0.284496736,
        1.421413741,
        -1.453152027,
        1.061405429,
    )
    t = 1.0 / (1.0 + p * x)
    y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x)
    return sign * y


def normal_pdf(z):
    return math.exp(-z * z / 2) / math.sqrt(2 * math.pi)


def normal_cdf(z):
    return 0.5 * (1 + erf(z / math.sqrt(2)))


_LANCZOS_G = 7
_LANCZOS_COEF = [
    0.99999999999980993,
    676.5203681218851,
    -1259.1392167224028,
    771.32342877765313,
    -176.61502916214059,
    12.507343278686905,
    -0.13857109526572012,
    9.9843695780195716e-6,
    1.5056327351493116e-7,
]


def log_gamma(x):
    """Lanczos近似(g=7, n=9)。"""
    if x < 0.5:
        return math.log(math.pi / math.sin(math.pi * x)) - log_gamma(1 - x)
    x -= 1
    a = _LANCZOS_COEF[0]
    for i in range(1, _LANCZOS_G + 2):
        a += _LANCZOS_COEF[i] / (x + i)
    t = x + _LANCZOS_G + 0.5
    return 0.5 * math.log(2 * math.pi) + (x + 0.5) * math.log(t) - t + math.log(a)


def betacf(a, b, x, max_it=200, eps=1e-12):
    """Numerical Recipes の連分数展開(Lentz法)。"""
    fpmin = 1e-300
    qab = a + b
    qap = a + 1
    qam = a - 1
    c = 1.0
    d = 1.0 - qab * x / qap
    if abs(d) < fpmin:
        d = fpmin
    d = 1.0 / d
    h = d
    for m in range(1, max_it + 1):
        m2 = 2 * m
        aa = m * (b - m) * x / ((qam + m2) * (a + m2))
        d = 1.0 + aa * d
        if abs(d) < fpmin:
            d = fpmin
        c = 1.0 + aa / c
        if abs(c) < fpmin:
            c = fpmin
        d = 1.0 / d
        h *= d * c
        aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2))
        d = 1.0 + aa * d
        if abs(d) < fpmin:
            d = fpmin
        c = 1.0 + aa / c
        if abs(c) < fpmin:
            c = fpmin
        d = 1.0 / d
        delta = d * c
        h *= delta
        if abs(delta - 1.0) < eps:
            break
    return h


def regularized_incomplete_beta(a, b, x):
    if x <= 0 or x >= 1:
        if x == 0 or x == 1:
            return float(x)
        raise ValueError("xは[0,1]の範囲でなければなりません")
    bt = math.exp(
        log_gamma(a + b) - log_gamma(a) - log_gamma(b) + a * math.log(x) + b * math.log(1 - x)
    )
    if x < (a + 1) / (a + b + 2):
        return bt * betacf(a, b, x) / a
    else:
        return 1 - bt * betacf(b, a, 1 - x) / b


def student_t_cdf(t, df):
    x = df / (df + t * t)
    ib = regularized_incomplete_beta(df / 2, 0.5, x)
    if t >= 0:
        return 1 - 0.5 * ib
    else:
        return 0.5 * ib


def t_quantile(p, df, lo=-50.0, hi=50.0, tol=1e-9):
    while hi - lo > tol:
        mid = (lo + hi) / 2
        if student_t_cdf(mid, df) < p:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


def main():
    results = []

    print("--- normalCdf ---")
    v1 = normal_cdf(0)
    v2 = normal_cdf(1.959964)
    print(f"normalCdf(0) = {v1} (expected 0.5, atol 1e-12)")
    print(f"normalCdf(1.959964) = {v2} (expected 0.975, atol 1e-6)")
    print(f"scipy norm.cdf(0) = {stats.norm.cdf(0)}, scipy norm.cdf(1.959964) = {stats.norm.cdf(1.959964)}")
    ok = abs(v1 - 0.5) < 1e-12 and abs(v2 - 0.975) < 1e-6
    print("OK" if ok else "MISMATCH")
    print()
    results.append(ok)

    print("--- erf vs scipy.special.erf (sanity) ---")
    xs = [-2.5, -1.0, -0.1, 0.0, 0.1, 1.0, 2.5]
    max_diff = max(abs(erf(x) - sp.erf(x)) for x in xs)
    print(f"max diff over {xs} = {max_diff:.3e} (< 1.5e-7 ?)")
    ok = max_diff < 1.5e-7
    print("OK" if ok else "MISMATCH")
    print()
    results.append(ok)

    print("--- studentTCdf ---")
    cases = [
        (2.0, 10, 0.963306, 1e-5),
        (-2.0, 10, 0.036694, 1e-5),
        (1.812461, 10, 0.95, 1e-5),
    ]
    ok = True
    for t, df, expected, atol in cases:
        v = student_t_cdf(t, df)
        sp_v = stats.t.cdf(t, df)
        print(f"studentTCdf({t}, {df}) = {v}, expected = {expected}, scipy = {sp_v}")
        case_ok = abs(v - expected) < atol and abs(v - sp_v) < 1e-8
        ok = ok and case_ok
    print("OK" if ok else "MISMATCH")
    print()
    results.append(ok)

    print("--- tQuantile ---")
    cases = [
        (0.975, 10, 2.228139, 1e-4),
    ]
    ok = True
    for p, df, expected, atol in cases:
        v = t_quantile(p, df)
        sp_v = stats.t.ppf(p, df)
        print(f"tQuantile({p}, {df}) = {v}, expected = {expected}, scipy ppf = {sp_v}")
        case_ok = abs(v - expected) < atol and abs(v - sp_v) < 1e-6
        ok = ok and case_ok
    print("OK" if ok else "MISMATCH")
    print()
    results.append(ok)

    print("--- tQuantile(0.975, 138): 設計書§9.3記載値1.977431との不一致を検証 ---")
    v138 = t_quantile(0.975, 138)
    sp_138 = stats.t.ppf(0.975, 138)
    sp_137 = stats.t.ppf(0.975, 137)
    print(f"tQuantile(0.975, 138) = {v138}, scipy ppf(df=138) = {sp_138}")
    print(f"設計書記載値 1.977431 <-> scipy ppf(df=137) = {sp_137}")
    print(
        "-> 設計書§9.3のtQuantile(0.975,138)=1.977431は、df=137の値(1.977431)を"
        "df=138用として誤記載したものと判断。テストはdf=138の正しい値"
        f"({sp_138:.6f})を使う。"
    )
    ok137 = abs(1.977431 - sp_137) < 1e-5
    ok138 = abs(v138 - sp_138) < 1e-8
    print("OK (df=137一致・自実装値もscipyと一致)" if ok137 and ok138 else "MISMATCH")
    print()
    results.append(ok137 and ok138)

    print("=" * 40)
    if all(results):
        print("ALL CHECKS PASSED")
    else:
        print("SOME CHECKS FAILED")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
