LR_var <- function(x, minseg = 2) {
  n <- length(x)
  if (n < 2*minseg) return(c(tau = 0, max_LR = 0)) 
  
  xsq <- x^2
  C <- cumsum(xsq)
  C_total <- C[n]
  k <- minseg:(n-minseg)
  
  var_left <- C[k] / k
  var_right <- (C_total - C[k]) / (n - k)
  var_total <- C_total / n
  
  LR <- n * log(var_total) - (k * log(var_left) + (n - k) * log(var_right))
  LR[is.na(LR) | is.infinite(LR)] <- 0
  
  return(max(LR))
}


sliding_window <- function(x, eta, h, c){
  print(glue("threshold is {c}"))
  n <- length(x)
  candidates <- matrix(ncol=2, nrow=n-1)
  colnames(candidates) <- c("index", "score")
  
  for (t in (h+1):(n-h)){
    A <- t-h+1
    B <- t
    C <- t+h
    size <- h
    
    #title <- glue("Iteration{t-h}.jpeg")
    #jpeg(title, width=1920/2, height=1080/2, units="px")
    # plot(x, main=glue("Window {A} to {C}"))
    # abline(v=A, col="green")
    # abline(v=C, col="green")
    # abline(v=B, col="red", lty=2)
    # clip(A, B, min(x), max(x))
    # abline(h=mean(x[A:B]), col="blue")
    # clip(B, C, min(x), max(x))
    # abline(h=mean(x[B:C]), col="blue") 
    #dev.off()
    
    teststat <- LR_var(x[A:C], size)
    #print(teststat)
    if (teststat>c){
      #newcand <- list(B-1, teststat)
      candidates[t,] <-  c(B, teststat)
    }
  }
  candidates <- candidates[-1,]
  candidates <- na.omit(candidates)
  sorted_cands <- candidates[order(candidates[, "score"], decreasing=TRUE), ]
  changepoints <- c()
  while(length(sorted_cands)>0){
    print(glue("Highest score is  {sorted_cands[1,2]}"))
    if (length(sorted_cands)==2){
      changepoints <- c(changepoints, sorted_cands[1])
      return(list(cps=sort(unname(changepoints))))
    }
    
    #plot(x)
    remove <- c()
    changepoint <- sorted_cands[1,1]
    #abline(v=changepoint, col="red")
    changepoints <- c(changepoints, changepoint)
    for (i in 1:nrow(sorted_cands)){
      #abline(v=sorted_cands[i,1], col="grey", lty=2)
      if (abs(changepoint-sorted_cands[i,1])<= eta){
        remove <- c(remove, i)
      }
    }
    if (nrow(sorted_cands) == length(remove)){
      return(list(cps=sort(unname(changepoints))))
    }
    sorted_cands <- sorted_cands[-remove, ,drop=FALSE]
  }
  return(0)
  
}

sliding_window_vectorised<- function(x, eta, h, c){
  print(glue("threshold is {c}"))
  n <- length(x)
  C <- cumsum(x**2)
  C <- c(0, C)
  t <- (h+1):(n-h)
  left  <- (C[t+1] - C[t - h+1]) / h
  right <- (C[t + h+1] - C[t+1]) / h
  total <- (C[t + h+1] - C[t - h+1]) / (2 * h)
  
  lr <- (2 * h) * log(total) - (h * log(left) + h * log(right))
  lr[is.na(lr) | is.infinite(lr)] <- 0
  
  lr_scores <- rep(0, n)
  lr_scores[t] <- lr
  candidates <- which(lr_scores > c)
  changepoints <- c()
  
  while (length(candidates) > 0) {
    merge_index <- candidates[which.max(lr_scores[candidates])]
    changepoints <- c(changepoints, merge_index)
    suppressed_zone <- (merge_index - eta):(merge_index + eta)
    candidates <- setdiff(candidates, suppressed_zone)
  }
  return(list(cps = sort(unname(changepoints)), scores = lr_scores))
}

# mu_1 <- 0
# sigma_1 <- 1
# sigma_2 <- 4
# sigma_3 <- 10
# x_1 <- mu_1 + sigma_1*rnorm(200, 0, 1)
# x_2 <- mu_1 + sigma_2*rnorm(300, 0, 1)
# x_3 <- mu_1 + sigma_3*rnorm(100,0,1)
# x <- c(x_1, x_2, x_3)
# plot(x, xlab="t", ylab="X_t")
# clip(0,600, -100, 100)
# abline(h=mu_1, col="red")
# abline(v=200, lty=2 )
# abline(v=500, lty=2 )
# sliding_window(x, 10, 10, 4*log(log(600)))
# sliding_window_vectorised(x, 10, 10, 4*log(log(600)))
# LR_var(x)
