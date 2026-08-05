# ==============================================================================
#  MODULE 6: DATA VISUALIZATION WITH GGPLOT2
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Purpose: Build a library of publication-quality graphs using ggplot2.
#  Covers histograms, bar charts, box plots, scatter plots, coefficient plots,
#  predicted probability plots, and faceted panels.
#
#  ggplot2 grammar:
#    ggplot(data, aes(x, y, color, fill, ...)) +
#    geom_*() +           # geometric layer (point, line, bar, etc.)
#    scale_*() +          # axis/color/fill scales
#    facet_*() +          # small multiples
#    labs() +             # titles and labels
#    theme_*()            # overall appearance
# ==============================================================================

library(tidyverse)
library(scales)           # percent(), comma() formatting helpers
library(patchwork)        # combine multiple ggplots (install.packages("patchwork"))
library(ggrepel)          # non-overlapping text labels (install.packages("ggrepel"))
library(marginaleffects)  # predicted probability grids

ces <- readRDS("CES2020_clean.rds")

# Set a consistent theme for the whole session
theme_set(theme_minimal(base_size = 12))


# ==============================================================================
# SECTION 1: HISTOGRAM — CONTINUOUS VARIABLE
# ==============================================================================

# geom_histogram() for continuous distributions
# bins or binwidth controls bin size
# after_stat(density) normalizes to density; default is count

ggplot(ces, aes(x = age)) +
  geom_histogram(bins = 30, fill = "navy", color = "white", alpha = 0.8) +
  stat_function(
    fun  = dnorm,
    args = list(mean = mean(ces$age, na.rm = TRUE),
                sd   = sd(ces$age, na.rm = TRUE)),
    aes(y = after_stat(y) * nrow(na.omit(ces["age"])) * (max(ces$age, na.rm=TRUE) -
                                                           min(ces$age, na.rm=TRUE)) / 30),
    color = "red", linewidth = 0.8
  ) +
  labs(title = "Age Distribution of CES 2020 Respondents",
       x = "Age", y = "Count") +
  theme_minimal()

ggsave("hist_age.png", width = 8, height = 5, dpi = 300)

# Immigration restrictionism (discrete — use geom_bar or histogram with breaks)
ggplot(ces |> filter(!is.na(imm_restrict)),
       aes(x = factor(imm_restrict))) +
  geom_bar(fill = "darkgreen", alpha = 0.7, color = "white") +
  labs(title  = "Immigration Restrictionism Index",
       x      = "Restrictionism Score (0 = Least, 5 = Most)",
       y      = "Count") +
  theme_minimal()

ggsave("hist_imm_restrict.png", width = 8, height = 5, dpi = 300)


# ==============================================================================
# SECTION 2: BAR CHARTS — PROPORTIONS
# ==============================================================================

# Compute proportions first, then plot with geom_col()
# geom_col() uses pre-computed heights; geom_bar() counts rows

voted_by_educ <- ces |>
  filter(!is.na(voted), !is.na(education)) |>
  group_by(education) |>
  summarise(prop_voted = mean(voted),
            n          = n(),
            se         = sqrt(prop_voted * (1 - prop_voted) / n))

ggplot(voted_by_educ, aes(x = factor(education), y = prop_voted)) +
  geom_col(fill = "navy", alpha = 0.8) +
  geom_errorbar(aes(ymin = prop_voted - 1.96 * se,
                    ymax = prop_voted + 1.96 * se),
                width = 0.2, color = "gray30") +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "red") +
  scale_x_discrete(labels = c("No HS","HS grad","Some coll.","Assoc.","Bach.","Postgrad")) +
  scale_y_continuous(labels = percent_format()) +
  labs(title = "Voter Turnout by Education Level",
       x     = "Education",
       y     = "Proportion Who Voted") +
  theme_minimal()

ggsave("bar_voted_by_educ.png", width = 9, height = 5, dpi = 300)

# Biden vote share by party ID (voters only)
biden_by_party <- ces |>
  filter(voted == 1, !is.na(biden_voter), !is.na(party_id3)) |>
  group_by(party_id3) |>
  summarise(prop_biden = mean(biden_voter))

ggplot(biden_by_party, aes(x = factor(party_id3), y = prop_biden,
                            fill = factor(party_id3))) +
  geom_col(alpha = 0.85) +
  geom_text(aes(label = percent(prop_biden, accuracy = 1)),
            vjust = -0.5, size = 3.5) +
  scale_x_discrete(labels = c("Democrat", "Republican", "Independent")) +
  scale_fill_manual(values = c("blue", "red", "darkgreen"), guide = "none") +
  scale_y_continuous(labels = percent_format(), limits = c(0, 1.05)) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray40") +
  labs(title = "Biden Vote Share by Party Identification (Voters Only)",
       x     = "Party ID",
       y     = "Proportion Voting Biden") +
  theme_minimal()

ggsave("bar_biden_by_party.png", width = 7, height = 5, dpi = 300)


# ==============================================================================
# SECTION 3: BOX PLOTS
# ==============================================================================

# geom_boxplot() shows median, IQR, and outliers
# geom_jitter() overlays raw data points (useful for moderate N)

ggplot(ces |> filter(!is.na(imm_restrict), !is.na(party_id3)),
       aes(x = factor(party_id3), y = imm_restrict,
           fill = factor(party_id3))) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.1) +
  scale_x_discrete(labels = c("Democrat", "Republican", "Independent")) +
  scale_fill_manual(values = c("blue", "red", "darkgreen"), guide = "none") +
  labs(title = "Distribution of Immigration Restrictionism by Party",
       x     = "Party ID",
       y     = "Restrictionism Score (0–5)") +
  theme_minimal()

ggsave("box_imm_by_party.png", width = 7, height = 5, dpi = 300)

# Age by voter turnout
ggplot(ces |> filter(!is.na(voted)),
       aes(x = factor(voted), y = age, fill = factor(voted))) +
  geom_boxplot(alpha = 0.7) +
  scale_x_discrete(labels = c("Did Not Vote", "Voted")) +
  scale_fill_manual(values = c("gray60", "navy"), guide = "none") +
  labs(title = "Age Distribution by Voter Turnout",
       x     = NULL,
       y     = "Age") +
  theme_minimal()

ggsave("box_age_by_voted.png", width = 6, height = 5, dpi = 300)


# ==============================================================================
# SECTION 4: SCATTER PLOT WITH FITTED LINE
# ==============================================================================

# geom_point() for raw data; geom_smooth() for fitted line
# method = "lm" gives OLS line; method = "loess" gives nonparametric smoother
# alpha controls transparency (useful with large N to show density)

ggplot(ces |> filter(!is.na(imm_restrict), !is.na(age)),
       aes(x = age, y = imm_restrict)) +
  geom_jitter(alpha = 0.05, color = "navy", size = 0.3, height = 0.15) +
  geom_smooth(method = "lm", color = "red", se = TRUE) +
  labs(title = "Age and Immigration Restrictionism",
       x     = "Age",
       y     = "Restrictionism Index (0–5)") +
  theme_minimal()

ggsave("scatter_age_imm.png", width = 8, height = 5, dpi = 300)

# Education vs. ideology with loess
ggplot(ces |> filter(!is.na(ideology5), !is.na(education)),
       aes(x = education, y = ideology5)) +
  geom_jitter(alpha = 0.05, color = "darkgreen", size = 0.3, width = 0.2) +
  geom_smooth(method = "loess", color = "orange", se = TRUE, linewidth = 1) +
  scale_x_continuous(breaks = 1:6,
                     labels = c("No HS","HS","Some coll.","Assoc.","Bach.","Postgrad")) +
  labs(title = "Education and Ideology",
       x     = "Education Level",
       y     = "Ideology (1=Very Lib, 5=Very Con)") +
  theme_minimal()

ggsave("scatter_educ_ideo.png", width = 8, height = 5, dpi = 300)


# ==============================================================================
# SECTION 5: COEFFICIENT PLOT (FOREST PLOT)
# ==============================================================================

# Tidy the model output, filter out the intercept and factor base levels,
# then plot with geom_point + geom_errorbar

library(broom)

m_turnout <- glm(
  voted ~ education + age + factor(sex) + factor(census_region) +
    ideology5 + party_id7,
  data   = ces,
  family = binomial()
)

coef_df <- tidy(m_turnout, conf.int = TRUE) |>
  filter(term != "(Intercept)") |>
  mutate(
    significant = p.value < 0.05,
    term = str_replace_all(term, c(
      "factor\\(sex\\)2"            = "Female (ref: Male)",
      "factor\\(census_region\\)2"  = "Region: Midwest",
      "factor\\(census_region\\)3"  = "Region: South",
      "factor\\(census_region\\)4"  = "Region: West"
    ))
  )

ggplot(coef_df, aes(x = estimate, y = reorder(term, estimate),
                    color = significant)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(size = 3) +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.2) +
  scale_color_manual(values = c("gray60", "navy"),
                     labels = c("p ≥ .05", "p < .05"),
                     name   = NULL) +
  labs(title = "Logit Coefficients: Voter Turnout Model",
       x     = "Log-Odds Coefficient (95% CI)",
       y     = NULL) +
  theme_minimal()

ggsave("coefplot_turnout.png", width = 9, height = 6, dpi = 300)

# Odds ratio version (exponentiate, reference line at 1 not 0)
coef_or <- tidy(m_turnout, exponentiate = TRUE, conf.int = TRUE) |>
  filter(term != "(Intercept)")

ggplot(coef_or, aes(x = estimate, y = reorder(term, estimate))) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "gray50") +
  geom_point(color = "darkgreen", size = 3) +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high),
                 height = 0.2, color = "darkgreen") +
  scale_x_log10() +     # log scale keeps ORs symmetric around 1
  labs(title = "Odds Ratios: Voter Turnout Model",
       x     = "Odds Ratio (log scale, 95% CI)",
       y     = NULL) +
  theme_minimal()

ggsave("coefplot_OR.png", width = 9, height = 6, dpi = 300)


# ==============================================================================
# SECTION 6: PREDICTED PROBABILITY PLOTS
# ==============================================================================

library(marginaleffects)

m_voted2 <- glm(
  voted ~ education + age + factor(sex) + ideology5 + party_id7,
  data   = ces,
  family = binomial()
)

pred_sex <- predictions(
  m_voted2,
  newdata = datagrid(education = 1:6, sex = 1:2)
)

ggplot(pred_sex, aes(x = education, y = estimate,
                     color = factor(sex), fill = factor(sex))) +
  geom_line(linewidth = 1) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.15) +
  scale_color_manual(values = c("navy", "firebrick"),
                     labels = c("Male", "Female"), name = "Sex") +
  scale_fill_manual(values  = c("navy", "firebrick"),
                    labels = c("Male", "Female"), name = "Sex") +
  scale_x_continuous(breaks = 1:6,
                     labels = c("No HS","HS","Some coll.","Assoc.","Bach.","Postgrad"),
                     guide  = guide_axis(angle = 30)) +
  scale_y_continuous(labels = percent_format(), limits = c(0, 1)) +
  labs(title    = "Predicted Probability of Voting",
       subtitle = "By Education and Sex (other variables at mean)",
       x        = "Education Level",
       y        = "Pr(Voted)") +
  theme_minimal()

ggsave("marginsplot_voted_educ_sex.png", width = 9, height = 6, dpi = 300)


# ==============================================================================
# SECTION 7: PROFILE PLOT (GROUP MEANS OVER A COVARIATE)
# ==============================================================================

profile_df <- ces |>
  filter(!is.na(imm_restrict), !is.na(education), !is.na(party_id3)) |>
  group_by(education, party_id3) |>
  summarise(
    mean_restrict = mean(imm_restrict),
    se            = sd(imm_restrict) / sqrt(n()),
    .groups       = "drop"
  )

ggplot(profile_df, aes(x = education, y = mean_restrict,
                       color = factor(party_id3),
                       group = factor(party_id3))) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  geom_errorbar(aes(ymin = mean_restrict - 1.96 * se,
                    ymax = mean_restrict + 1.96 * se),
                width = 0.15) +
  scale_color_manual(values = c("blue", "red", "darkgreen"),
                     labels = c("Democrat", "Republican", "Independent"),
                     name   = "Party ID") +
  scale_x_continuous(breaks = 1:6,
                     labels = c("No HS","HS","Some coll.","Assoc.","Bach.","Postgrad"),
                     guide  = guide_axis(angle = 30)) +
  geom_hline(yintercept = 2.5, linetype = "dashed", color = "gray50") +
  labs(title = "Immigration Restrictionism by Education and Party",
       x     = "Education Level",
       y     = "Mean Restrictionism (0–5)") +
  theme_minimal()

ggsave("profile_restrict_educ_party.png", width = 9, height = 6, dpi = 300)


# ==============================================================================
# SECTION 8: FACETED PLOTS (SMALL MULTIPLES)
# ==============================================================================

# facet_wrap() creates a panel for each level of a variable
# facet_grid() creates a row × column grid of panels

# Biden vote share by education, faceted by region
biden_educ_region <- ces |>
  filter(voted == 1, !is.na(biden_voter), !is.na(education),
         !is.na(census_region)) |>
  group_by(census_region, education) |>
  summarise(prop_biden = mean(biden_voter), .groups = "drop")

region_labels <- c("1" = "Northeast", "2" = "Midwest",
                   "3" = "South",     "4" = "West")

ggplot(biden_educ_region,
       aes(x = factor(education), y = prop_biden, fill = prop_biden)) +
  geom_col() +
  facet_wrap(~ census_region, labeller = labeller(census_region = region_labels)) +
  scale_fill_gradient2(low = "red", mid = "white", high = "blue",
                       midpoint = 0.5, guide = "none") +
  scale_x_discrete(labels = c("None","HS","Some","Assoc.","Bach.","Post.")) +
  scale_y_continuous(labels = percent_format(), limits = c(0, 1)) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray30") +
  labs(title = "Biden Vote Share by Education, Faceted by Region",
       x     = "Education",
       y     = "Proportion Voting Biden") +
  theme_minimal()

ggsave("facet_biden_educ_region.png", width = 10, height = 7, dpi = 300)


# ==============================================================================
# SECTION 9: COMBINING PLOTS WITH PATCHWORK
# ==============================================================================

# patchwork uses +, /, and | to arrange ggplot objects
# | = side by side; / = stacked; + with plot_layout() for grids

p1 <- ggplot(ces, aes(x = age)) +
  geom_histogram(bins = 25, fill = "navy", color = "white", alpha = 0.8) +
  labs(title = "Age", x = "Age", y = "Count") +
  theme_minimal()

p2 <- ggplot(ces |> filter(!is.na(imm_restrict)),
             aes(x = factor(imm_restrict))) +
  geom_bar(fill = "darkgreen", alpha = 0.8) +
  labs(title = "Restrictionism", x = "Score (0–5)", y = "Count") +
  theme_minimal()

p3 <- ggplot(ces |> filter(!is.na(ideology5)),
             aes(x = factor(ideology5))) +
  geom_bar(fill = "firebrick", alpha = 0.8) +
  scale_x_discrete(labels = c("V.Lib","Lib","Mod","Con","V.Con")) +
  labs(title = "Ideology", x = NULL, y = "Count") +
  theme_minimal()

combined <- p1 | p2 | p3
combined + plot_annotation(
  title    = "CES 2020: Key Variable Distributions",
  subtitle = "N ≈ 60,000 respondents"
)

ggsave("combined_distributions.png", width = 14, height = 5, dpi = 300)


# ==============================================================================
# SECTION 10: THEME CUSTOMIZATION FOR PUBLICATION
# ==============================================================================

# Custom theme for clean publication output
theme_publication <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor  = element_blank(),
      panel.grid.major  = element_line(color = "gray90", linewidth = 0.3),
      axis.line         = element_line(color = "gray30", linewidth = 0.4),
      axis.ticks        = element_line(color = "gray30"),
      plot.title        = element_text(face = "bold", size = base_size + 2),
      plot.subtitle     = element_text(color = "gray40", size = base_size),
      legend.position   = "bottom",
      legend.key.size   = unit(0.8, "lines"),
      strip.text        = element_text(face = "bold")
    )
}

# Apply publication theme to the profile plot
ggplot(profile_df, aes(x = education, y = mean_restrict,
                       color = factor(party_id3),
                       group = factor(party_id3))) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  scale_color_manual(values = c("blue", "red", "darkgreen"),
                     labels = c("Democrat", "Republican", "Independent"),
                     name   = "Party ID") +
  scale_x_continuous(breaks = 1:6,
                     labels = c("No HS","HS","Some coll.","Assoc.","Bach.","Postgrad")) +
  labs(title = "Immigration Restrictionism by Education and Party",
       x = "Education Level", y = "Mean Restrictionism (0–5)") +
  theme_publication()

ggsave("profile_publication_theme.png", width = 9, height = 6, dpi = 300)

message("Module 6 complete. Check your directory for .png files.")
