dyn.load("tests/libtNimFromR.so")

source('tNimFromR.R')

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

yOrig <- c(1.0, 2.0, 3.5, 4.0, 5.2)
modifyVec(y)
check(y == yOrig + 1.0)

printVec(y)


checkSexp(x)
checkSexpRaw(x)