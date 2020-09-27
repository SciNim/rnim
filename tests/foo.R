add1 <- function(a) {
  return(a + 1)
}

makeString <- function(a) {
    return(toString(a))
}

returnFn <- function() {
    aFn <- function(a, param) {
        return(5)
    }
    return(aFn)
}


dotFn <- function(..., param) {
    return(param)
}
