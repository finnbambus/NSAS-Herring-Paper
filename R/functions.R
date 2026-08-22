# Functions for "data_analysis.Rmd" and "data_analysis_component.Rmd"
#--------------------------------------------------------------------------------------
## Analyse SSB change-points
#--------------------------------------------------------------------------------------

changepoint_analysis <- function(data,
                                 ssb_col = "SSB_component",
                                 year_col = "year",
                                 region_name = "Region",
                                 Q = 6,
                                 bcp_threshold = 0.7,
                                 consensus_tolerance = 1,
                                 min_years_between = 5,
                                 plot_results = TRUE,
                                 seed = 42,
                                 bcp_mcmc = 5000) {
  
  # Print region being analyzed
  cat("=== Changepoint Analysis for", region_name, "===\n")
  
  # Validate inputs
  if (!ssb_col %in% names(data)) {
    stop("SSB column '", ssb_col, "' not found in data")}
  if (!year_col %in% names(data)) {
    stop("Year column '", year_col, "' not found in data")}
  
  # Remove rows with missing values
  analysis_data <- data[complete.cases(data[c(ssb_col, year_col)]), ]
  
  if(nrow(analysis_data) < nrow(data)) {
    cat("# Removed", nrow(data) - nrow(analysis_data), "rows with missing values\n")}
  
  cat("# Data range:", range(analysis_data[[year_col]])[1], "-", 
      range(analysis_data[[year_col]])[2], "\n")
  cat("# Analysis parameters: Q =", Q, ", BCP threshold =", bcp_threshold, "\n")
  
  # CPT Analysis (BinSeg method)
  cat("\n## CPT Analysis (BinSeg)\n")
  ssbcpts <- cpt.mean(data = analysis_data[[ssb_col]], method = "BinSeg", Q = Q)
  cpt_indices <- cpts(ssbcpts)
  cpt_years <- analysis_data[[year_col]][cpt_indices]
  
  cat("# CPT changepoint indices:", paste(cpt_indices, collapse = ", "), "\n")
  cat("# CPT changepoint years:", paste(cpt_years, collapse = ", "), "\n")
  
  if(plot_results) {
    plot(ssbcpts, type = "l", cpt.col = "navyblue", 
         xlab = "Index", lwd = 4,
         main = paste("CPT Analysis -", region_name))}
  
  # BCP Analysis
  # bcp() estimates posterior probabilities by MCMC: a fixed seed and a long chain
  # are required for reproducible changepoints (probabilities near the threshold
  # flip between runs otherwise)
  cat("\n## BCP Analysis\n")
  set.seed(seed)
  bcp.ssb <- bcp(analysis_data[[ssb_col]], mcmc = bcp_mcmc, burnin = ceiling(bcp_mcmc / 10))
  bcp_indices <- which(bcp.ssb$posterior.prob >= bcp_threshold)
  bcp_years <- analysis_data[[year_col]][bcp_indices]
  
  cat("# BCP changepoint indices:", paste(bcp_indices, collapse = ", "), "\n")
  cat("# BCP changepoint years:", paste(bcp_years, collapse = ", "), "\n")
  
  if(plot_results) {
    plot(bcp.ssb, main = paste("BCP Analysis -", region_name))}
  
  # Consensus Analysis
  cat("\n## Consensus Analysis\n")
  consensus_years <- c()
  
  # Find consensus points (within tolerance)
  for (cpt_year in cpt_years) {
    if (any(abs(bcp_years - cpt_year) <= consensus_tolerance)) {
      consensus_years <- c(consensus_years, cpt_year)}}
  
  # Apply minimum spacing rule
  if (length(consensus_years) > 1) {
    consensus_years <- sort(consensus_years)
    filtered_consensus <- consensus_years[1]
    
    for (i in 2:length(consensus_years)) {
      if (consensus_years[i] - tail(filtered_consensus, 1) >= min_years_between) {
        filtered_consensus <- c(filtered_consensus, consensus_years[i])}}
    consensus_years <- filtered_consensus}
  
  # Identify method-specific changepoints
  cpt_only_years <- setdiff(cpt_years, consensus_years)
  bcp_only_years <- setdiff(bcp_years, consensus_years)
  
  cat("# Consensus changepoints (±", consensus_tolerance, "yr, min", min_years_between, "yr apart):", 
      paste(consensus_years, collapse = ", "), "\n")
  
  if (length(cpt_only_years) > 0) {
    cat("# CPT only:", paste(cpt_only_years, collapse = ", "), "\n")
  }
  if (length(bcp_only_years) > 0) {
    cat("# BCP only:", paste(bcp_only_years, collapse = ", "), "\n")}
  
  # Create results structure
  results <- list(
    region = region_name,
    parameters = list(
      Q = Q,
      bcp_threshold = bcp_threshold,
      consensus_tolerance = consensus_tolerance,
      min_years_between = min_years_between),
    data_info = list(
      n_observations = nrow(analysis_data),
      year_range = range(analysis_data[[year_col]]),
      ssb_range = range(analysis_data[[ssb_col]], na.rm = TRUE)),
    cpt_analysis = list(
      model = ssbcpts,
      changepoint_indices = cpt_indices,
      changepoint_years = cpt_years,
      n_changepoints = length(cpt_years)),
    bcp_analysis = list(
      model = bcp.ssb,
      changepoint_indices = bcp_indices,
      changepoint_years = bcp_years,
      n_changepoints = length(bcp_years),
      threshold_used = bcp_threshold),
    consensus = list(
      changepoint_years = consensus_years,
      cpt_only_years = cpt_only_years,
      bcp_only_years = bcp_only_years,
      n_consensus = length(consensus_years),
      criteria = paste("Both methods ±", consensus_tolerance, "year, min", min_years_between, "years between points")))
  
  cat("\n")
  return(results)}

#--------------------------------------------------------------------------------------
## Plot SSB change-points
#--------------------------------------------------------------------------------------

plot_SSB_cpt <- function(data, changepoints, component, SSB_column, l_bnd_column, u_bnd_column,
                         ribbon_colors = NULL,
                         vline_colors = NULL,
                         ribbon_changepoints = NULL,
                         start_year = NULL,
                         end_year = NULL,
                         show_hlines = TRUE) {

  # Ribbon periods default to the same changepoints as the vertical lines;
  # ribbon_changepoints allows coloring the CI by a different segmentation
  # (e.g. the full-stock phases in the component plots)
  if (is.null(ribbon_changepoints)) {
    ribbon_changepoints <- changepoints}

  # Set default colors if not provided
  default_ribbon_colors <- c("#201124", "#3e478d", "#318ca5", "#5ccdaa", "#d2f1da")
  default_vline_colors <- c("black", "black", "black", "black", "black", "black", "black", "grey")

  if (is.null(ribbon_colors)) {
    ribbon_colors <- rep(default_ribbon_colors, length.out = length(ribbon_changepoints) + 1)}

  if (is.null(vline_colors)) {
    vline_colors <- rep(default_vline_colors, length.out = length(changepoints))}

  # Determine start and end years from data if not provided
  if (is.null(start_year)) {
    start_year <- min(data$year, na.rm = TRUE)}
  if (is.null(end_year)) {
    end_year <- max(data$year, na.rm = TRUE)}
  
  # Create the base plot
  p <- ggplot(data) +
    geom_line(aes(x = year, y = .data[[SSB_column]]/1000000), linewidth = 0.8) +
    labs(title = component,
         x = "Year",
         y = "SSB in million t") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5),
          axis.title.x = element_text(margin = margin(t = 10)),
          axis.title.y = element_text(margin = margin(r = 10)))

  # Add horizontal reference line if enabled
  if (show_hlines) {
    p <- p +
      geom_hline(yintercept = 1130747/1000000, col = "darkorange")} #MSY Btrigger
  
  # Add vertical lines for changepoints
  for (i in seq_along(changepoints)) {
    p <- p + geom_vline(xintercept = changepoints[i],
                        col = vline_colors[i],
                        linewidth = 0.4)}

  # Ribbon periods; ribbon changepoints outside the data range shift the
  # starting color instead of creating empty periods (a component starting in
  # 1972 begins in the full stock's second phase)
  rcp <- sort(ribbon_changepoints)
  first_period <- sum(rcp <= start_year) + 1
  bounds <- c(start_year, rcp[rcp > start_year & rcp < end_year], end_year)

  # Add ribbons for each period
  for (i in seq_len(length(bounds) - 1)) {
    year_range <- bounds[i]:bounds[i + 1]

    p <- p + geom_ribbon(data = filter(data, year %in% year_range),
                         mapping = aes(x = year,
                                       ymin = .data[[l_bnd_column]]/1000000,
                                       ymax = .data[[u_bnd_column]]/1000000),
                         fill = ribbon_colors[first_period + i - 1],
                         alpha = 0.5)}

  return(p)
}


#--------------------------------------------------------------------------------------
## Plot Grid CPT
#--------------------------------------------------------------------------------------

plot_F_cpt <- function(data, changepoints, ribbon_colors, vline_colors, component,
                       ribbon_changepoints = NULL,
                       show_hlines = FALSE,
                       fmsy = 0.32,
                       F_column = "F", l_bnd_column = "F_low", u_bnd_column = "F_high") {

  # Ribbon periods default to the changepoints; see plot_SSB_cpt
  if (is.null(ribbon_changepoints)) {
    ribbon_changepoints <- changepoints}

  # Determine start and end years from data
  start_year <- min(data$year, na.rm = TRUE)
  end_year <- max(data$year, na.rm = TRUE)

  # Create the base plot
  p <- ggplot(data, aes(x = year)) +
    geom_line(aes(y = .data[[F_column]]), linewidth = 0.8, color = "black") +
    xlim(1947, 2024) +  # Fixed x-axis range
    theme_minimal() +
    theme(axis.title = element_blank(),
          axis.text = element_text(size = 8))

  # Add F reference line if enabled
  if (show_hlines) {
    p <- p + geom_hline(yintercept = fmsy, col = "#56B4E9")} #FMSY (light blue)

  # Add changepoint lines
  if(length(changepoints) > 0) {
    p <- p + geom_vline(xintercept = changepoints,
                        color = vline_colors,
                        linetype = "dashed",
                        linewidth = 0.4)
  }

  # Ribbon periods; out-of-range ribbon changepoints shift the starting color
  rcp <- sort(ribbon_changepoints)
  first_period <- sum(rcp <= start_year) + 1
  bounds <- c(start_year, rcp[rcp > start_year & rcp < end_year], end_year)

  # Add colored ribbons for each period
  for (i in seq_len(length(bounds) - 1)) {
    year_range <- bounds[i]:bounds[i + 1]

    p <- p + geom_ribbon(data = filter(data, year %in% year_range),
                         mapping = aes(x = year,
                                       ymin = .data[[l_bnd_column]],
                                       ymax = .data[[u_bnd_column]]),
                         fill = ribbon_colors[first_period + i - 1],
                         alpha = 0.5)
  }

  return(p)
}

# Function to plot Recruitment with phase coloring
plot_Recruitment_cpt <- function(data, changepoints, ribbon_colors, vline_colors, component,
                                 ribbon_changepoints = NULL,
                                 R_column = "Recruitment", l_bnd_column = "Recruitment_low",
                                 u_bnd_column = "Recruitment_high") {

  # Ribbon periods default to the changepoints; see plot_SSB_cpt
  if (is.null(ribbon_changepoints)) {
    ribbon_changepoints <- changepoints}

  # Determine start and end years from data
  start_year <- min(data$year, na.rm = TRUE)
  end_year <- max(data$year, na.rm = TRUE)

  # Create the base plot
  p <- ggplot(data, aes(x = year)) +
    geom_line(aes(y = .data[[R_column]]/1000000), linewidth = 0.8, color = "black") +
    xlim(1947, 2024) +  # Fixed x-axis range
    theme_minimal() +
    theme(axis.title = element_blank(),
          axis.text = element_text(size = 8))

  # Add changepoint lines
  if(length(changepoints) > 0) {
    p <- p + geom_vline(xintercept = changepoints,
                        color = vline_colors,
                        linetype = "dashed",
                        linewidth = 0.4)
  }

  # Ribbon periods; out-of-range ribbon changepoints shift the starting color
  rcp <- sort(ribbon_changepoints)
  first_period <- sum(rcp <= start_year) + 1
  bounds <- c(start_year, rcp[rcp > start_year & rcp < end_year], end_year)

  # Add colored ribbons for each period
  for (i in seq_len(length(bounds) - 1)) {
    year_range <- bounds[i]:bounds[i + 1]

    p <- p + geom_ribbon(data = filter(data, year %in% year_range),
                         mapping = aes(x = year,
                                       ymin = .data[[l_bnd_column]]/1000000,
                                       ymax = .data[[u_bnd_column]]/1000000),
                         fill = ribbon_colors[first_period + i - 1],
                         alpha = 0.5)
  }

  return(p)
}


#--------------------------------------------------------------------------------------
## Extract optimal breakpoint
#--------------------------------------------------------------------------------------

opt_bpts <- function(x) {
  # x: named vector of BIC values, names = number of breaks (from summary(bpts)$RSS["BIC", ])
  # Returns the break counts at interior local minima of the BIC curve;
  # falls back to the global minimum if the curve has no interior local minimum.
  n <- length(x)
  lowest <- rep(FALSE, n)
  if (n >= 3) {
    for (i in 2:(n - 1)) {
      lowest[i] <- x[i] < x[i - 1] & x[i] < x[i + 1]}}
  out <- as.integer(names(x)[lowest])
  if (length(out) == 0) {
    out <- as.integer(names(x)[which.min(x)])}
  return(out)}


#--------------------------------------------------------------------------------------
## Breakpoint analysis
#--------------------------------------------------------------------------------------

breakpoint_analysis <- function(data, ssb_col, f_col, year_col, 
                                lag_years = 1, 
                                region_name = "Region", 
                                plot_breakpoints = TRUE) {
  
  # Print region being analyzed
  cat("=== Analysis for", region_name, "===\n")
  cat("# Using", lag_years, "year lag\n")

  # Lag SSB by lag_years (data must be ordered by year)
  data <- data[order(data[[year_col]]), ]
  data$SSB_lag <- dplyr::lag(data[[ssb_col]], lag_years)

  # Remove rows with missing values for analysis
  analysis_data <- data[complete.cases(data[c(ssb_col, f_col, "SSB_lag")]), ]
  
  if(nrow(analysis_data) < nrow(data)) {
    cat("# Removed", nrow(data) - nrow(analysis_data), "rows with missing values\n")}
  
  # Break-point analysis
  bpts <- strucchange::breakpoints(analysis_data$SSB_lag/1000000 ~ analysis_data[[f_col]])
  
  if(plot_breakpoints) {
    plot(bpts, main = paste("Breakpoints for", region_name))}
  
  # Get summary and find optimal breaks
  bpts_sum <- summary(bpts)
  opt_brks <- opt_bpts(bpts_sum$RSS["BIC",])
  
  cat("# Optimal number of breaks:", opt_brks[1], "\n")
  
  # Get breakpoints with optimal number of breaks
  bpts2 <- strucchange::breakpoints(bpts, breaks = opt_brks[1])
  best_brk <- analysis_data[[f_col]][bpts2$breakpoints]
  
  cat("# Best breakpoint F values:\n")
  cat("####", paste(round(best_brk, 3), collapse = " "), "\n")
  
  # Get breakpoint years
  best_brk_years <- analysis_data[[year_col]][bpts2$breakpoints]
  
  cat("# Best breakpoint years:\n") 
  cat("####", paste(best_brk_years, collapse = ", "), "\n")
  
  # Create confidence interval plot
  par(mfrow = c(1,1))
  ci_mod <- confint(bpts, breaks = opt_brks[1])
  
  plot(analysis_data$SSB_lag/1000000 ~ analysis_data[[f_col]], type = "p",
       xlab = "F", ylab = "SSB (millions)",
       main = paste("SSB vs F with Breakpoints -", region_name))
  
  # Add confidence interval lines
  for (i in 1:opt_brks[1]) {
    abline(v = analysis_data[[f_col]][ci_mod$confint[i,2]], col = "blue", lwd = 2)
    abline(v = analysis_data[[f_col]][ci_mod$confint[i,1]], col = "red", lty = 3)
    abline(v = analysis_data[[f_col]][ci_mod$confint[i,3]], col = "red", lty = 3)}
  
  legend("topright", legend = c("Best estimate", "Confidence limits"), 
         col = c("blue", "red"), lty = c(1, 3), lwd = c(2, 1))
  
  # Return results as a list
  results <- list(
    region = region_name,
    lag_used = lag_years,
    breakpoints = bpts2,
    optimal_breaks = opt_brks[1],
    break_f_values = best_brk,
    break_years = best_brk_years,
    confidence_intervals = ci_mod)
  
  cat("\n")
  return(results)}


#--------------------------------------------------------------------------------------
## Plot Hysteresis
#--------------------------------------------------------------------------------------

plot_hysteresis <- function(data, break_years, component,
                            msy_btrigger = 1130747, 
                            fmsy = 0.32,
                            show_msy_btrigger = TRUE,
                            show_fmsy = TRUE,
                            colors = c("#201124", "#3e478d", "#318ca5", "#5ccdaa", "#d2f1da", "navyblue"),
                            nudge_force = 1,             # control label nudging strength
                            label_box_padding = 0.35,    # padding around labels
                            label_point_padding = 0.5) { # padding from points
  
  msy_btrigger <- as.numeric(msy_btrigger)
  fmsy <- as.numeric(fmsy)
  
  # Determine number of break years
  n_breaks <- length(break_years)
  n_phases <- n_breaks + 1
  
  # Create phase assignment vector
  phase_assignment <- rep(1, nrow(data))
  for (i in 1:n_breaks) {
    phase_assignment[data$year > break_years[i]] <- i + 1}
  
  # Assign colors based on phase
  hyst_phases <- colors[phase_assignment]
  
  # Create list of phase data
  phase_data_list <- list()
  for (i in 1:n_phases) {
    if (i == 1) {
      phase_data_list[[i]] <- data %>% filter(year <= break_years[1])
    } else if (i == n_phases) {
      phase_data_list[[i]] <- data %>% filter(year > break_years[n_breaks])
    } else {
      phase_data_list[[i]] <- data %>% filter(year > break_years[i-1] & year <= break_years[i])}}
  
  # Calculate data ranges for intelligent nudging
  f_range <- range(data$F, na.rm = TRUE)
  ssb_range <- range(data$SSB_lag/1000000, na.rm = TRUE)
  f_span <- diff(f_range)
  ssb_span <- diff(ssb_range)
  
  # Create the base plot
  p <- ggplot(data = data, aes(x = F, y = SSB_lag/1000000)) +
    geom_path(colour = "grey") +
    geom_point(colour = hyst_phases) +
    labs(title = component, x = "F", y = "SSB in millions") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5))
  
  # Add MSY B trigger line and label (darkorange, as in the changepoint plots)
  if (show_msy_btrigger) {
    p <- p +
      geom_hline(yintercept = msy_btrigger/1000000, linetype = "dashed", color = "darkorange") +
      annotate("text", x = f_range[1] + f_span * 0.02, y = msy_btrigger/1000000,
               label = expression("MSY B"[trigger]), color = "darkorange", size = 3.5,
               fontface = "bold", hjust = 0, vjust = -0.5)}

  # Add F_MSY line and label (light blue, as in the changepoint plots)
  if (show_fmsy) {
    p <- p +
      geom_vline(xintercept = fmsy, linetype = "dashed", color = "#56B4E9") +
      annotate("text", x = fmsy, y = ssb_range[1] + ssb_span * 0.02,
               label = expression("F"[MSY]), color = "#56B4E9", size = 3.5,
               hjust = -0.2, vjust = 0)}
  
  # Add geom_smooth for each phase
  for (i in 1:n_phases) {
    if (nrow(phase_data_list[[i]]) > 0) {
      p <- p + geom_smooth(data = phase_data_list[[i]], aes(x = F, y = SSB_lag/1000000),
                           method = "lm", colour = colors[i])}}
  
  # Prepare data for labeling
  label_data <- data.frame()
  
  # Add break years
  for (i in 1:n_breaks) {
    break_year_data <- data %>% filter(year == break_years[i])
    if (nrow(break_year_data) > 0) {
      label_data <- rbind(label_data, break_year_data)}}
  
  # Add first and last years
  first_last_data <- data[c(1, nrow(data)), ]
  label_data <- rbind(label_data, first_last_data)
  
  # Remove duplicates (in case break years include first/last years)
  label_data <- label_data[!duplicated(label_data$year), ]
  
  # Automatic label nudging
  p <- p + geom_text_repel(
    data = label_data,
    aes(label = year),
    box.padding = label_box_padding,
    point.padding = label_point_padding,
    force = nudge_force,
    force_pull = nudge_force * 0.5,
    max.overlaps = Inf,
    min.segment.length = 0,
    segment.size = 0.3,
    segment.alpha = 0.6,
    size = 3.2,
    fontface = "italic",
    color = "black",
    direction = "both",
    seed = 42)

  return(p)}
#--------------------------------------------------------------------------------------
## Extract SRR Breakpoints
#--------------------------------------------------------------------------------------

srr_breakpoint_analysis <- function(data, ssb_col = "SSB", r_col = "Recruitment", year_col = "year",
                                    region_name = "Region", plot_breakpoints = TRUE) {

  # Print region being analyzed
  cat("=== SRR Analysis for", region_name, "===\n")

  # Remove rows with missing values for analysis
  analysis_data <- data[complete.cases(data[c(ssb_col, r_col, year_col)]), ]

  if(nrow(analysis_data) < nrow(data)) {
    cat("# Removed", nrow(data) - nrow(analysis_data), "rows with missing values\n")}

  bpts_SRR <- strucchange::breakpoints(analysis_data[[r_col]] ~ analysis_data[[ssb_col]])

  if(plot_breakpoints) {
    plot(bpts_SRR, main = paste("SRR Breakpoints for", region_name))}

  # Get summary and find optimal breaks
  bpts_SRR_sum <- summary(bpts_SRR)
  opt_brks_SRR <- opt_bpts(bpts_SRR_sum$RSS["BIC",])

  cat("# Optimal number of breaks:", opt_brks_SRR[1], "\n")

  # Get breakpoints with optimal number of breaks
  bpts2_SRR <- strucchange::breakpoints(bpts_SRR, breaks = opt_brks_SRR[1])
  best_brk_SRR <- analysis_data[[ssb_col]][bpts2_SRR$breakpoints]

  cat("# Best breakpoint SSB values:\n")
  cat("#", paste(round(best_brk_SRR, 1), collapse = ", "), "\n")

  # Get breakpoint years
  best_brk_years_SRR <- analysis_data[[year_col]][bpts2_SRR$breakpoints]

  cat("# Best breakpoint years:\n")
  cat("#", paste(best_brk_years_SRR, collapse = ", "), "\n")

  # Create stock-recruitment plot with breakpoints
  par(mfrow = c(1,1))
  ci_mod_SRR <- confint(bpts_SRR, breaks = opt_brks_SRR[1])

  plot(analysis_data[[r_col]] ~ analysis_data[[ssb_col]], type = "p",
       xlab = "SSB", ylab = "Recruitment (R)",
       main = paste("Stock-Recruitment Relationship with Breakpoints -", region_name))

  # Add confidence interval lines
  for (i in 1:opt_brks_SRR[1]) {
    abline(v = analysis_data[[ssb_col]][ci_mod_SRR$confint[i,2]], col = "blue", lwd = 2)
    abline(v = analysis_data[[ssb_col]][ci_mod_SRR$confint[i,1]], col = "red", lty = 3)
    abline(v = analysis_data[[ssb_col]][ci_mod_SRR$confint[i,3]], col = "red", lty = 3)}

  legend("topright", legend = c("Best estimate", "Confidence limits"),
         col = c("blue", "red"), lty = c(1, 3), lwd = c(2, 1))

  results <- list(
    region = region_name,
    data_used = analysis_data,
    breakpoints = bpts2_SRR,
    optimal_breaks = opt_brks_SRR[1],
    break_ssb_values = best_brk_SRR,
    break_years = best_brk_years_SRR,
    confidence_intervals = ci_mod_SRR,
    summary = bpts_SRR_sum)

  cat("\n")
  return(results)}


#--------------------------------------------------------------------------------------
## Plot SRR
#--------------------------------------------------------------------------------------

plot_SRR <- function(data, break_years, title_stock, used_model,
                     ssb_col = "SSB", r_col = "Recruitment", year_col = "year",
                     Blim = 828874,
                     show_Blim = TRUE,  # New argument to control Blim display
                     colors = c("#201124", "#3e478d", "#318ca5", "#5ccdaa", "#d2f1da", "navyblue"),
                     nudge_params = NULL) {  # New argument for nudge parameters
  
  # Check if specified columns exist in the data
  required_cols <- c(ssb_col, r_col, year_col)
  missing_cols <- required_cols[!required_cols %in% names(data)]
  if (length(missing_cols) > 0) {
    stop("Missing columns in data: ", paste(missing_cols, collapse = ", "))}
  
  # Determine number of break years and resulting phases
  n_breaks <- length(break_years)
  n_phases <- n_breaks + 1
  
  # Create phase column based on break years
  data$phase <- 1
  for (i in 1:n_breaks) {
    data$phase[data[[year_col]] > break_years[i]] <- i + 1}
  
  # Set default nudge parameters if not provided
  if (is.null(nudge_params)) {
    nudge_params <- list(
      list(nudge_y = -5, nudge_x = -0.2), # first year
      list(nudge_y = 0, nudge_x = -0.5),  # breakpoint
      list(nudge_y = -5, nudge_x = -0.2), # last year
      list(nudge_y = 5, nudge_x = -0.2),  # more breakpoints
      list(nudge_y = -0, nudge_x = -0.2))}
  
  # Create the plot using the specified column names
  p <- ggplot(data = data, aes(x = .data[[ssb_col]] / 1000000, y = .data[[r_col]] / 1000000)) +
    geom_path(colour = "grey") +
    geom_point(aes(color = factor(phase))) +
    scale_color_manual(values = colors[1:n_phases]) +
    labs(title = title_stock, 
         subtitle = used_model,
         x = "SSB in million t", 
         y = "R in billions") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"), 
          plot.subtitle = element_text(hjust = 0.5, size = 12, face = "italic"),
          legend.position = "none",
          axis.text = element_text(size = 12))
  
  # Add Blim line and label only if show_Blim is TRUE
  if (show_Blim) {
    p <- p + 
      geom_vline(xintercept = Blim / 1000000, linetype = "dashed", color = "gray30") +
      geom_label(x = Blim / 1000000, y = 7, label = expression("B"[lim]),
                 color = "gray30", size = 3.5, fontface = "bold")}
  
  # Add geom_smooth for each phase
  for (i in 1:n_phases) {
    phase_data <- data %>% dplyr::filter(phase == i)
    if (nrow(phase_data) > 0) {
      p <- p + geom_smooth(data = phase_data,
                           mapping = aes(x = .data[[ssb_col]] / 1000000, 
                                         y = .data[[r_col]] / 1000000),
                           col = colors[i], method = "lm")}}
  
  # Add text labels for the first and last years with complete SSB/R data
  complete_idx <- which(complete.cases(data[c(ssb_col, r_col)]))
  p <- p + geom_text_repel(data = data[min(complete_idx), ],
                           aes(label = .data[[year_col]]),
                           point.padding = 0.2,
                           nudge_y = nudge_params[[1]]$nudge_y,
                           nudge_x = nudge_params[[1]]$nudge_x,
                           size = 3, col = "gray30", segment.size = 0.2) +
    geom_text_repel(data = data[max(complete_idx), ],
                    aes(label = .data[[year_col]]),
                    point.padding = 0.2,
                    nudge_y = nudge_params[[3]]$nudge_y,
                    nudge_x = nudge_params[[3]]$nudge_x,
                    size = 3, col = "gray30", segment.size = 0.2)
  
  # Add text labels for each breakpoint year
  for (i in 1:n_breaks) {
    brk_year <- break_years[i]
    break_year_data <- data %>% dplyr::filter(.data[[year_col]] == brk_year)
    if (nrow(break_year_data) > 0) {
      nudge_idx <- (i %% length(nudge_params)) + 1
      p <- p + geom_text_repel(data = break_year_data, 
                               aes(label = .data[[year_col]]),
                               point.padding = 0.2,
                               nudge_y = nudge_params[[nudge_idx]]$nudge_y,
                               nudge_x = nudge_params[[nudge_idx]]$nudge_x,
                               size = 3, col = "gray30", segment.size = 0.2)}}
  
  return(p)}
