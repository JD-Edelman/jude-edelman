# ==============================================================================
#  MODULE 11: SCALE CONSTRUCTION & RELIABILITY
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Purpose: Build and validate multi-item scales from CES attitude batteries.
#  Covers: Cronbach's alpha, EFA, CFA with lavaan, and PCA.
#
#  install.packages(c("psych", "lavaan", "semPlot", "GPArotation"))
# ==============================================================================

library(tidyverse)
library(psych)       # alpha(), fa(), pca(), describe()
library(lavaan)      # CFA / SEM
library(semPlot)     # path diagrams for SEM (install.packages("semPlot"))
library(GPArotation) # rotation methods for EFA

ces <- readRDS("CES2020_clean.rds")


# ==============================================================================
# SECTION 1: RECODE ITEMS TO CONSISTENT DIRECTION
# ==============================================================================

# CES policy items: 1=Support, 2=Oppose.
# Recode to 0/1 so that 1 = the focal construct (restrictionism, gun control, etc.)
# Higher sum = more of the construct.

ces <- ces |>
  mutate(
    # Immigration restrictionism items (1 = restrictionist position)
    imm_item1 = if_else(pol_daca          == 2, 1L, 0L),  # oppose DACA
    imm_item2 = if_else(pol_border_patrol == 1, 1L, 0L),  # more border patrol
    imm_item3 = if_else(pol_wall          == 1, 1L, 0L),  # support wall
    imm_item4 = if_else(pol_legal_status  == 2, 1L, 0L),  # oppose legal path
    imm_item5 = if_else(pol_deportation   == 1, 1L, 0L),  # support deportation

    # Gun control items (1 = supports gun control)
    gun_item1 = if_else(pol_assault_ban      == 1, 1L, 0L),
    gun_item2 = if_else(pol_concealed_carry  == 2, 1L, 0L),
    gun_item3 = if_else(pol_background_check == 1, 1L, 0L),

    # Climate policy items (1 = supports climate action)
    climate_item1 = if_else(pol_climate_epa        == 1, 1L, 0L),
    climate_item2 = if_else(pol_climate_paris       == 1, 1L, 0L),
    climate_item3 = if_else(pol_climate_renewables  == 1, 1L, 0L),
    climate_item4 = if_else(pol_climate_carbon_tax  == 1, 1L, 0L)
  )

# Item matrices for scale functions
imm_items     <- ces |> select(imm_item1:imm_item5)
gun_items     <- ces |> select(gun_item1:gun_item3)
climate_items <- ces |> select(climate_item1:climate_item4)


# ==============================================================================
# SECTION 2: CRONBACH'S ALPHA
# ==============================================================================

# psych::alpha() computes Cronbach's alpha with item-level diagnostics.
# check.keys = TRUE auto-reverses negatively correlated items.

alpha_imm <- alpha(imm_items, check.keys = TRUE, na.rm = TRUE)
alpha_imm
# Key output:
#   raw_alpha          = Cronbach's alpha using raw variances
#   std.alpha          = alpha on standardized items
#   average_r          = average inter-item correlation
#   alpha.drop         = alpha if each item is deleted one at a time
#   item.stats         = item-total correlations

cat("Immigration scale alpha:", round(alpha_imm$total$raw_alpha, 3), "\n")

alpha_gun <- alpha(gun_items, check.keys = TRUE, na.rm = TRUE)
cat("Gun control scale alpha:", round(alpha_gun$total$raw_alpha, 3), "\n")

alpha_climate <- alpha(climate_items, check.keys = TRUE, na.rm = TRUE)
cat("Climate scale alpha:", round(alpha_climate$total$raw_alpha, 3), "\n")

# Benchmarks: >.9 excellent, >.8 good, >.7 acceptable, >.6 questionable


# ==============================================================================
# SECTION 3: SIMPLE ADDITIVE SCALE SCORES
# ==============================================================================

# rowMeans() with na.rm = TRUE computes the mean ignoring NA.
# Apply a minimum valid-items threshold to avoid scales dominated by imputation.

ces <- ces |>
  mutate(
    # Immigration scale: require >= 4 of 5 items
    imm_n_valid      = rowSums(!is.na(pick(imm_item1:imm_item5))),
    imm_scale_mean   = rowMeans(pick(imm_item1:imm_item5), na.rm = TRUE),
    imm_scale_mean   = if_else(imm_n_valid < 4, NA_real_, imm_scale_mean),

    # Gun control scale mean
    gun_scale_mean   = rowMeans(pick(gun_item1:gun_item3), na.rm = TRUE),

    # Climate scale mean
    climate_scale_mean = rowMeans(pick(climate_item1:climate_item4), na.rm = TRUE)
  ) |>
  select(-imm_n_valid)

ces |>
  summarise(
    across(c(imm_scale_mean, gun_scale_mean, climate_scale_mean),
           list(mean = ~ mean(.x, na.rm=TRUE), sd = ~ sd(.x, na.rm=TRUE)))
  )


# ==============================================================================
# SECTION 4: EXPLORATORY FACTOR ANALYSIS (EFA)
# ==============================================================================

# psych::fa() fits factor analysis with various extraction methods.
# fm = "pa" : principal axis (equivalent to Stata's method(pf))
# fm = "ml" : maximum likelihood
# rotate    = "varimax" (orthogonal) or "oblimin" (oblique, allows correlation)

# How many factors? Use parallel analysis (more rigorous than eigenvalue > 1)
fa.parallel(
  imm_items |> drop_na(),
  fa     = "fa",
  n.iter = 100,
  main   = "Parallel Analysis — Immigration Items"
)

# Single-factor EFA on immigration items
efa_imm1 <- fa(
  imm_items |> drop_na(),
  nfactors = 1,
  fm       = "pa",
  rotate   = "none"
)

print(efa_imm1, digits = 3, cut = 0.3)
# h2 = communality (variance explained by the factor)
# u2 = uniqueness (1 - h2)
# com = complexity (how many factors each item loads on)

# Two-factor EFA with rotation
efa_imm2 <- fa(
  imm_items |> drop_na(),
  nfactors = 2,
  fm       = "pa",
  rotate   = "oblimin"   # oblique — allows factors to correlate
)

print(efa_imm2, digits = 3, cut = 0.3)
fa.diagram(efa_imm2, main = "EFA: Immigration Items (2 Factors)")

# EFA across all three attitude domains — do they separate cleanly?
all_items <- ces |>
  select(imm_item1:imm_item5, gun_item1:gun_item3, climate_item1:climate_item4) |>
  drop_na()

efa_all3 <- fa(all_items, nfactors = 3, fm = "pa", rotate = "oblimin")
print(efa_all3, digits = 3, cut = 0.3)
fa.diagram(efa_all3, main = "EFA: All Attitude Items (3 Factors)")


# ==============================================================================
# SECTION 5: FACTOR SCORES
# ==============================================================================

# After EFA, extract factor scores (regression-weighted)
# Works on cases complete on all items in the model

efa_imm_scores <- fa(
  imm_items |> drop_na(),
  nfactors = 1,
  fm       = "pa",
  scores   = "regression"
)

factor_scores <- efa_imm_scores$scores |>
  as_tibble() |>
  rename(imm_factor_score = MR1)

# These scores have mean ~ 0 and SD ~ 1 (standardized)
summary(factor_scores$imm_factor_score)

# Attach to dataset (using row indices of complete cases)
ces_complete_idx <- which(complete.cases(ces[, paste0("imm_item", 1:5)]))
ces$imm_factor_score <- NA_real_
ces$imm_factor_score[ces_complete_idx] <- factor_scores$imm_factor_score

# Compare factor score to simple mean
cor(ces$imm_factor_score, ces$imm_scale_mean, use = "pairwise")
# If r > .95, the simple mean is a good approximation


# ==============================================================================
# SECTION 6: PRINCIPAL COMPONENTS ANALYSIS (PCA)
# ==============================================================================

# prcomp() is the base R function for PCA.
# scale. = TRUE standardizes variables before computing PCs.

pca_imm <- prcomp(
  imm_items |> drop_na(),
  scale. = TRUE
)

# Proportion of variance explained
summary(pca_imm)

# Scree plot
scree_df <- tibble(
  component = 1:length(pca_imm$sdev),
  eigenvalue = pca_imm$sdev^2
)

ggplot(scree_df, aes(x = component, y = eigenvalue)) +
  geom_line() +
  geom_point(size = 2) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "red") +
  labs(title = "Scree Plot: Immigration Items",
       x = "Component", y = "Eigenvalue") +
  theme_minimal()

# Loadings (rotation matrix)
pca_imm$rotation

# Extract PC1 scores
pc1_imm <- pca_imm$x[, 1]
summary(pc1_imm)

# Attach to dataset
ces$pc1_imm <- NA_real_
ces$pc1_imm[ces_complete_idx] <- pc1_imm

cor(ces$imm_factor_score, ces$pc1_imm, use = "pairwise")


# ==============================================================================
# SECTION 7: CONFIRMATORY FACTOR ANALYSIS (CFA) WITH LAVAAN
# ==============================================================================

# lavaan uses a model syntax where =~ defines factor loadings:
#   LatentFactor =~ item1 + item2 + item3 ...

ces_items_df <- ces |>
  select(imm_item1:imm_item5, gun_item1:gun_item3,
         climate_item1:climate_item4) |>
  drop_na() |>
  mutate(across(everything(), as.numeric))

# Single-factor CFA: immigration restrictionism
model_1f <- "
  ImmRestrict =~ imm_item1 + imm_item2 + imm_item3 + imm_item4 + imm_item5
"

fit_1f <- cfa(
  model_1f,
  data     = ces_items_df,
  estimator = "WLSMV"   # weighted least squares — appropriate for binary/ordinal items
)

summary(fit_1f, fit.measures = TRUE, standardized = TRUE)

# Key fit indices:
#   CFI   > .95 = excellent, > .90 = acceptable
#   RMSEA < .05 = close fit, < .08 = acceptable
#   SRMR  < .08 = acceptable

fitMeasures(fit_1f, c("cfi", "rmsea", "srmr", "tli"))

# Two-factor CFA: immigration + gun control (correlated factors)
model_2f <- "
  ImmRestrict =~ imm_item1 + imm_item2 + imm_item3 + imm_item4 + imm_item5
  GunControl  =~ gun_item1 + gun_item2 + gun_item3
  ImmRestrict ~~ GunControl   # allow factors to correlate
"

fit_2f <- cfa(model_2f, data = ces_items_df, estimator = "WLSMV")
summary(fit_2f, fit.measures = TRUE, standardized = TRUE)

# Compare 1-factor vs. 2-factor model
lavTestLRT(fit_1f, fit_2f)   # chi-square difference test

# Path diagram
# semPaths(fit_2f, what = "std", layout = "tree", edge.label.cex = 0.8)

# Modification indices (suggests which parameters to free for better fit)
modificationIndices(fit_1f, sort. = TRUE, maximum.number = 10)


# ==============================================================================
# SECTION 8: SAVE SCALES
# ==============================================================================

# Drop item variables, keep only scales and scores
ces <- ces |>
  select(-matches("_item\\d$"))

saveRDS(ces, "CES2020_with_scales.rds")
message("Module 11 complete. Dataset with scales saved.")
