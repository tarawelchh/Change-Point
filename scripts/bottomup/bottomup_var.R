bottom_up_variance <- function(x, threshold) {
  n <- length(x)
  segments <- seq(1, n, by = 5) #cant have segment length 1
  if(segments[length(segments)] != n+1) segments <- c(segments, n+1) #adds leftover segment tht arent multiple of 5
  deltas <- numeric(length(segments)-2)
  iter <-1
  
  merged <- FALSE
  while(!merged) {
    deltamin <- Inf
    merge_index <- 0
      for (i in 1:(length(segments) - 2)) {
      start <- segments[i]
      mid   <- segments[i+1]
      end   <- segments[i+2] - 1
      
      test_block <- x[start:end]
      n_block <- length(test_block)
      k_split <- mid - start
      
      v_total <- var(test_block)
      v_left  <- var(test_block[1:k_split])
      v_right <- var(test_block[(k_split+1):n_block])
      
      delta <- n_block*log(v_total) - (k_split*log(v_left) + (n_block - k_split)*log(v_right))
      
      if (delta < deltamin) {
        deltamin <- delta
        merge_index <- i + 1
      }
    }
    deltas[iter]<- deltamin
    iter<- iter +1
    
    if (deltamin < threshold && length(segments) > 2) {
      segments <- segments[-merge_index]
    } else {
      merged <- TRUE
    }
  }
  return(list(cps=segments[c(-1, -length(segments))], 
              costs=deltas))
}

deltalist <- function(x) {
  n <- length(x)
  segments <- seq(1, n, by = 5) #cant have segment length 1
  if(segments[length(segments)] != n+1) segments <- c(segments, n+1) #adds leftover segment tht arent multiple of 5
  deltalist <- numeric(length(segments)-2)
  iter <-1
  
  merged <- FALSE
  while(length(segments)>2) {
    deltamin <- Inf
    merge_index <- 0
    for (i in 1:(length(segments) - 2)) {
      start <- segments[i]
      mid   <- segments[i+1]
      end   <- segments[i+2] - 1
      
      test_block <- x[start:end]
      n_block <- length(test_block)
      k_split <- mid - start
      
      v_total <- var(test_block)
      v_left  <- var(test_block[1:k_split])
      v_right <- var(test_block[(k_split+1):n_block])
      
      delta <- n_block*log(v_total) - (k_split*log(v_left) + (n_block - k_split)*log(v_right))
      
      if (delta < deltamin) {
        deltamin <- delta
        merge_index <- i + 1
      }
    }
    deltalist[iter]<- deltamin
    iter<- iter+1
    
    if  (length(segments) > 2) {
      segments <- segments[-merge_index]
      #   } else {
      #     merged <- TRUE
    }
  }
  return(deltalist)
}
