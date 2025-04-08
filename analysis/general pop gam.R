library(mgcv)

# Ensure 'teachingstatus' is treated as a factor
train_data$teachingstatus <- factor(train_data$teachingstatus, levels = c(0, 1))

# Fit the GAM model
mod_spline <- gam(actualicumortality ~ s(lactate_max, k = 4, bs = "cr") +
                    age_fixed + sex + unitType + hospitalAdmitSource +
                    apache_iv + final_charlson_score + apache_strat +
                    sofatotal_day1 + teachingstatus + region,
                  family = binomial(link = "logit"),
                  data = train_data)

# Prepare newdata for prediction
newdata <- data.frame(
  lactate_max = seq(min(train_data$lactate_max, na.rm = TRUE),
                    max(train_data$lactate_max, na.rm = TRUE),
                    length.out = 100)
)

# Numeric covariates: use means
newdata$age_fixed <- mean(train_data$age_fixed, na.rm = TRUE)
newdata$apache_iv <- mean(train_data$apache_iv, na.rm = TRUE)
newdata$final_charlson_score <- mean(train_data$final_charlson_score, na.rm = TRUE)
newdata$sofatotal_day1 <- mean(train_data$sofatotal_day1, na.rm = TRUE)

# Categorical covariates: most frequent observed level
get_most_common <- function(x) factor(names(which.max(table(x))), levels = levels(x))

newdata$sex <- get_most_common(train_data$sex)
newdata$unitType <- get_most_common(train_data$unitType)
newdata$hospitalAdmitSource <- get_most_common(train_data$hospitalAdmitSource)
newdata$apache_strat <- get_most_common(train_data$apache_strat)
newdata$teachingstatus <- get_most_common(train_data$teachingstatus)
newdata$region <- get_most_common(train_data$region)

# Predict (logit scale), then convert to probability
pred <- predict(mod_spline, newdata = newdata, se.fit = TRUE, type = "link")
prob <- plogis(pred$fit)
lower <- plogis(pred$fit - 1.96 * pred$se.fit)
upper <- plogis(pred$fit + 1.96 * pred$se.fit)

# Plot: flat design with soft gray and blue
plot(newdata$lactate_max, prob * 100, type = "l", lwd = 2, col = "#007ACC",
     ylim = range(c(lower, upper) * 100),
     xlab = "Lactate max", ylab = "Estimated mortality probability (%)",
     main = "Smoothed effect of lactate_max on mortality")
polygon(c(newdata$lactate_max, rev(newdata$lactate_max)),
        c(upper, rev(lower)) * 100,
        col = adjustcolor("#B0BEC5", alpha.f = 0.4), border = NA)
lines(newdata$lactate_max, prob * 100, lwd = 2, col = "#007ACC")
