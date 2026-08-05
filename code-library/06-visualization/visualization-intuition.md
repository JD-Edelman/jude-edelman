# Visualization — Intuition

## 1. What Problem Does This Solve?

Numbers in tables are hard to process at scale. A regression output with 15 coefficients tells you something, but the human visual system cannot quickly answer "which of these is largest?", "are most of them positive?", or "do any confidence intervals overlap zero?" by scanning rows. Visualization translates quantitative structure into perceptual signals that the brain processes faster and more reliably than text.

The specific problems visualization solves in social science research:

- **Distribution shape**: a mean and SD do not tell you whether a variable is skewed, bimodal, or has outliers. A histogram or density plot does.
- **Relationship patterns**: two variables can have identical correlations but very different scatterplot patterns (Anscombe's Quartet is the canonical example). A number hides what a plot reveals.
- **Magnitude and uncertainty together**: a table shows β̂ and SE separately; a coefficient plot shows them as a point and interval, making relative magnitude and statistical uncertainty readable at a glance.
- **Comparison across groups**: side-by-side panels or color-coded series expose group differences that a table of means obscures.

## 2. When Would a Researcher Reach for It — and When Not?

**Use visualization when:**

- Exploring data for the first time (check distributions, outliers, missingness patterns).
- Communicating findings to a non-technical audience.
- Presenting regression results where the focus is on the sign and relative size of several coefficients.
- Showing distributional overlap or separation between groups.
- Making a descriptive argument that a relationship exists before modeling it.

**Be cautious or avoid when:**

- Precise numerical values matter (tables serve that need better).
- The audience needs exact p-values or point estimates to replicate your work.
- The plot would require more than a paragraph of explanation to interpret correctly.
- You are dealing with high-dimensional data where pairwise plots multiply unmanageably.

## 3. How the Mechanism Works in Plain Language

### The Hierarchy of Visual Channels

Perceptual research (Cleveland and McGill's foundational work) shows that humans decode some visual properties more accurately than others. In rough order from most to least accurate:

1. Position along a common scale (bar height, dot on an axis)
2. Length (bar length without a shared baseline is less accurate)
3. Angle (pie slices — harder to compare than you think)
4. Area (bubble size — even harder)
5. Color hue (categorizes but does not convey quantity)

This hierarchy has direct design implications. A bar chart wins over a pie chart because bar height uses position along a common scale; pie slices use angle. Even if the slice labeled "37%" looks about right, comparing two similar-sized slices (say, 31% vs. 34%) is genuinely difficult, while comparing two bar heights is easy.

### Histograms vs. Density Plots

A histogram bins the data into discrete intervals and shows counts or proportions per bin. The shape you see depends on how you chose the bin width, which is an analyst decision, not a property of the data. Change the bin width and the picture changes, sometimes dramatically.

A kernel density estimate (KDE) smooths over that problem by placing a small curve at each data point and summing them. The result is a continuous curve without hard bin edges. KDE is more visually elegant but has its own choice: bandwidth. A too-wide bandwidth over-smooths and hides real features (two modes look like one); a too-narrow bandwidth creates noise spikes at individual observations.

The honest choice depends on sample size and purpose. For small samples, a histogram is more transparent because you can see the raw data structure. For larger samples, KDE communicates shape better. For a public presentation, KDE typically looks cleaner. When distribution shape matters for a methods paper, show both.

### Overplotting in Scatter Plots

When you have thousands of respondents (CES 2020 has roughly 61,000), a standard scatter plot is a black rectangle. Every dot overlaps every other dot. Strategies to address this:

- **Jitter**: add a small random displacement to each point so overlapping points separate visually. Best for discrete variables where many observations share exact coordinates.
- **Alpha transparency**: make each dot semi-transparent, so dense regions appear darker. Works well for continuous variables.
- **Binning (2D histogram or hex bins)**: divide the plot area into cells and color each cell by count. Shows density structure without individual points.

### Coefficient Plots

A coefficient plot shows each predictor on the y-axis with its point estimate on the x-axis and a horizontal line for the confidence interval. A vertical reference line sits at zero. The reader can immediately see: which coefficients are large in absolute terms, which are positive vs. negative, and which CIs cross zero (not distinguishable from null). This is information that would require scanning multiple columns in a table.

### Facets vs. Color

When you want to compare a relationship across groups, you have two options. Color uses different hues to distinguish groups within a single plot; facets (also called small multiples) replicate the plot once per group in separate panels.

Color is appropriate when the groups overlap in the data space and you want to see that overlap directly (e.g., two income distributions on the same axis). Facets are appropriate when the groups' data ranges are similar but you want to examine each group's pattern without visual clutter, or when you have more than 3-4 groups (color palettes degrade with more than 4-5 categories).

### Exploratory vs. Presentation Visualization

An exploratory plot is for you. It should be fast to produce, may have default colors and axis labels, and can be ugly as long as it reveals something true. An exploratory plot that takes 30 minutes to polish is wasted effort if it ends up in your notes and nowhere else.

A presentation plot is for an audience. It earns investment in axis labels that explain units, a title that states the takeaway, legends that are readable without prior knowledge, and color choices that remain interpretable in black-and-white print and for color-blind viewers. The same underlying data may support both, but they should be made separately with different goals.

## 4. Honest Strengths vs. Weaknesses

**Strengths:**

- Reveals distributional features (skew, bimodality, outliers) invisible in summary statistics.
- Communicates effect size and uncertainty simultaneously when done well.
- Builds intuition for data structure before modeling.
- In presentation contexts, makes findings accessible to readers who will not engage with regression tables.

**Weaknesses:**

- Plots can mislead. A truncated y-axis makes tiny differences look dramatic. Wide bins on a histogram can erase a real bimodal structure. These are not just beginner mistakes; they appear in published work.
- Visualization of more than 2-3 variables simultaneously is hard. High-dimensional structure (like what a principal components analysis finds) cannot be faithfully shown in 2D without assumptions.
- Plots are harder to replicate precisely than tables. A reader cannot extract exact numbers from a bar chart.
- Color choices that look fine on your monitor may print poorly, appear different on a projector, or be unreadable for people with color vision deficiency. Colorbrewer palettes and viridis address this but require deliberate choices.
