# Dense Random Survival Forests (DRF)

### Interpretable Subgroup Discovery for Heterogeneous Treatment Benefit in Survival Outcomes

**Dense Random Survival Forests (DRF)** is a treatment-supervised patient similarity-learning framework for discovering **clinically interpretable subgroups** with potentially different treatment benefits in right-censored time-to-event data.

Instead of estimating a treatment effect for every patient and then grouping those estimates, DRF learns **which patients are similar in their survival and treatment-response patterns**. It then discovers candidate patient groups, converts them into straightforward clinical rules, and uses **empirical calibration** to decide whether the subgroup findings provide sufficient evidence of treatment-effect heterogeneity.

## Method at a Glance

![Dense Random Survival Forests: method overview, multi-parameter forest aggregation, proximity, subgroup discovery, and empirical calibration](images/drf-method-overview.png)

*Figure. DRF trains treatment-supervised survival forests under multiple parameter settings, aggregates their terminal-node memberships, computes a treatment-informed patient proximity matrix, discovers and profiles candidate subgroups, and calibrates the evidence for treatment-effect heterogeneity.*

**The central idea:** **learn patient similarity → discover candidate subgroups → obtain interpretable rules → calibrate before reporting heterogeneity.**

## Why DRF?

Survival prognosis and treatment benefit are not the same: patients with a similar overall survival risk may respond very differently to an intervention. Standard random survival forests typically focus on separating survival outcomes, without explicitly encouraging splits that distinguish **treatment responses**.

DRF was designed to address three related challenges:

1. **Heterogeneity-aware representation.** Construct a patient similarity measure informed by both survival prognosis and treatment interactions.
2. **Stable, interpretable discovery.** Combine information from multiple forest configurations, cluster the resulting representation, and summarize it using concise covariate-based decision rules.
3. **Reliable interpretation.** Distinguish data-adaptively discovered patterns from statistically supported treatment-effect heterogeneity using empirical calibration.

## How DRF Works

### 1. Train treatment-supervised survival forests under multiple parameter settings

Each survival tree uses a proposed splitting score that combines **prognostic discrimination** and **treatment-by-split interaction**:

$$
G(s)=\omega_1 (\frac{C(s)}{0.5}-1)
+(1-\omega_1)\min\!\{\frac{|Z_{\mathrm{int}}(s)|}{\omega_2},1\}.
$$

Here, $C(s)$ is the concordance index from the split-specific Cox model, $Z_{\mathrm{int}}(s)$ is the Wald statistic for the treatment-by-split interaction, $\omega_1$ balances the two components, and $\omega_2$ scales and truncates the interaction component. The reported analyses use $\omega_1=0.5$ and $\omega_2=3.5$.

**Dense** refers to training and combining **multiple forests across a prespecified grid of parameter configurations**, rather than selecting a single forest specification.

### 2. Aggregate the forests **before** computing proximity

For each trained tree, DRF records the terminal node to which each patient belongs. The terminal-node membership matrices from all configurations are **concatenated across trees**.

This aggregation builds one ensemble representation from many different patient partitions. **The final proximity matrix is then constructed from the aggregated tree memberships**—not by clustering first or treating proximity as an input to forest aggregation.

### 3. Construct treatment-informed patient similarity

Patients are more similar when they repeatedly occupy the same terminal node across the aggregated ensemble. For $B$ total trees, the conventional all-sample proximity is

$$
S(i,j)=\frac{1}{B}\sum_{b=1}^{B}\mathbf{1}\{L_{ib}=L_{jb}\},
$$

where $L_{ib}$ is the terminal-node label for patient $i$ in tree $b$.

Because the forests were grown using a treatment-aware splitting criterion, the resulting proximity reflects **both clinical prognosis and treatment-response patterns**. The manuscript also considers joint out-of-bag (OOB) proximity to reduce direct reuse of patients in tree construction and pairwise similarity estimation.

### 4. Discover candidate subgroups using spectral clustering

Spectral clustering uses the resulting proximity matrix to find patients with similar treatment-related survival patterns. Candidate numbers of clusters are examined rather than assuming one subgroup structure in advance.

### 5. Translate clusters into interpretable patient profiles

A constrained classification tree predicts the cluster assignments from baseline covariates. Its terminal leaves provide explicit rules—such as age and prior treatment thresholds—that clinicians and researchers can inspect and communicate.

Importantly, these are **candidate profiles**. A visually persuasive tree does not establish treatment-effect heterogeneity.

### 6. Assess heterogeneity and apply empirical calibration

For each eligible clustering solution, DRF compares two Cox models:

- **Without treatment interaction:** treatment + subgroup prognostic effects.
- **With treatment interaction:** treatment + subgroup prognostic effects + treatment-by-subgroup interactions.

The likelihood-ratio test gives a nominal $p_{\mathrm{leaf}}(K)$ for the candidate number of clusters $K$. DRF selects the eligible solution with the smallest nominal value, **subject to a calibrated critical threshold**.

Why calibration? Both the patient profiles and the selected number of clusters depend on the observed data. Searching over many possible partitions can generate apparently small nominal p-values even when there is **no treatment-effect heterogeneity**.

**Empirical calibration addresses the adaptive search:** a reference distribution of the selection statistic is obtained under appropriate no-heterogeneity settings, and a critical value $p^*$ is chosen to control false-positive subgroup declarations in the settings considered. The real-data analysis also uses treatment-assignment permutations as described in the manuscript.

The reporting rule is:

$$
\min_{K\in\mathcal{K}_{+}} p_{\mathrm{leaf}}(K) < p^{*}
\quad\Longrightarrow\quad
\text{report the selected subgroup profile};
$$

**otherwise, retain the overall population as one group.** Calibration is an assessment of evidence—not proof that a subgroup is clinically actionable.

---

## Case Study: ACTG 175 HIV Phase III Trial

We illustrate the methodology using the publicly available **ACTG 175** randomized HIV clinical trial (available through the R package `BART`). Following the analysis in the manuscript, we considered **1,083 patients** in two treatment arms:

- **Treatment:** zidovudine plus didanosine.
- **Control:** didanosine alone.

The analysis used ten baseline characteristics, including age, baseline CD4 T-cell count (`cd40`), and days of prior antiretroviral therapy (`preanti`).

### Exploratory patient profiles (without calibration-based exclusion)

When the exclusion step was deliberately omitted, DRF produced an interpretable three-group profile:

```text
ACTG 175 (N = 1,083)
│
├── Prior antiretroviral therapy ≥ 691 days
│     └── Subgroup 1 (n = 291)
│
└── Prior antiretroviral therapy < 691 days
      ├── Age < 34 years  → Subgroup 2 (n = 389)
      └── Age ≥ 34 years  → Subgroup 3 (n = 403)
```

This is an example of the **interpretability** of DRF—not a validated finding that the three groups have different treatment effects.

### What did empirical calibration show?

In the reported analysis, the treatment variable alone was permuted **10,000 times**, while other variables were held fixed. The observed nominal heterogeneity statistic and calibrated critical values were:

| Measure | Value |
|:--|--:|
| Observed nominal $p_{\mathrm{leaf}}$ | **0.017** |
| Calibrated threshold at 5% Type I error | **0.0005** |
| Calibrated threshold at 10% Type I error | **0.0013** |

Since $0.017>0.0013>0.0005$, the observed statistic **did not satisfy either calibrated threshold**.

**Final result:** The DRF analysis found **no statistically significant evidence of treatment-effect heterogeneity** at the 5% or 10% levels. The final output therefore retained the **overall population**, and subgroup-specific hazard ratios and confidence intervals were not reported for the exploratory profile.

> **Takeaway:** Flexible subgroup learning can yield interpretable profiles even when the evidence for different treatment effects is insufficient. DRF combines **discovery** with **calibration** so that exploratory partitions are not automatically reported as treatment-benefit subgroups.

## What Makes DRF Distinctive?

| Stage | Methodological contribution |
|:--|:--|
| Forest construction | Treatment-supervised splitting balances survival discrimination and treatment heterogeneity. |
| **Dense** ensemble | Multiple forest configurations contribute complementary tree memberships. |
| Representation | **Aggregation precedes proximity construction**; similarity is computed from the combined ensemble. |
| Subgroup discovery | Spectral clustering uses the learned treatment-informed similarity matrix. |
| Interpretation | A constrained decision tree provides concise, baseline-covariate subgroup rules. |
| Statistical assessment | Empirical calibration addresses adaptive subgroup discovery before reporting heterogeneity. |

DRF is **complementary** to generalized random forests and causal survival forests: whereas those methods principally target conditional treatment-effect estimation, DRF emphasizes **a small number of interpretable patient profiles** and statistical assessment of their treatment-effect differences.

## Scope and Interpretation

DRF is intended for randomized-trial subgroup research with right-censored survival outcomes. Its application relies on the assumptions described in the manuscript, including conditional noninformative censoring and Cox-based interaction assessment. The empirical Type I error findings are established for the studied settings and should not be interpreted as universal finite-sample guarantees. Any candidate patient profile requires independent clinical evaluation and appropriate validation before treatment decisions.

## Reference

Li, X., Liu, Q., Jiang, X., Xia, H. A., Wei, P., and Hobbs, B. P. **Dense random survival forests identify interpretable patient profiles with heterogeneous treatment benefit.** Manuscript under revision at the *Journal of the Royal Statistical Society: Series C (Applied Statistics)*.
