# Basalt Formal Mathematical Specification

This document presents the mathematical definitions, algorithmic proofs, and accounting invariants governing the Basalt clearinghouse kernel.

---

## 1. Bi-Temporal Interval Algebra

Let $\mathbb{T}$ denote a discrete, linearly ordered time domain representing timestamps with microsecond resolution.

### Temporal Domains

* **Valid Time Interval**: $I_v = [v_s, v_e) \subset \mathbb{T}$, where $v_s$ is the effective start date and $v_e$ is the expiration date ($v_s < v_e$).
* **System Assertion Interval**: $I_s = [s_s, s_e) \subset \mathbb{T}$, where $s_s$ is the physical write timestamp and $s_e$ is the physical supersession timestamp.

A bi-temporal tuple $r$ is defined as:

$$r = (k, v, [v_s, v_e), [s_s, s_e))$$

where $k$ is the primary key and $v$ is the payload tuple.

### Temporal Snapshot Operators

1. **Point-in-Time Valid Snapshot (AS-OF $t_v$)**:
   $$\sigma_{v}^{t_v}(R) = \{ (k, v) \mid \exists (k, v, I_v, I_s) \in R \text{ s.t. } t_v \in I_v \land s_e = \infty \}$$

2. **Audit Rollback Snapshot (AS-AT $t_s$)**:
   $$\sigma_{s}^{t_s}(R) = \{ (k, v, I_v) \mid \exists (k, v, I_v, I_s) \in R \text{ s.t. } t_s \in I_s \}$$

---

## 2. Invariant Conservation Theorems

### Definition 1: Double-Entry Voucher
A voucher $V$ is a set of debits $D$ and credits $C$:

$$V = (D, C), \quad D = \{(a_i, m_i)\}_{i=1}^p, \quad C = \{(a_j, m_j)\}_{j=1}^q$$

where $a \in \mathcal{A}$ is an account identifier and $m \in \mathbb{Q}^+$ is a positive rational quantity.

### Theorem 1: Transaction Balance
A voucher $V$ is admissible if and only if:

$$\sum_{i=1}^p m_i - \sum_{j=1}^q m_j = 0$$

### Theorem 2: System-Wide Conservation
Let $\mathbf{b}_t \in \mathbb{Q}^{|\mathcal{A}|}$ denote the vector of settled account balances at time $t$. If all applied vouchers $\{V_1, V_2, \dots, V_k\}$ are admissible, then for any transfer matrix $T$:

$$\mathbf{1}^T \mathbf{b}_t = \mathbf{1}^T \mathbf{b}_0 \quad \forall t \ge 0$$

*Proof*: Each voucher application adds a vector $\mathbf{v}$ satisfying $\mathbf{1}^T \mathbf{v} = 0$. By induction on the sequence of transactions:

$$\mathbf{1}^T \mathbf{b}_k = \mathbf{1}^T \left(\mathbf{b}_0 + \sum_{i=1}^k \mathbf{v}_i\right) = \mathbf{1}^T \mathbf{b}_0 + \sum_{i=1}^k \mathbf{1}^T \mathbf{v}_i = \mathbf{1}^T \mathbf{b}_0$$

---

## 3. Multilateral Netting Complexity and Convergence

Let $G = (V, E, c)$ be a directed debt network with $n = |V|$ nodes and $m = |E|$ edges.

### Johnson Cycle Traversal Complexity
Finding all elementary directed cycles in $G$ has time complexity:

$$\mathcal{O}((n + m)(C + 1))$$

where $C$ is the number of elementary cycles. Since debt compression strictly eliminates at least one directed edge per cycle cancellation pass, the maximum number of cancellation iterations is bounded by:

$$k \le m$$

The total netting time complexity across all rounds is:

$$\mathcal{O}(m \cdot (n + m))$$

### Push-Relabel Gridlock Resolution
For residual obligations with liquidity constraints, the preflow $f: V \times V \to \mathbb{R}$ satisfies:

1. **Capacity Constraint**: $f(u, v) \le c(u, v)$
2. **Antisymmetry**: $f(u, v) = -f(v, u)$
3. **Non-negative Excess**: $e(u) = \sum_{v \in V} f(v, u) \ge 0 \quad \forall u \in V \setminus \{s\}$

The height function $h: V \to \mathbb{N}$ satisfies the validity condition:

$$h(u) \le h(v) + 1 \quad \forall (u, v) \in E_f$$

The algorithm terminates with an optimal feasible flow in $\mathcal{O}(V^2 E)$ operations.

---

## 4. Analytical Approximations for Risk Margining

### Abramowitz and Stegun Normal Cumulative Distribution Function
The standard normal CDF $\Phi(x) = \frac{1}{\sqrt{2\pi}} \int_{-\infty}^x e^{-t^2/2} dt$ is evaluated via the rational polynomial approximation (formula 7.1.26):

$$\Phi(x) = 1 - Z(x) \left( b_1 t + b_2 t^2 + b_3 t^3 + b_4 t^4 + b_5 t^5 \right) + \epsilon(x)$$

where:
$$t = \frac{1}{1 + p x}, \quad Z(x) = \frac{1}{\sqrt{2\pi}} e^{-x^2 / 2}$$

Coefficients:
* $p = 0.2316419$
* $b_1 = 0.319381530$
* $b_2 = -0.356563782$
* $b_3 = 1.781477937$
* $b_4 = -1.821255978$
* $b_5 = 1.330274429$

Error bound: $|\epsilon(x)| < 7.5 \times 10^{-8}$.

### SPAN 16-Scenario Valuation Metric

Given an instrument with underlying spot price $S$, implied volatility $\sigma$, delta $\Delta$, and vega $\nu$, the valuation shock $\Delta V_{i}$ under scenario $i = (\delta S_i, \delta \sigma_i)$ is computed as:

$$\Delta V_i = \Delta \cdot \delta S_i + \frac{1}{2} \Gamma \cdot (\delta S_i)^2 + \nu \cdot \delta \sigma_i$$

Total portfolio initial margin $IM$ is the maximum portfolio loss across all scenarios:

$$IM = \max_{1 \le i \le 16} \left( -\sum_{k \in \mathcal{P}} \Delta V_{i, k} \right)$$

---

## 5. ACTUS Financial Contract Lifecycles

The ACTUS (Algorithmic Contract Types Unified Standard) engine defines discrete cashflow schedules based on contract type parameters:

| Contract Type | Acronym | Amortization Schedule | Terminal Principal |
| :--- | :--- | :--- | :--- |
| Principal at Maturity | PAM | Bullet at Maturity | $100\%$ Principal at $T_M$ |
| Annuity | ANN | Equal Total Installments | Constant $(P + I)$ per period |
| Linear Amortizer | LAM | Equal Principal Reductions | $P_t = P_0 / N$, decreasing $I$ |
| Interest Rate Swap | IRS | Multi-Leg Netting | Floating vs Fixed Difference |
| Credit Default Swap | CDS | Premium Legs vs Default Leg | Protection Payout on Credit Event |
| Foreign Exchange Swap | FXSWAP | Near Spot Leg + Far Fwd Leg | Netting across Two Currencies |
