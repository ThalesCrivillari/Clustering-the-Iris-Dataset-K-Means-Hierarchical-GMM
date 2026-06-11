# Clustering the Iris Dataset: K-Means, Hierarchical & GMM

A comparison of three clustering methods on the classic Iris dataset, showing why
Gaussian Mixture Models capture group structure better than distance-based
approaches when clusters overlap.

A full write-up with all the figures and the reasoning behind each step is in
[`Iris_github.pdf`](Iris_github.pdf).

## Motivation

K-Means and Hierarchical clustering assign each point to exactly one group based on
distance. That works well when groups are compact and well-separated, but the Iris
dataset has heavy overlap between *versicolor* and *virginica*. A GMM handles this
naturally: instead of a hard assignment, it models each cluster as a Gaussian with
its own shape and orientation, and asks how likely each point is to have come from
each one.

## What the script does

1. **EDA** — pairwise scatterplots to visualize the natural group structure.
2. **K-Means** — elbow and silhouette diagnostics to pick K, then a final fit at K = 3.
3. **Hierarchical** — Ward's linkage with a colored dendrogram, cut at K = 3.
4. **GMM (mclust)** — BIC selects the number of components and covariance shape
   automatically, then a refit at K = 3 for a fair comparison.
5. **Comparison** — Adjusted Rand Index (ARI) of all three methods against the true
   species labels.

## Results

| Method       | ARI       |
| ------------ | --------- |
| Hierarchical | 0.615     |
| K-Means      | 0.620     |
| **GMM**      | **0.904** |

K-Means and Hierarchical clustering both plateau around 0.62: they assume roughly
spherical groups and separate by distance, so they trip on the same overlapping
region between *versicolor* and *virginica*. GMM reaches 0.90 because its ellipses
can stretch and rotate to follow the real shape of each cloud, misclassifying only
5 of the 150 flowers.

## A note on the BIC

When BIC is left to choose freely, `mclust` lands on **2 components** rather than 3,
reading the overlapping *versicolor* + *virginica* pair as a single blob. But the
BIC values for 2 and 3 groups are almost tied — the curve jumps from 1 to 2 and
then barely moves. Since the elbow method and the known ground truth both point to
3, the most honest reading is not "there are only 2 groups" but rather that the
third split is real, just subtle. We fix K = 3 so all three methods are compared on
equal footing.

## Stack

R · mclust · factoextra · cluster · dendextend · ggplot2 · GGally

```r
# packages
install.packages(c("mclust", "cluster", "factoextra",
                   "dendextend", "ggplot2", "GGally"))

# run (uses set.seed(236312) for reproducibility)
source("clustering_iris.R")
```

All figures are written to `figs/`.

## Figures

| File                          | Description                          |
| ----------------------------- | ------------------------------------ |
| `01_eda_pairs.png`            | Pairwise scatterplots (true labels)  |
| `02_kmeans_diagnostico.png`   | Elbow + silhouette diagnostics       |
| `03_kmeans_clusters.png`      | K-Means clusters (K = 3)             |
| `04_dendrograma.png`          | Ward's linkage dendrogram, cut at K = 3 |
| `05_gmm_bic.png`              | BIC across models and number of components |
| `06_gmm_classification.png`   | GMM classification (K = 3)           |
| `07_ari_comparacao.png`       | ARI comparison across methods        |

## Repository

```
.
├── clustering_iris.R   # full analysis script
├── Iris_github.pdf      # written report with all figures
├── README.md
└── figs/                # generated when you run the script
```

---

*Thales de Souza Crivillari*
