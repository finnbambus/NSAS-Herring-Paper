
#--------------------------------------------------------------------------------------
## Helper functions
#--------------------------------------------------------------------------------------

# Calculate Root Mean Squared Error (RMSE)
rmse <- function(sim, obs) {
  sqrt(mean((obs - sim)^2, na.rm = TRUE))
}

# Check if required columns exist in a data frame
check_data_columns <- function(data, required_cols) {
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    stop(paste("Missing columns in data:", paste(missing_cols, collapse = ", ")))
  }
}

#--------------------------------------------------------------------------------------
## Fit individual SRR models
#--------------------------------------------------------------------------------------

# Independence (linear) model: R ~ SSB
fit_independence_model <- function(data, recruit_col = "R", ssb_col = "SSB") {
  check_data_columns(data, c(recruit_col, ssb_col))

  model <- lm(as.formula(paste(recruit_col, "~", ssb_col)), data = data)

  list(model = model, fitted = fitted(model))
}

# Beverton-Holt stock-recruitment model, fitted on the log scale.
# Fitted values are returned on the response scale; because the likelihood is on the
# log scale, the AIC of this model is not comparable to raw-response models
# (log_response = TRUE flags this for compare_models).
fit_beverton_holt <- function(data, recruit_col = "R", ssb_col = "SSB") {
  check_data_columns(data, c(recruit_col, ssb_col))

  fitted_vals <- rep(NA, nrow(data))
  complete_rows <- complete.cases(data[c(recruit_col, ssb_col)])
  data_clean <- data[complete_rows, ]

  if (nrow(data_clean) < 5 ||
      any(data_clean[[recruit_col]] <= 0) || any(data_clean[[ssb_col]] <= 0)) {
    warning("Beverton-Holt model skipped: insufficient data or non-positive values")
    return(list(model = NULL, fitted = fitted_vals, r2 = NA, log_response = TRUE))
  }

  bh <- FSA::srFuns("BevertonHolt")
  log_formula <- as.formula(paste("log(", recruit_col, ") ~ log(bh(", ssb_col, ", a, b))"))

  # Starting values: FSA::srStarts, with manual values as fallback
  sv <- tryCatch(
    suppressWarnings(FSA::srStarts(as.formula(paste(recruit_col, "~", ssb_col)),
                                   data = data_clean, type = "BevertonHolt")),
    error = function(e) NULL)
  if (is.null(sv) || any(!is.finite(unlist(sv)))) {
    sv <- list(a = max(data_clean[[recruit_col]]) * 1.2,
               b = mean(data_clean[[ssb_col]]))
  }

  tryCatch({
    model <- nls(log_formula, data = data_clean, start = sv,
                 control = nls.control(maxiter = 200, minFactor = 1/8192, tol = 1e-5))

    fitted_clean <- bh(data_clean[[ssb_col]], a = coef(model)["a"], b = coef(model)["b"])
    fitted_vals[complete_rows] <- fitted_clean
    r2 <- cor(fitted_clean, data_clean[[recruit_col]], use = "complete.obs")^2

    list(model = model, fitted = fitted_vals, r2 = r2, log_response = TRUE)
  }, error = function(e) {
    warning(paste("Beverton-Holt model failed:", e$message))
    list(model = NULL, fitted = fitted_vals, r2 = NA, log_response = TRUE)
  })
}

# Ricker stock-recruitment model, fitted on the log scale (see note on fit_beverton_holt)
fit_ricker <- function(data, recruit_col = "R", ssb_col = "SSB") {
  check_data_columns(data, c(recruit_col, ssb_col))

  fitted_vals <- rep(NA, nrow(data))

  tryCatch({
    suppressWarnings(suppressMessages({
      sv <- FSA::srStarts(as.formula(paste(recruit_col, "~", ssb_col)),
                          data = data, type = "Ricker")
      rckr <- FSA::srFuns("Ricker")

      log_formula <- as.formula(paste("log(", recruit_col, ") ~ log(rckr(", ssb_col, ", a, b))"))
      model <- nls(log_formula, data = data, start = sv)

      fitted_vals <- rckr(data[[ssb_col]], a = coef(model))
    }))

    list(model = model, fitted = fitted_vals, log_response = TRUE)
  }, error = function(e) {
    warning(paste("Ricker model failed:", e$message))
    list(model = NULL, fitted = fitted_vals, log_response = TRUE)
  })
}

# Segmented regression models: linear, log-transformed, and Negative Binomial GLM
# (with Quasipoisson fallback). Fitted values are always on the response scale;
# the log model is flagged with log_response = TRUE.
fit_segmented_models <- function(data, recruit_col = "R", ssb_col = "SSB") {
  check_data_columns(data, c(recruit_col, ssb_col))

  mean_ssb <- mean(data[[ssb_col]], na.rm = TRUE)

  data_log <- data
  data_log$R_log <- log(data_log[[recruit_col]])
  data_log$sbb_log <- log(data_log[[ssb_col]])
  mean_sbb_log <- mean(data_log$sbb_log, na.rm = TRUE)

  formula_obj <- as.formula(paste(recruit_col, "~", ssb_col))
  seg_formula <- as.formula(paste("~", ssb_col))

  empty_result <- list(model = NULL, fitted = NULL, breakpoint = NULL, breakpoint_se = NULL)
  results <- list(regular = empty_result, log = empty_result, negbinom = empty_result)

  # Regular segmented (lm)
  tryCatch({
    seg_regular <- segmented::segmented(lm(formula_obj, data = data),
                                        seg.Z = seg_formula, psi = mean_ssb)
    results$regular <- list(
      model = seg_regular,
      fitted = fitted(seg_regular),
      breakpoint = seg_regular$psi[2],
      breakpoint_se = seg_regular$psi[3])
  }, error = function(e) {
    warning(paste("Regular segmented model failed:", e$message))
  })

  # Log-transformed segmented (lm on log scale, fitted values back-transformed)
  tryCatch({
    seg_log <- segmented::segmented(lm(R_log ~ sbb_log, data = data_log),
                                    seg.Z = ~sbb_log, psi = mean_sbb_log)
    results$log <- list(
      model = seg_log,
      fitted = exp(fitted(seg_log)),
      breakpoint = seg_log$psi[2],
      breakpoint_se = seg_log$psi[3],
      log_response = TRUE)
  }, error = function(e) {
    warning(paste("Log segmented model failed:", e$message))
  })

  # Segmented with Negative Binomial GLM: estimate theta with glm.nb, then refit as a
  # plain glm with fixed theta so segmented() can handle the object. Falls back to a
  # Quasipoisson GLM if the Negative Binomial fit fails.
  seg_negbi <- tryCatch({
    theta <- MASS::glm.nb(formula_obj, data = data, link = log)$theta
    base_glm <- glm(formula_obj, data = data,
                    family = MASS::negative.binomial(theta = theta))
    seg <- segmented::segmented(obj = base_glm, seg.Z = seg_formula, psi = mean_ssb)
    list(seg = seg, note = "Base model: Negative Binomial GLM")
  }, error = function(e) {
    warning(paste("Negative Binomial segmented model failed, attempting Quasipoisson fallback:", e$message))
    tryCatch({
      base_glm <- glm(formula_obj, data = data, family = quasipoisson)
      seg <- segmented::segmented(base_glm, seg.Z = seg_formula, psi = mean_ssb)
      list(seg = seg, note = "Base model: Quasipoisson GLM (Negative Binomial fallback)")
    }, error = function(e2) {
      warning(paste("Quasipoisson segmented fallback also failed:", e2$message))
      NULL
    })
  })

  if (!is.null(seg_negbi)) {
    results$negbinom <- list(
      model = seg_negbi$seg,
      fitted = fitted(seg_negbi$seg),
      breakpoint = seg_negbi$seg$psi[2],
      breakpoint_se = seg_negbi$seg$psi[3],
      note = seg_negbi$note)
  }

  return(results)
}

# Structural change model: strucchange::breakpoints with the number of breaks
# chosen by the same BIC rule as srr_breakpoint_analysis (opt_bpts from
# R/functions.R: first interior local minimum of the BIC curve), so the
# comparison table describes the same model whose breakpoints are reported.
fit_strucchange <- function(data, recruit_col = "R", ssb_col = "SSB") {
  check_data_columns(data, c(recruit_col, ssb_col))
  if (!exists("opt_bpts")) {
    stop("fit_strucchange requires opt_bpts() - source R/functions.R first")
  }

  formula_obj <- as.formula(paste(recruit_col, "~", ssb_col))

  linear_fallback <- function(bpts_obj, method) {
    model <- lm(formula_obj, data = data)
    list(model = model, breakpoints = NULL, bpts_obj = bpts_obj,
         fitted = fitted(model), optimal_breaks = 0, method = method)
  }

  tryCatch({
    bpts_full <- strucchange::breakpoints(formula_obj, data = data)

    n_opt <- opt_bpts(summary(bpts_full)$RSS["BIC", ])[1]
    if (is.na(n_opt) || n_opt < 1) {
      cat("No breakpoints selected by BIC. Fitting simple linear model.\n")
      return(linear_fallback(bpts_full, "linear_fallback"))
    }

    bpts_opt <- strucchange::breakpoints(bpts_full, breaks = n_opt)
    bp_idx <- bpts_opt$breakpoints

    if (is.null(bp_idx) || all(is.na(bp_idx))) {
      cat("No valid breakpoints for", n_opt, "breaks. Fitting simple linear model.\n")
      return(linear_fallback(bpts_full, "linear_fallback"))
    }

    bp_idx <- bp_idx[!is.na(bp_idx)]
    n_breaks <- length(bp_idx)
    cat("BIC (local minimum rule) selected", n_breaks, "breakpoints\n")

    bp_factor <- strucchange::breakfactor(bpts_opt, breaks = n_breaks)
    temp_data <- data
    temp_data$bp_factor <- bp_factor

    model <- lm(as.formula(paste(recruit_col, "~ bp_factor *", ssb_col)), data = temp_data)

    list(model = model,
         breakpoints = data[[ssb_col]][bp_idx],
         bpts_obj = bpts_full,
         fitted = fitted(model),
         optimal_breaks = n_breaks,
         method = "BIC")
  }, error = function(e) {
    warning(paste("Structural change model failed:", e$message))
    linear_fallback(NULL, "error_fallback")
  })
}

# Negative Binomial GLM (diagnostic baseline) with its overdispersion parameter
fit_glm_negbinom <- function(data, recruit_col = "R", ssb_col = "SSB") {
  check_data_columns(data, c(recruit_col, ssb_col))

  tryCatch({
    model <- MASS::glm.nb(as.formula(paste(recruit_col, "~", ssb_col)), data = data)
    list(model = model, fitted = fitted(model),
         overdispersion = deviance(model) / df.residual(model))
  }, error = function(e) {
    warning(paste("Negative Binomial GLM failed:", e$message))
    list(model = NULL, fitted = NULL, overdispersion = NA)
  })
}

#--------------------------------------------------------------------------------------
## Model comparison
#--------------------------------------------------------------------------------------

# Compare fitted models using AIC, RMSE, and R-squared.
# RMSE and R-squared are always computed on the response scale.
# AIC is reported as NA for models fitted on a log-transformed response
# (log_response = TRUE), because their likelihoods are not comparable to
# raw-response models.
compare_models <- function(models_list, observed_data) {
  model_names <- names(models_list)
  n_models <- length(models_list)

  comparison <- data.frame(
    Model = model_names,
    AIC = rep(NA_real_, n_models),
    RMSE = rep(NA_real_, n_models),
    R_squared = rep(NA_real_, n_models),
    stringsAsFactors = FALSE
  )

  for (i in seq_along(models_list)) {
    model_info <- models_list[[i]]

    if (is.null(model_info) || is.null(model_info$model) || is.null(model_info$fitted)) {
      next
    }

    tryCatch({
      log_response <- isTRUE(model_info$log_response)

      # AIC only for models with the same (raw) response
      if (!log_response) {
        comparison$AIC[i] <- AIC(model_info$model)
      }

      comparison$RMSE[i] <- rmse(model_info$fitted, observed_data)

      # R-squared
      if (log_response || inherits(model_info$model, "nls")) {
        # Response-scale squared correlation (use stored value if available)
        comparison$R_squared[i] <- if (!is.null(model_info$r2)) {
          model_info$r2
        } else {
          cor(model_info$fitted, observed_data, use = "pairwise.complete.obs")^2
        }
      } else if (inherits(model_info$model, "segmented") && inherits(model_info$model$obj, "lm") &&
                 !inherits(model_info$model$obj, "glm")) {
        comparison$R_squared[i] <- summary(model_info$model$obj)$r.squared
      } else if (inherits(model_info$model, "lm") && !inherits(model_info$model, "glm")) {
        comparison$R_squared[i] <- summary(model_info$model)$r.squared
      }
      # GLM-based models report no R-squared (stays NA)

    }, error = function(e) {
      warning(paste("Error during comparison for model", model_names[i], ":", e$message))
    })
  }

  return(comparison)
}

#--------------------------------------------------------------------------------------
## Main analysis workflow
#--------------------------------------------------------------------------------------

# Run a comprehensive Stock-Recruitment Relationship (SRR) analysis:
# fits all candidate models on the same cropped dataset and compares them.
run_srr_analysis <- function(data_for_srr,
                             recruit_col = "R",
                             ssb_col = "SSB") {

  cat("Starting SRR analysis...\n")

  required_vars <- c(recruit_col, ssb_col)
  check_data_columns(data_for_srr, required_vars)

  # Crop to the contiguous block spanning all complete cases
  complete_indices <- which(complete.cases(data_for_srr[, required_vars]))
  if (length(complete_indices) == 0) {
    stop(paste("No complete cases found for the required variables",
               paste(required_vars, collapse = ", "), ". The function cannot proceed."))
  }

  start_index <- min(complete_indices)
  end_index <- max(complete_indices)
  original_nrow <- nrow(data_for_srr)
  data_cleaned <- data_for_srr[start_index:end_index, ]
  data_cleaned[[recruit_col]] <- as.numeric(data_cleaned[[recruit_col]])
  data_cleaned[[ssb_col]] <- as.numeric(data_cleaned[[ssb_col]])

  cat("--- Data Cropping ---\n")
  cat("Original dataset had", original_nrow, "rows.\n")
  cat("Data cropped to rows", start_index, "through", end_index,
      "based on non-NA values in '", recruit_col, "' and '", ssb_col, "'.\n")
  cat("New dataset has", nrow(data_cleaned), "observations for analysis.\n")
  cat("---------------------\n\n")

  if (nrow(data_cleaned) < 10) {
    stop("Insufficient data after cleaning (less than 10 rows). Cannot perform SRR analysis.")
  }

  models <- list()

  cat("Fitting independence model...\n")
  models$independence <- fit_independence_model(data_cleaned, recruit_col, ssb_col)

  cat("Fitting Beverton-Holt model...\n")
  models$beverton_holt <- fit_beverton_holt(data_cleaned, recruit_col, ssb_col)

  cat("Fitting Ricker model...\n")
  models$ricker <- fit_ricker(data_cleaned, recruit_col, ssb_col)

  cat("Fitting segmented models (linear, log, negative binomial)...\n")
  segmented_results <- fit_segmented_models(data_cleaned, recruit_col, ssb_col)
  models$segmented_regular <- segmented_results$regular
  models$segmented_log <- segmented_results$log
  models$segmented_negbinom <- segmented_results$negbinom

  cat("Fitting structural change model with BIC breakpoint selection...\n")
  models$strucchange <- fit_strucchange(data_cleaned, recruit_col, ssb_col)

  cat("Fitting Negative Binomial GLM (diagnostic baseline)...\n")
  models$glm_negbinom <- fit_glm_negbinom(data_cleaned, recruit_col, ssb_col)

  cat("Comparing all fitted models...\n")
  comparison_table <- compare_models(models, data_cleaned[[recruit_col]])

  cat("Analysis complete!\n")

  return(list(
    all_fitted_models = models,
    comparison_table = comparison_table
  ))
}

#--------------------------------------------------------------------------------------
## LOOCV
#--------------------------------------------------------------------------------------

# Leave-one-out cross-validation for all SRR candidate models.
# Expects columns: Year, R, SSB, R_log, SSB_log.
# Returns mean test and train RMSE per model (test RMSE per fold is the
# absolute prediction error of the single held-out observation).
cross_valid <- function(dataset) {

  cat("Starting cross-validation with", nrow(dataset), "observations...\n")

  model_cols <- c("linear.model", "beverton", "ricker", "segmented",
                  "segmented.log", "segmented.best.glm", "strucchange")

  empty_results <- as.data.frame(matrix(NA_real_, nrow = nrow(dataset), length(model_cols),
                                        dimnames = list(NULL, model_cols)))
  rmse_values <- cbind(run = 1:nrow(dataset), empty_results)
  rmse_values_train <- cbind(run = 1:nrow(dataset), empty_results)

  safe_rmse <- function(sim, obs) {
    if (any(is.na(sim)) || any(is.na(obs)) || length(sim) != length(obs)) {
      return(NA)
    }
    sqrt(mean((sim - obs)^2, na.rm = TRUE))
  }

  for (i in 1:nrow(dataset)) {

    train_data <- dataset[-i, ]
    test_data <- dataset[i, ]

    if (nrow(train_data) < 10) {
      cat("Warning: Insufficient training data for fold", i, ". Skipping to next fold.\n")
      next
    }

    positive_data <- !any(train_data$R <= 0, na.rm = TRUE) &&
      !any(train_data$SSB <= 0, na.rm = TRUE)

    # 1. Linear model
    tryCatch({
      m1 <- lm(R ~ SSB, data = train_data, na.action = na.exclude)
      rmse_values$linear.model[i] <- safe_rmse(predict(m1, newdata = test_data), test_data$R)
      rmse_values_train$linear.model[i] <- safe_rmse(predict(m1, newdata = train_data), train_data$R)
    }, error = function(e) {
      cat("Linear model failed for fold", i, ":", e$message, "\n")
    })

    # 2. Beverton-Holt
    tryCatch({
      if (!positive_data) {
        cat("Warning: Non-positive values detected for Beverton-Holt model in fold", i, ". Skipping.\n")
      } else {
        svR <- tryCatch(srStarts(R ~ SSB, data = train_data, type = "BevertonHolt"),
                        error = function(e) NULL)
        if (!is.null(svR)) {
          bh <- srFuns("BevertonHolt")
          srR_beverton <- nls(log(R) ~ log(bh(SSB, a, b)), data = train_data, start = svR,
                              control = nls.control(maxiter = 50, minFactor = 1/2048),
                              na.action = na.exclude)
          rmse_values$beverton[i] <- safe_rmse(bh(test_data$SSB, a = coef(srR_beverton)), test_data$R)
          rmse_values_train$beverton[i] <- safe_rmse(bh(train_data$SSB, a = coef(srR_beverton)), train_data$R)
        }
      }
    }, error = function(e) {
      cat("Beverton-Holt model failed for fold", i, ":", e$message, "\n")
    })

    # 3. Ricker
    tryCatch({
      if (!positive_data) {
        cat("Warning: Non-positive values detected for Ricker model in fold", i, ". Skipping.\n")
      } else {
        svR <- tryCatch(srStarts(R ~ SSB, data = train_data, type = "Ricker"),
                        error = function(e) NULL)
        if (!is.null(svR)) {
          rckr <- srFuns("Ricker")
          srR_ricker <- nls(log(R) ~ log(rckr(SSB, a, b)), data = train_data, start = svR,
                            control = nls.control(maxiter = 50, minFactor = 1/2048),
                            na.action = na.exclude)
          rmse_values$ricker[i] <- safe_rmse(rckr(test_data$SSB, a = coef(srR_ricker)), test_data$R)
          rmse_values_train$ricker[i] <- safe_rmse(rckr(train_data$SSB, a = coef(srR_ricker)), train_data$R)
        }
      }
    }, error = function(e) {
      cat("Ricker model failed for fold", i, ":", e$message, "\n")
    })

    # 4. Segmented regression
    tryCatch({
      base_lm <- lm(R ~ SSB, data = train_data, na.action = na.exclude)
      seg <- segmented::segmented(base_lm, seg.Z = ~SSB,
                                  psi = mean(train_data$SSB, na.rm = TRUE))
      rmse_values$segmented[i] <- safe_rmse(predict(seg, newdata = test_data), test_data$R)
      rmse_values_train$segmented[i] <- safe_rmse(predict(seg, newdata = train_data), train_data$R)
    }, error = function(e) {
      cat("Segmented model failed for fold", i, ":", e$message, "\n")
    })

    # 5. Segmented log (predictions back-transformed to the response scale)
    tryCatch({
      if (all(is.finite(train_data$R_log)) && all(is.finite(train_data$SSB_log))) {
        base_lm_log <- lm(R_log ~ SSB_log, data = train_data, na.action = na.exclude)
        seg_log <- segmented::segmented(base_lm_log, seg.Z = ~SSB_log,
                                        psi = mean(train_data$SSB_log, na.rm = TRUE))
        rmse_values$segmented.log[i] <- safe_rmse(exp(predict(seg_log, newdata = test_data)), test_data$R)
        rmse_values_train$segmented.log[i] <- safe_rmse(exp(predict(seg_log, newdata = train_data)), train_data$R)
      } else {
        cat("Warning: Non-finite log values for segmented log model in fold", i, ". Skipping.\n")
      }
    }, error = function(e) {
      cat("Segmented log model failed for fold", i, ":", e$message, "\n")
    })

    # 6. Segmented GLM (Negative Binomial with Quasipoisson fallback)
    mean_ssb <- mean(train_data$SSB, na.rm = TRUE)
    tryCatch({
      theta <- MASS::glm.nb(R ~ SSB, data = train_data, na.action = na.omit)$theta
      base_negbi <- glm(R ~ SSB, data = train_data,
                        family = MASS::negative.binomial(theta = theta), na.action = na.omit)
      seg_negbi <- segmented::segmented(obj = base_negbi, seg.Z = ~SSB, psi = mean_ssb,
                                        control = seg.control(maxit = 200, tol = 1e-5))
      rmse_values$segmented.best.glm[i] <- safe_rmse(predict(seg_negbi, newdata = test_data, type = "response"), test_data$R)
      rmse_values_train$segmented.best.glm[i] <- safe_rmse(predict(seg_negbi, newdata = train_data, type = "response"), train_data$R)
    }, error = function(e) {
      warning(paste("Negative Binomial segmented model failed for fold", i,
                    ", attempting Quasipoisson fallback:", e$message))
      tryCatch({
        base_qpois <- glm(R ~ SSB, data = train_data, family = quasipoisson, na.action = na.omit)
        seg_qpois <- segmented::segmented(base_qpois, seg.Z = ~SSB, psi = mean_ssb,
                                          control = seg.control(maxit = 200, tol = 1e-5))
        rmse_values$segmented.best.glm[i] <<- safe_rmse(predict(seg_qpois, newdata = test_data, type = "response"), test_data$R)
        rmse_values_train$segmented.best.glm[i] <<- safe_rmse(predict(seg_qpois, newdata = train_data, type = "response"), train_data$R)
      }, error = function(e2) {
        warning(paste("Quasipoisson segmented fallback also failed for fold", i, ":", e2$message))
      })
    })

    # 7. Structural change detection
    tryCatch({
      bpts <- strucchange::breakpoints(R ~ SSB, data = train_data, h = 0.15)

      if (!is.null(bpts$RSS.table) && nrow(bpts$RSS.table) > 0) {

        # Number of breaks by BIC, capped at 2 for the small fold sizes
        bic_bpts <- tryCatch(strucchange::breakpoints(bpts), error = function(e) NULL)
        if (!is.null(bic_bpts) && !is.null(bic_bpts$breakpoints) &&
            !any(is.na(bic_bpts$breakpoints))) {
          opt_breaks <- length(bic_bpts$breakpoints)
        } else {
          opt_breaks <- 0
        }
        if (opt_breaks > 2) opt_breaks <- 2

        if (opt_breaks > 0) {
          if (!is.null(bic_bpts) && length(bic_bpts$breakpoints) == opt_breaks) {
            bp_final <- bic_bpts
          } else {
            bp_final <- strucchange::breakpoints(bpts, breaks = opt_breaks)
          }

          if (!is.null(bp_final$breakpoints) && !any(is.na(bp_final$breakpoints))) {
            train_bp_factor <- strucchange::breakfactor(bp_final, breaks = opt_breaks)

            if (length(levels(train_bp_factor)) > 1) {
              strucc_model <- lm(R ~ train_bp_factor * SSB, data = train_data)
              rmse_values_train$strucchange[i] <- safe_rmse(fitted(strucc_model), train_data$R)

              # Classify the held-out observation into a segment by its SSB value
              bp_values <- train_data$SSB[bp_final$breakpoints]
              test_segment <- cut(test_data$SSB,
                                  breaks = c(-Inf, bp_values, Inf),
                                  labels = levels(train_bp_factor),
                                  include.lowest = TRUE)

              test_data_expanded <- test_data
              test_data_expanded$train_bp_factor <- test_segment

              rmse_values$strucchange[i] <- safe_rmse(predict(strucc_model, newdata = test_data_expanded), test_data$R)
            }
          }
        }
      }
    }, error = function(e) {
      cat("Structural change model failed for fold", i, ":", e$message, "\n")
    })

    if (i %% 10 == 0) {
      cat("Completed", i, "folds...\n")
    }
  }

  col_means <- function(df) {
    as.data.frame(t(colMeans(df[model_cols], na.rm = TRUE)))
  }

  # Number of folds that produced a test prediction per model: means based on few
  # folds (failed fits, unassignable test observations) are not comparable to
  # models evaluated on all folds
  n_test_folds <- sapply(rmse_values[model_cols], function(x) sum(!is.na(x)))

  cat("Cross-validation completed!\n")
  cat("Contributing test folds per model (of", nrow(dataset), "):\n")
  print(n_test_folds)

  return(list(
    test = col_means(rmse_values),
    train = col_means(rmse_values_train),
    n_test_folds = n_test_folds,
    detailed_test = rmse_values,
    detailed_train = rmse_values_train
  ))
}