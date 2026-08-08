# ==============================================================================
#  MODULE 12: PANEL DATA & REPEATED MEASURES
#  Dataset: CES 2020 (simulated two-wave panel)
#
#  Purpose: Fixed effects, random effects, and difference-in-differences
#  using plm (panel linear models) and lfe (large fixed effects).
#
#  install.packages(c("plm", "lfe", "fixest"))
#  fixest is the modern, fastest option for FE models — use it for large data.
# ==============================================================================

library(tidyverse)
library(plm)         # panel linear models (classic approach)
library(fixest)      # fast fixed effects (modern approach — recommended)
library(broom)
library(modelsummary)

ces <- readRDS("CES2020_clean.rds")


# ==============================================================================
# SECTION 1: CREATE A SIMULATED TWO-WAVE PANEL
# ==============================================================================

# Wave 1: baseline (pre-election)
wave1 <- ces |>
  select(caseid, age, sex, education, race_eth, college, white_nh,
         census_region, state_fips, ideology5, party_id3, dem, rep,
         imm_restrict, econ_retro, voted, wt_post) |>
  mutate(wave = 0)

# Wave 2: post-election — simulate change in ideology for college respondents
set.seed(20240101)

wave2 <- wave1 |>
  mutate(
    wave      = 1,
    ideo_noise = rnorm(n(), 0, 0.5),
    # Simulate treatment effect: college-educated shift slightly more liberal
    ideology5 = case_when(
      college == 1 ~ ideology5 - 0.3 + ideo_noise,
      TRUE         ~ ideology5 + ideo_noise
    ),
    ideology5 = pmax(1, pmin(5, ideology5))   # clamp to [1, 5]
  ) |>
  select(-ideo_noise)

panel_df <- bind_rows(wave1, wave2) |>
  arrange(caseid, wave)

cat("Panel observations:", nrow(panel_df), "\n")
cat("Unique respondents:", n_distinct(panel_df$caseid), "\n")


# ==============================================================================
# SECTION 2: DECLARE PANEL STRUCTURE WITH PLM
# ==============================================================================

# pdata.frame() declares the panel structure — sets index (unit, time)
panel_plm <- pdata.frame(panel_df, index = c("caseid", "wave"))

# pdim() summarizes the panel structure
pdim(panel_plm)

# Within vs. between variance for key variables
summary(Between(panel_plm$ideology5))   # between-person variance
summary(Within(panel_plm$ideology5))    # within-person variance (over waves)


# ==============================================================================
# SECTION 3: POOLED OLS (BASELINE)
# ==============================================================================

# Ignores panel structure — standard lm() with clustered SEs on person ID
m_pooled <- lm(ideology5 ~ college + wave + age + factor(sex),
               data = panel_df)

# Cluster SEs by person (caseid) using sandwich
library(sandwich)
library(lmtest)
coeftest(m_pooled, vcov = vcovCL(m_pooled, cluster = ~ caseid))


# ==============================================================================
# SECTION 4: FIXED EFFECTS MODEL
# ==============================================================================

# plm with model = "within" estimates the within (FE) estimator
# FE removes all time-invariant variation: age, sex, race drop out automatically

m_fe_plm <- plm(
  ideology5 ~ college + wave,
  data  = panel_plm,
  model = "within",
  effect = "individual"   # individual FE (demean within person)
)

summary(m_fe_plm)

# Clustered SEs (cluster on individual)
coeftest(m_fe_plm, vcov = plm::vcovHC(m_fe_plm, type = "HC1", cluster = "group"))

# --- Using fixest (faster, modern alternative) ---
m_fe_fixest <- feols(
  ideology5 ~ college + wave | caseid,   # | caseid = absorb individual FE
  data    = panel_df,
  cluster = ~ caseid
)

summary(m_fe_fixest)
# fixest absorbs fixed effects efficiently — critical for large panels


# ==============================================================================
# SECTION 5: RANDOM EFFECTS MODEL
# ==============================================================================

# plm with model = "random" estimates the GLS random effects estimator
# RE assumes unit effects are UNCORRELATED with predictors (strong assumption)
# Advantage over FE: can include time-invariant predictors (sex, race, etc.)

m_re <- plm(
  ideology5 ~ college + wave + age + factor(sex),
  data  = panel_plm,
  model = "random"
)

summary(m_re)


# ==============================================================================
# SECTION 6: HAUSMAN TEST — FE VS. RE
# ==============================================================================

# phtest() runs the Hausman test comparing FE and RE coefficients
# H0: RE is consistent (FE and RE give similar estimates)
# Reject H0 → use FE

phtest(m_fe_plm, m_re)

# Significant p-value: RE is inconsistent (endogeneity in random effects)
# → prefer fixed effects for causal inference


# ==============================================================================
# SECTION 7: FIRST DIFFERENCES
# ==============================================================================

# plm with model = "fd" computes first-difference estimator
# With T=2, FD and FE give identical estimates

m_fd <- plm(
  ideology5 ~ college + wave,
  data  = panel_plm,
  model = "fd"
)

summary(m_fd)

# Manual first differences using dplyr
panel_fd <- panel_df |>
  arrange(caseid, wave) |>
  group_by(caseid) |>
  mutate(
    d_ideology5 = ideology5 - lag(ideology5),
    d_college   = college   - lag(college)
  ) |>
  filter(wave == 1) |>   # keep only the difference rows
  ungroup()

lm(d_ideology5 ~ d_college, data = panel_fd) |>
  coeftest(vcov = vcovHC(lm(d_ideology5 ~ d_college, data = panel_fd),
                         type = "HC3"))


# ==============================================================================
# SECTION 8: DIFFERENCE-IN-DIFFERENCES (DiD)
# ==============================================================================

# DiD setup:
#   Treated = college == 1
#   Post    = wave == 1
#   DiD     = Treated × Post interaction
#
# The β on the interaction is the Average Treatment Effect on the Treated (ATT),
# under the parallel trends assumption.

panel_did <- panel_df |>
  mutate(
    treated = college,
    post    = wave,
    did     = treated * post
  )

# Standard DiD regression
m_did <- lm(
  ideology5 ~ treated + post + did,
  data = panel_did
)

coeftest(m_did, vcov = vcovCL(m_did, cluster = ~ caseid))

# Equivalent using * notation (includes main effects + interaction)
m_did2 <- lm(
  ideology5 ~ treated * post,
  data = panel_did
)

coeftest(m_did2, vcov = vcovCL(m_did2, cluster = ~ caseid))

# DiD with additional controls
m_did_controls <- lm(
  ideology5 ~ treated * post + age + factor(sex) + factor(census_region),
  data = panel_did
)

coeftest(m_did_controls, vcov = vcovCL(m_did_controls, cluster = ~ caseid))

# fixest version (cleanest syntax, handles clustering automatically)
m_did_fixest <- feols(
  ideology5 ~ i(post, treated, ref = 0) +    # interaction with reference period
    age + factor(sex),
  data    = panel_did,
  cluster = ~ caseid
)

summary(m_did_fixest)


# ==============================================================================
# SECTION 9: PARALLEL TRENDS PLOT
# ==============================================================================

trend_df <- panel_did |>
  group_by(treated, wave) |>
  summarise(mean_ideo = mean(ideology5, na.rm = TRUE), .groups = "drop")

ggplot(trend_df, aes(x = wave, y = mean_ideo,
                     color = factor(treated),
                     group = factor(treated))) +
  geom_line(linewidth = 1) +
  geom_point(size = 3) +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "gray50") +
  scale_x_continuous(breaks = c(0, 1), labels = c("Pre", "Post")) +
  scale_color_manual(values = c("navy", "firebrick"),
                     labels = c("No College (Control)", "College (Treated)"),
                     name   = NULL) +
  labs(
    title    = "Parallel Trends Check",
    subtitle = "Mean Ideology by Treatment Group and Wave",
    x        = NULL,
    y        = "Mean Ideology (1=Very Liberal, 5=Very Conservative)"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("parallel_trends.png", width = 7, height = 5, dpi = 300)


# ==============================================================================
# SECTION 10: RESULTS TABLE
# ==============================================================================

# RE model (plm object) doesn't support sandwich cluster SEs via modelsummary;
# show it separately and include only lm-based models in the joint table.
tidy(m_re, conf.int = TRUE)

models_panel <- list(
  "Pooled OLS" = m_pooled,
  "DiD"        = m_did_controls
)

modelsummary(
  models_panel,
  vcov    = ~ caseid,    # cluster SEs on person for all models
  stars   = c("*" = .05, "**" = .01, "***" = .001),
  title   = "Panel Models: Effect of College on Ideology"
)

# FE model separately (fixest object)
modelsummary(
  list("Fixed Effects" = m_fe_fixest),
  stars = c("*" = .05, "**" = .01, "***" = .001)
)

message("Module 12 complete.")
