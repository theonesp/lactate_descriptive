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

# Define a common x-axis range based on where we actually have data
# Use 95th percentile across all groups to set a reasonable upper limit
common_max_lactate <- quantile(train_data$lactate_max, 0.95, na.rm = TRUE)
common_min_lactate <- min(train_data$lactate_max, na.rm = TRUE)

print(paste("Using lactate range:", round(common_min_lactate, 2), "to", round(common_max_lactate, 2), "mmol/L"))

# Function to check if group has sufficient data in a lactate range
has_sufficient_data <- function(data, lactate_value, min_count = 5) {
  # Check if there are at least min_count observations within 1 mmol/L of this value
  nearby_data <- sum(abs(data$lactate_max - lactate_value) <= 1, na.rm = TRUE)
  return(nearby_data >= min_count)
}

# Collect prediction data
prediction_data <- data.frame()

for (group in apache_groups) {
  data_subset <- subset(train_data, apache_strat == group)
  data_subset <- droplevels(data_subset)
  data_subset$teachingstatus <- factor(data_subset$teachingstatus, levels = c(0, 1))
  
  # Find the effective range for this group (where we have sufficient data)
  group_max_lactate <- min(common_max_lactate, 
                           quantile(data_subset$lactate_max, 0.95, na.rm = TRUE))
  
  mod <- gam(actualicumortality ~ s(lactate_max, k = 4, bs = "cr") +
               age_fixed + sex + unitType + hospitalAdmitSource +
               apache_iv + final_charlson_score +
               sofatotal_day1 + teachingstatus + region,
             family = binomial(link = "logit"),
             data = data_subset)
  
  # Use common range for all groups, but only predict where we have data
  lactate_seq <- seq(common_min_lactate, common_max_lactate, length.out = 100)
  
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
  
  # Determine which predictions to show (only where we have sufficient data)
  show_prediction <- sapply(lactate_seq, function(x) has_sufficient_data(data_subset, x))
  
  # Set predictions to NA where we don't have sufficient data
  prob[!show_prediction] <- NA
  lower[!show_prediction] <- NA
  upper[!show_prediction] <- NA
  
  prediction_data <- rbind(prediction_data,
                           data.frame(
                             apache_strat = paste0(group, "\nN = ", group_counts[group]),
                             lactate_max = lactate_seq,
                             prob = prob * 100,
                             lower = lower * 100,
                             upper = upper * 100,
                             color = flat_colors[group],
                             has_data = show_prediction
                           )
  )
}

# Use one color per panel
color_map <- setNames(flat_colors, paste0(names(flat_colors), "\nN = ", group_counts[names(flat_colors)]))

# Final plot with consistent x-axis and data-driven visibility
ggplot(prediction_data, aes(x = lactate_max, y = prob)) +
  geom_ribbon(aes(ymin = lower, ymax = upper, fill = apache_strat), 
              alpha = 0.2, color = NA, na.rm = TRUE) +
  geom_line(aes(color = apache_strat), size = 1.1, na.rm = TRUE) +
  scale_color_manual(values = color_map) +
  scale_fill_manual(values = color_map) +
  scale_x_continuous(limits = c(common_min_lactate, common_max_lactate)) +
  facet_wrap(~ apache_strat, ncol = 3) +
  labs(x = "Lactate max (mmol/L)", 
       y = "Mortality probability (%)",
       title = paste("Mortality vs Lactate (showing only data-supported ranges)")) +
  theme_minimal(base_size = 13) +
  theme(
    strip.text = element_text(size = 12, face = "bold"),
    panel.grid.minor = element_blank(),
    legend.position = "none",
    plot.margin = margin(10, 10, 20, 10)
  )

# Print summary of data availability by group
cat("\nData availability summary by group:\n")
data_summary <- train_data %>%
  group_by(apache_strat) %>%
  summarise(
    N = n(),
    Min_Lactate = round(min(lactate_max, na.rm = TRUE), 2),
    Max_Lactate = round(max(lactate_max, na.rm = TRUE), 2),
    P95_Lactate = round(quantile(lactate_max, 0.95, na.rm = TRUE), 2),
    N_above_10 = sum(lactate_max > 10, na.rm = TRUE),
    N_above_15 = sum(lactate_max > 15, na.rm = TRUE),
    .groups = 'drop'
  )

print(data_summary)

ggsave("./figures/lactate_mortality_gam.tiff", width = 12, height = 8, dpi = 300, compression = "lzw")
