library(ggplot2)
library(reshape2)
library(patchwork)
library(dplyr)
library(tidyr)
library(lubridate)
raw_data <- read.csv("data/uh9iavowosgqqkib.csv", stringsAsFactors = FALSE)

clean <- raw_data %>%
  mutate(
    Date = ymd(DlyCalDt),
    Return = as.numeric(DlyRet)
  )
n <- nrow(clean)

wide_matrix <- clean %>%
  dplyr::select(Date, Ticker, Return) %>%
  pivot_wider(names_from = Ticker, values_from = Return) %>%
  arrange(Date)
wide_matrix <- na.omit(wide_matrix)
data <- wide_matrix[, -1]

break_index <- 551
data_pre <- data[1:break_index, ]
data_post <- data[break_index:nrow(wide_matrix), ]
var_pre <- vars::VAR(data_pre, p = 1, type = "const")
var_post <- vars::VAR(data_post, p = 1, type = "const")
Sigma_pre <- crossprod(residuals(var_pre)) / nrow(data[1:break_index, ])
Sigma_post <- crossprod(residuals(var_post)) / nrow(data[(break_index + 1):nrow(data), ])
cor_pre <- cov2cor(Sigma_pre)
cor_post <- cov2cor(Sigma_post)
global_min <- min(c(as.vector(cor_pre), as.vector(cor_post)))
global_max <- 1

colnames(cor_pre) <- rownames(cor_pre) <- colnames(data)
melted_pre <- melt(cor_pre)

p1 <- ggplot(melted_pre, aes(Var2, Var1, fill = value)) +
  geom_tile(colour = "white") +
  scale_fill_gradient(
    low = "white",
    high = "black",
    limits = c(global_min, global_max),
    name = "Correlation"
  ) +
  labs() +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    legend.position = "right"
  )

colnames(cor_post) <- rownames(cor_post) <- colnames(Y)
melted_post <- melt(cor_post)

p2 <- ggplot(melted_post, aes(Var2, Var1, fill = value)) +
  geom_tile(colour = "white") +
  scale_fill_gradient(
    low = "white",
    high = "black",
    limits = c(global_min, global_max),
    name = "Correlation"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    legend.position = "none"
  )

p1 + p2 +
  plot_layout(guides = "collect") &
  theme(legend.position = "right")
