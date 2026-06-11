
#pacotes e funcao para conferir se esta instalado

install.packages(c("mclust", "cluster", "factoextra",
                   "dendextend", "ggplot2", "GGally"))
library(ggplot2)
library(dplyr)
library(tibble)
library(GGally)
library(cluster)
library(factoextra)
library(dendextend)
library(mclust)
library(patchwork)



#ajustes
set.seed(236312)                       #  porque ok-means usa início aleatório)
dir.create("figs", showWarnings = FALSE)   # pasta de saída das figuras


#Paleta consistente entre os gráficos
pal <- c("#2C6E9B", "#C0392B", "#27AE60")

#Preparando so dados

# Usamos as 4 variáveis numéricas. Para K-Means e Hierárquico padronizamos
# (z-score), porque ambos dependem de distância euclidiana e são sensíveis à
# escala. Para o GMM mantemos os dados na escala original: o mclust modela a
# matriz de covariância de cada componente, então a escala é absorvida pelo
# próprio modelo.
data(iris)
X            <- iris[, 1:4]
X_scaled     <- scale(X)
true_labels  <- as.integer(iris$Species)   # rótulos reais (1=setosa, 2=versicolor, 3=virginica)


#Analise exploratoria

p_eda <- ggpairs(
  iris,
  columns      = 1:4,
  mapping      = aes(color = Species, alpha = 0.7),
  upper        = list(continuous = wrap("cor", size = 3)),
  lower        = list(continuous = wrap("points", size = 0.8)),
  diag         = list(continuous = wrap("densityDiag", alpha = 0.5)),
  title        = "EDA - Iris: dispersão pareada por espécie"
)


for (i in 1:p_eda$nrow) {
  for (j in 1:p_eda$ncol) {
    p_eda[i, j] <- p_eda[i, j] +
      scale_color_manual(values = pal) +
      scale_fill_manual(values = pal)
  }
}

p_eda <- p_eda + theme_minimal(base_size = 10)

ggsave("figs/01_eda_pairs.png", p_eda, width = 9, height = 8, dpi = 150)

#K-MEANS, escolha do k (ELBOW + SILHOUETTE) e ajuste final (K=3)

p_elbow <- fviz_nbclust(X_scaled, kmeans, method = "wss",
                        k.max = 10, nstart = 25) +
  geom_vline(xintercept = 3, linetype = 2, color = "#C0392B") +
  labs(title = "Método do Cotovelo (WSS)",
       subtitle = "Inflexão clara em K = 3")

p_sil <- fviz_nbclust(X_scaled, kmeans, method = "silhouette",
                      k.max = 10, nstart = 25) +
  labs(title = "Silhouette médio por K")

p_diag <- p_elbow + p_sil
ggsave("figs/02_kmeans_diagnostico.png", p_diag, width = 11, height = 4.5, dpi = 150)

#  Adotamos K = 3, seguindo o grafico de cotovelos.


km3 <- kmeans(X_scaled, centers = 3, nstart = 25)

p_km <- fviz_cluster(km3, data = X_scaled,
                     ellipse.type = "norm", geom = "point",
                     palette = pal, ggtheme = theme_minimal()) +
  labs(title = "K-Means (K = 3) — clusters no espaço das 2 primeiras PCs")
ggsave("figs/03_kmeans_clusters.png", p_km, width = 7, height = 5.5, dpi = 150)


print(table(Cluster = km3$cluster, Especie = iris$Species))


#hierarquico usando WARD.D2

d   <- dist(X_scaled, method = "euclidean")
hc  <- hclust(d, method = "ward.D2")
hc_clusters <- cutree(hc, k = 3)

# Dendrograma colorido por cluster com dendextend
dend <- as.dendrogram(hc)
dend <- color_branches(dend, k = 3, col = pal)
dend <- set(dend, "labels_cex", 0.25)

png("figs/04_dendrograma.png", width = 1100, height = 600, res = 120)
par(mar = c(3, 4, 3, 1))
plot(dend,
     main = "Dendrograma - Ward.D2 (corte em K = 3)",
     ylab = "Altura (dissimilaridade)")
rect.dendrogram(dend, k = 3, border = "grey40", lty = 2, lwd = 1)
dev.off()

print(table(Cluster = hc_clusters, Especie = iris$Species))


#GMM, fixando K=3 para poder comparar

#Deixa o BIC escolher número de componentes E forma da covariância
gmm_auto <- Mclust(X)                 
print(summary(gmm_auto))
#no Iris o BIC escolhe G = 2 (modelo VEV), porque versicolor e virginica se sobrepõem tanto que o critério "junta" as duas.

png("figs/05_gmm_bic.png", width = 900, height = 600, res = 120)
plot(gmm_auto, what = "BIC")
title(main = "GMM - BIC por modelo e número de componentes", line = 2.5)
dev.off()

#Fixa G = 3 para comparar de forma justa com os outros dois métodos
gmm3 <- Mclust(X, G = 3)


png("figs/06_gmm_classification.png", width = 900, height = 800, res = 120)
plot(gmm3, what = "classification")
dev.off()


print(table(Cluster = gmm3$classification, Especie = iris$Species))



#Comapracao usandoADJUSTED RAND INDEX (ARI) 

ari_kmeans <- adjustedRandIndex(km3$cluster,        true_labels)
ari_hc     <- adjustedRandIndex(hc_clusters,        true_labels)
ari_gmm    <- adjustedRandIndex(gmm3$classification, true_labels)

ari_df <- tibble(
  Metodo = factor(c("K-Means", "Hierárquico\n(Ward.D2)", "GMM\n(mclust, K=3)")),
  ARI    = c(ari_kmeans, ari_hc, ari_gmm)
)

#resultado final
print(ari_df %>% mutate(ARI = round(ARI, 3)))

p_ari <- ggplot(ari_df, aes(x = reorder(Metodo, ARI), y = ARI, fill = Metodo)) +
  geom_col(width = 0.62, show.legend = FALSE) +
  geom_text(aes(label = sprintf("%.3f", ARI)), vjust = -0.4, size = 4.2) +
  scale_fill_manual(values = pal) +
  scale_y_continuous(limits = c(0, 1), expand = expansion(mult = c(0, 0.08))) +
  labs(title = "Comparação dos métodos — Adjusted Rand Index",
       subtitle = "Validação externa contra as espécies reais do Iris",
       x = NULL, y = "ARI") +
  theme_minimal(base_size = 12)

ggsave("figs/07_ari_comparacao.png", p_ari, width = 7.5, height = 5, dpi = 150)

