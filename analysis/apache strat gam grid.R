library(mgcv)
library(ggplot2)
library(dplyr)

# Ensure correct data types
train_data$teachingstatus <- factor(train_data$teachingstatus, levels = c(0, 1))

# Apache groups and flat colors
apache_groups <- c("ACS", "CardiacArrest", "CVA", "GIBleed", "Sepsis")
flat_colors <- c(
  "ACS" = "#E74C3C",           # red
  "CardiacArrest" = "#3498DB", # blue
  "CVA" = "#2ECC71",           # green
  "GIBleed" = "#F1C40F",       # yellow
  "Sepsis" = "#9B59B6"         # purple
)
group_counts <- table(train_data$apache_strat)

# Collect prediction data
prediction_data <- data.frame()

for (group in apache_groups) {
  data_subset <- subset(train_data, apache_strat == group)
  data_subset <- droplevels(data_subset)
  data_subset$teachingstatus <- factor(data_subset$teachingstatus, levels = c(0, 1))
  
  mod <- gam(actualicumortality ~ s(lactate_max, k = 4, bs = "cr") +
               age_fixed + sex + unitType + hospitalAdmitSource +
               apache_iv + final_charlson_score +
               sofatotal_day1 + teachingstatus + region,
             family = binomial(link = "logit"),
             data = data_subset)
  
  lactate_seq <- seq(min(train_data$lactate_max, na.rm = TRUE),
                     max(train_data$lactate_max, na.rm = TRUE),
                     length.out = 100)
  
  newdata <- data.frame(lactate_max = lactate_seq)
  newdata$age_fixed <- mean(data_subset$age_fixed, na.rm = TRUE)
  newdata$apache_iv <- mean(data_subset$apache_iv, na.rm = TRUE)
  newdata$final_charlson_score <- mean(data_subset$final_charlson_score, na.rm = TRUE)
  newdata$sofatotal_day1 <- mean(data_subset$sofatotal_day1, na.rm = TRUE)
  
  get_most_common <- function(x) factor(names(which.max(table(x))), levels = levels(x))
  newdata$sex <- get_most_common(data_subset$sex)
  newdata$unitType <- get_most_common(data_subset$unitType)
  newdata$hospitalAdmitSource <- get_most_common(data_subset$hospitalAdmitSource)
  newdata$apache_strat <- factor(group, levels = apache_groups)
  newdata$teachingstatus <- get_most_common(data_subset$teachingstatus)
  newdata$region <- get_most_common(data_subset$region)
  
  pred <- predict(mod, newdata = newdata, se.fit = TRUE, type = "link")
  prob <- plogis(pred$fit)
  lower <- plogis(pred$fit - 1.96 * pred$se.fit)
  upper <- plogis(pred$fit + 1.96 * pred$se.fit)
  
  prediction_data <- rbind(prediction_data,
                           data.frame(
                             apache_strat = paste0(group, "\nN = ", group_counts[group]),
                             lactate_max = lactate_seq,
                             prob = prob * 100,
                             lower = lower * 100,
                             upper = upper * 100,
                             color = flat_colors[group]
                           )
  )
}

# Use one color per panel
color_map <- setNames(flat_colors, paste0(names(flat_colors), "\nN = ", group_counts[names(flat_colors)]))

# Final plot
ggplot(prediction_data, aes(x = lactate_max, y = prob)) +
  geom_ribbon(aes(ymin = lower, ymax = upper, fill = apache_strat), alpha = 0.2, color = NA) +
  geom_line(aes(color = apache_strat), size = 1.1) +
  scale_color_manual(values = color_map) +
  scale_fill_manual(values = color_map) +
  facet_wrap(~ apache_strat, ncol = 3) +
  labs(x = "Lactate max", y = "Mortality probability (%)") +
  theme_minimal(base_size = 13) +
  theme(
    strip.text = element_text(size = 12, face = "bold"),
    panel.grid.minor = element_blank(),
    legend.position = "none",
    plot.margin = margin(10, 10, 20, 10)  # extra bottom space for x axis
  )
