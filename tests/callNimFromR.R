dyn.load("tests/libtNimFromR.so")
# .Call("R_init_tNimFromR")
addNim <- function(a, b) {
    return(.Call("addXY", a, b))
}
