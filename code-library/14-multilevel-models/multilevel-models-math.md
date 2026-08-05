# Module 14: Multilevel Models -- Math Reference

---

## Notation and index conventions

- i: individual (level-1 unit), i = 1, ..., n_j
- j: group (level-2 unit), j = 1, ..., J
- Y_ij: outcome for individual i in group j
- X_ij: individual-level predictor for individual i in group j
- W_j: group-level predictor for group j
- γ (gamma): fixed effects (population-average coefficients, analogous to β in OLS)
- u (lowercase): random effects (group-specific deviations)
- ε (epsilon): individual-level residual
- τ² (tau-squared): variance of random effects (between-group variance)
- σ² (sigma-squared): variance of level-1 residuals (within-group variance)
- T: covariance matrix of a vector of random effects

---

## Part A: The random intercept model

### Level-1 equation

For individual i in group j:

Y_ij = β₀ⱼ + β₁X_ij + ε_ij

The intercept β₀ⱼ carries a j subscript, meaning each group gets its own baseline. The slope β₁ is the same for all groups (it is fixed). The residual ε_ij ~ N(0, σ²) is the unexplained individual-level deviation.

### Level-2 equation

The group intercept itself is modeled as a function of a grand mean plus a group-specific deviation:

β₀ⱼ = γ₀₀ + u₀ⱼ

where:
- γ₀₀ is the grand intercept (average baseline across all groups)
- u₀ⱼ is the random effect for group j, assumed u₀ⱼ ~ N(0, τ²₀₀)

The distribution N(0, τ²₀₀) expresses the assumption that group baselines are draws from a normal distribution. τ²₀₀ is the parameter that tells you how spread out those group baselines are. If τ²₀₀ = 0, all groups have the same intercept and multilevel modeling adds nothing over OLS.

### Combined (reduced-form) equation

Substitute the level-2 equation into the level-1 equation:

Y_ij = (γ₀₀ + u₀ⱼ) + β₁X_ij + ε_ij

Y_ij = γ₀₀ + β₁X_ij + u₀ⱼ + ε_ij

This is called the combined or reduced-form equation. It looks like an OLS regression with an additional error term u₀ⱼ that is shared by all individuals in the same group. The total error for individual i in group j is (u₀ⱼ + ε_ij).

### Implied variance of Y_ij

Because u₀ⱼ and ε_ij are independent (by assumption):

Var(Y_ij) = Var(u₀ⱼ + ε_ij) = Var(u₀ⱼ) + Var(ε_ij) = τ²₀₀ + σ²

Total variance partitions cleanly into between-group variance (τ²₀₀) and within-group variance (σ²). This partition is the foundation of the ICC.

---

## Part B: The intraclass correlation coefficient (ICC)

### Derivation

Take two individuals i and i' from the same group j (i ≠ i'). Their combined errors are:

e_ij  = u₀ⱼ + ε_ij
e_i'j = u₀ⱼ + ε_i'j

Compute their covariance. Since ε_ij and ε_i'j are independent of each other and of u₀ⱼ:

Cov(e_ij, e_i'j) = Cov(u₀ⱼ + ε_ij, u₀ⱼ + ε_i'j)
                 = Var(u₀ⱼ) + Cov(u₀ⱼ, ε_i'j) + Cov(ε_ij, u₀ⱼ) + Cov(ε_ij, ε_i'j)
                 = τ²₀₀ + 0 + 0 + 0
                 = τ²₀₀

The correlation between two observations from the same group is:

Corr(Y_ij, Y_i'j) = Cov(Y_ij, Y_i'j) / Var(Y_ij)
                   = τ²₀₀ / (τ²₀₀ + σ²)

This ratio is the **intraclass correlation coefficient**:

ICC = τ²₀₀ / (τ²₀₀ + σ²)

### Interpretation

ICC ∈ [0, 1].

- ICC = 0: all the variance is within groups; knowing the group membership tells you nothing about the outcome.
- ICC = 0.20: 20% of total outcome variance is attributable to group membership. Two randomly chosen people from the same group have a correlation of 0.20 in their outcomes, before conditioning on any predictors.
- High ICC means clustering is severe and ignoring it in OLS would badly underestimate standard errors.

### Effective sample size

The "design effect" due to clustering is approximately:

DEFF ≈ 1 + (n̄ - 1) · ICC

where n̄ is the average group size. The effective sample size is N / DEFF. If ICC = 0.15 and average group size is 50, DEFF ≈ 1 + 49 × 0.15 = 8.35. Your 5,000-person sample has the inferential power of roughly 599 independent observations. Ignoring this inflates your t-statistics by a factor of √8.35 ≈ 2.9.

---

## Part C: The random slope model

### Level-1 equation

Y_ij = β₀ⱼ + β₁ⱼ X_ij + ε_ij

Both the intercept β₀ⱼ and the slope β₁ⱼ now carry a j subscript. The effect of X on Y is allowed to vary across groups.

### Level-2 equations

β₀ⱼ = γ₀₀ + u₀ⱼ
β₁ⱼ = γ₁₀ + u₁ⱼ

where:
- γ₀₀ is the grand intercept (average baseline)
- γ₁₀ is the average slope of X across groups
- u₀ⱼ is the group deviation in the intercept
- u₁ⱼ is the group deviation in the slope

The two random effects are jointly distributed as multivariate normal:

(u₀ⱼ, u₁ⱼ) ~ MVN(0, T)

where T is the 2×2 covariance matrix:

T = | τ²₀₀   τ₀₁ |
    | τ₀₁    τ²₁₁ |

- τ²₀₀: variance of group intercepts (same as before)
- τ²₁₁: variance of group slopes. How much does the slope of X vary across groups? Large τ²₁₁ means the relationship between X and Y is genuinely different across contexts.
- τ₀₁: covariance between intercepts and slopes. Positive τ₀₁ means groups that start high on the outcome also tend to show stronger effects of X. Negative τ₀₁ means high-baseline groups show weaker (or reversed) slopes.

### Combined equation

Substitute both level-2 equations into the level-1 equation:

Y_ij = (γ₀₀ + u₀ⱼ) + (γ₁₀ + u₁ⱼ) X_ij + ε_ij

Y_ij = γ₀₀ + γ₁₀ X_ij + u₀ⱼ + u₁ⱼ X_ij + ε_ij

The term u₁ⱼ X_ij is a group-by-variable interaction embedded in the error structure. This is what makes the model "mixed" -- it has both fixed effects (γ₀₀, γ₁₀) and random effects (u₀ⱼ, u₁ⱼ) that interact with predictors.

### Implied variance of Y_ij (random slope model)

Var(Y_ij) = τ²₀₀ + 2τ₀₁ X_ij + τ²₁₁ X²_ij + σ²

This variance is no longer constant across individuals: it depends on X_ij. Groups with extreme values of X contribute more to the heteroscedasticity if τ²₁₁ > 0. This is a key diagnostic: heteroscedasticity in the residuals can indicate omitted random slopes.

---

## Part D: Cross-level interaction

### Setup

A cross-level interaction uses a group-level variable W_j to explain variation in the slope of X across groups. Extend the level-2 equation for β₁ⱼ:

β₁ⱼ = γ₁₀ + γ₁₁ W_j + u₁ⱼ

The coefficient γ₁₁ answers: "For a one-unit increase in the group-level variable W_j, how much does the slope of X on Y change?"

### Combined equation with cross-level interaction

Substitute into the level-1 equation:

Y_ij = γ₀₀ + (γ₁₀ + γ₁₁ W_j + u₁ⱼ) X_ij + u₀ⱼ + ε_ij

Y_ij = γ₀₀ + γ₁₀ X_ij + γ₁₁ W_j X_ij + u₀ⱼ + u₁ⱼ X_ij + ε_ij

The term γ₁₁ W_j X_ij is the cross-level interaction in the fixed-effects part of the model. It is a product of a level-2 variable and a level-1 variable. You would not include W_j alone in this equation unless you also want to estimate the main effect of the group context on the outcome intercept (which usually makes sense to do).

### Interpretation

γ₁₁ tells you how much the slope of X changes for each unit increase in W. If W is a state-level variable (e.g., Republican vote share) and X is respondent education, then γ₁₁ captures whether education's effect on the outcome is stronger or weaker in more Republican states.

Adding the cross-level interaction often substantially reduces τ²₁₁ (the residual variance of slopes), because W_j is now explaining part of that between-group variation in slopes. The ratio (τ²₁₁_reduced / τ²₁₁_null) is sometimes called the pseudo-R² for the slope variance.

---

## Part E: REML vs. full ML estimation

### Why OLS doesn't work here

The combined equation Y_ij = γ₀₀ + γ₁₀ X_ij + u₀ⱼ + u₁ⱼ X_ij + ε_ij has a composite error structure in which observations from the same group are correlated. OLS assumes all errors are independent, so its estimates of γ are consistent but its variance estimates are wrong (the model doesn't account for the structure in the errors).

Multilevel models are estimated by maximizing a likelihood function that correctly specifies this error covariance structure.

### Full maximum likelihood (ML)

Full ML jointly maximizes the likelihood over both the fixed effects γ and the variance components (τ², σ²). The likelihood is:

L(γ, T, σ² | Y) = ∏_j f(Y_j | γ, T, σ²)

where f(Y_j | ...) is the marginal likelihood for group j, obtained by integrating out the random effects:

f(Y_j | γ, T, σ²) = ∫ f(Y_j | u_j, γ, σ²) · f(u_j | T) du_j

This integral is tractable under the normality assumptions because the product of two normals is normal. The result is a multivariate normal marginal distribution for Y_j.

Full ML yields slightly biased variance component estimates (τ², σ²) because it doesn't account for the degrees of freedom used estimating the fixed effects -- analogous to dividing by n instead of n-k when estimating σ² in OLS.

### Restricted maximum likelihood (REML)

REML maximizes a modified likelihood that is computed from linear combinations of Y that are orthogonal to the fixed-effects design matrix X. Intuitively: REML first projects out the fixed effects, then estimates the variance components from the residuals. This is analogous to the OLS correction of dividing by n-k rather than n.

REML variance component estimates are less biased than ML estimates, especially with small samples and few groups. **Use REML as the default** for estimating and reporting variance components and random effects.

**Critical caveat:** REML likelihoods for two models are not comparable unless the models have identical fixed-effects specifications. To compare models with different fixed effects via a likelihood ratio test (LRT), you must refit both models with full ML first.

Rule of thumb:
- Use REML for estimating, interpreting, and reporting.
- Use ML for LRT comparisons involving different fixed-effect structures.

---

## Part F: Shrinkage and partial pooling

### The empirical Bayes estimator

The observed group mean Ȳ_j is an unbiased but noisy estimate of the true group effect (γ₀₀ + u₀ⱼ). For small groups, this noise can be substantial. The multilevel model produces a **shrunken** estimate of the random effect u₀ⱼ that blends the group's own data with information from the overall distribution of group effects.

The empirical Bayes (EB) estimate of u₀ⱼ is:

ũ₀ⱼ = λ_j · (Ȳ_j - γ̂₀₀)

where the shrinkage weight λ_j is:

λ_j = (n_j · τ²₀₀) / (n_j · τ²₀₀ + σ²)

### Understanding the weight

Rewrite the denominator:

λ_j = n_j · τ²₀₀ / (n_j · τ²₀₀ + σ²)

As n_j → ∞: λ_j → 1. Large groups get no shrinkage; the model trusts their observed mean.

As n_j → 0: λ_j → 0. Tiny groups are pulled entirely to the grand mean γ̂₀₀.

For moderate n_j, the weight depends on the ratio ICC / (1 - ICC) scaled by group size. When ICC is high (τ²₀₀ is large relative to σ²), even moderately sized groups get substantial weight. When ICC is low (between-group variance is small), almost all information comes from the group mean.

### Connection to Bayes

The EB estimate is formally the posterior mean of u₀ⱼ under a normal prior N(0, τ²₀₀) and normal likelihood for Ȳ_j. The multilevel model is doing Bayesian inference on the random effects, using the empirical distribution of effects (estimated from the data) as the prior. This is why multilevel models are sometimes described as "empirical Bayes."

The practical consequence: in a CES analysis, a small state like Wyoming (few respondents) will have its estimated random effect pulled substantially toward zero. A large state like California will be barely moved. This is not bias -- it is statistically optimal weighting of information.

---

## Part G: Matrix representation (for reference)

For group j with n_j individuals, define:

Y_j = n_j × 1 vector of outcomes
X_j = n_j × p matrix of fixed-effect predictors
Z_j = n_j × q matrix of random-effect predictors (e.g., just a column of 1s for random intercept)
u_j = q × 1 vector of random effects for group j

The model for group j:

Y_j = X_j γ + Z_j u_j + ε_j

Marginal distribution (integrating out u_j):

Y_j ~ MVN(X_j γ, V_j)

where V_j = Z_j T Z_j' + σ² I_nj

V_j is the n_j × n_j marginal covariance matrix of the outcomes for group j. For the random intercept model with Z_j = 1_nj (column of ones):

V_j = τ²₀₀ · (1_nj)(1_nj)' + σ² I_nj

This is a compound-symmetric matrix: variance τ²₀₀ + σ² on the diagonal, covariance τ²₀₀ off-diagonal -- exactly the structure that gives rise to the ICC.

The full log-likelihood across all J groups:

log L = -½ Σ_j [ n_j log(2π) + log|V_j| + (Y_j - X_j γ)' V_j⁻¹ (Y_j - X_j γ) ]

Maximizing this over γ, T, and σ² yields the ML estimates. REML modifies this to remove the contribution of γ from the curvature of the likelihood before optimizing variance components.
