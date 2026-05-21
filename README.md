# Clustering the Iris Dataset: K-Means, Hierarchical & GMM

A comparison of three clustering methods on the classic Iris dataset, showing
why Gaussian Mixture Models capture group structure better than distance-based approaches when clusters overlap.

## Motivation

K-Means and Hierarchical clustering assign each point to exactly one group based
on distance. That works well when groups are compact and well-separated — but the
Iris dataset has significant overlap between *versicolor* and *virginica*. GMM handles
this naturally by estimating the probability of each point belonging to each cluster,
rather than making hard assignments.

## What the script does

1. **EDA** — pairwise scatterplots to visualize the natural group structure
2. **K-Means** — elbow and silhouette methods to choose K, then fit with K = 3
3. **Hierarchical** — Ward's linkage + dendrogram, cut at K = 3
4. **GMM (mclust)** — BIC to select the best model and number of components automatically, then fit with K = 3 for a fair comparison
5. **Comparison** — Adjusted Rand Index (ARI) against the true species labels

## Results

| Method       | ARI   |
|--------------|-------|
| K-Means      | 0.620 |
| Hierarchical | 0.615 |
| **GMM**      | **0.904** |

GMM classified *setosa* and *virginica* perfectly and misclassified only 5 *versicolor* observations, while K-Means misclassified 50. The reason: GMM's probabilistic framework naturally handles the overlap between those two species that rigid distance-based methods struggle with.

Interestingly, when left to choose freely via BIC, GMM selected K = 2 — correctly identifying that *setosa* is perfectly separable while *versicolor* and *virginica* form one overlapping group.

## Stack

R · mclust · factoextra · cluster · dendextend · ggplot2

```r
# packages
install.packages(c("mclust", "cluster", "factoextra", "dendextend", "ggplot2"))

# run
source("clustering_iris.R")
```

## Figures

| File | Description |
|------|-------------|
| `01_eda_pairs.png` | Pairwise scatterplots (true labels) |
| `02_kmeans_elbow.png` | Elbow method |
| `03_kmeans_silhouette.png` | Silhouette method |
| `04_kmeans_result.png` | K-Means clusters (K = 3) |
| `05_dendrogram.png` | Hierarchical clustering dendrogram |
| `06_gmm_bic.png` | BIC across models and K values |
| `07_gmm_classification.png` | GMM classification (K = 3) |
| `08_comparison_ari.png` | ARI comparison across methods |
