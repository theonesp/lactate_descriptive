library(mgcv)

train_data$teachingstatus <- factor(train_data$teachingstatus, levels = c(0, 1))

apache_groups <- c("ACS", "CardiacArrest", "CVA", "GIBleed", "Sepsis")
flat_colors <- c(
  "ACS" = "#E74C3C",           # red
  "CardiacArrest" = "#3498DB", # blue
  "CVA" = "#2ECC71",           # green
  "GIBleed" = "#F1C40F",       # yellow
  "Sepsis" = "#9B59B6"         # purple
)

group_counts <- table(train_data$apache_strat)
legend_labels <- paste0(names(flat_colors), " (N = ", group_counts[names(flat_colors)], ")")

lactate_seq <- seq(min(train_data$lactate_max, na.rm = TRUE),
                   max(train_data$lactate_max, na.rm = TRUE),
                   length.out = 100)

plot(NULL, xlim = range(lactate_seq), ylim = c(0, 100),
     xlab = "Lactate max",
     ylab = "Estimated mortality probability (%)",
     main = "Smoothed effect of lactate_max by apache_strat")

for (group in apache_groups) {
  data_subset <- subset(train_data, apache_strat == group)
  
  data_subset$sex <- droplevels(data_subset$sex)
  data_subset$unitType <- droplevels(data_subset$unitType)
  data_subset$hospitalAdmitSource <- droplevels(data_subset$hospitalAdmitSource)
  data_subset$apache_strat <- droplevels(data_subset$apache_strat)
  data_subset$region <- droplevels(data_subset$region)
  data_subset$teachingstatus <- factor(data_subset$teachingstatus, levels = c(0, 1))
  
  mod <- gam(actualicumortality ~ s(lactate_max, k = 4, bs = "cr") +
               age_fixed + sex + unitType + hospitalAdmitSource +
               apache_iv + final_charlson_score +
               sofatotal_day1 + teachingstatus + region,
             family = binomial(link = "logit"),
             data = data_subset)
  
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
  
  polygon(c(lactate_seq, rev(lactate_seq)),
          c(upper, rev(lower)) * 100,
          col = adjustcolor(flat_colors[group], alpha.f = 0.15),
          border = NA)
  
  lines(lactate_seq, prob * 100, lwd = 2, col = flat_colors[group])
}

legend("topleft", legend = legend_labels, col = flat_colors, lwd = 2, bty = "n")
