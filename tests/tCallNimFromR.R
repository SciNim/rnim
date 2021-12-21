dyn.load("tests/libtNimFromR.so")

addXYInt <- function(a, b) {
    return(.Call("addXYInt", a, b))
}

addXYFloat <- function(a, b) {
    return(.Call("addXYFloat", a, b))
}

addVecs <- function(a, b) {
    return(.Call("addVecs", a, b))
}

check <- function(arg) {
    if (!all(arg)){
        stop(paste("Failed to run ", deparse(arg)))
    }
}


check(addXYInt(1L, 1L) == 1L + 1L)
check(addXYFloat(1L, 1L) == 1.0 + 1.0)

check(addXYInt(1.0, 1.0) == 1L + 1L)
check(addXYFloat(1.0, 1.0) == 1.0 + 1.0)

x <- 1:5

check(addVecs(x, x) == x + x)

y <- c(1.0, 2.0, 3.5, 4.0, 5.2)

check(addVecs(y, y) == y + y)

check(addVecs(x, y) == x + y)
