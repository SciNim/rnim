when defined(Windows):
  const
    libname* = "R.dll"
else:
  const
    libname* = "libR.so"

import Rinternals_types

var R_GlobalEnv*: SEXP
proc lang1*(a: SEXP): SEXP {.cdecl, importc: "Rf_lang1", dynlib: libname.}
proc lang2*(a, b: SEXP): SEXP {.cdecl, importc: "Rf_lang2", dynlib: libname.}
proc lang3*(a, b, c: SEXP): SEXP {.cdecl, importc: "Rf_lang3", dynlib: libname.}
proc lang4*(a, b, c, d: SEXP): SEXP {.cdecl, importc: "Rf_lang4", dynlib: libname.}
proc lang5*(a, b, c, d, e: SEXP): SEXP {.cdecl, importc: "Rf_lang5", dynlib: libname.}
proc lang6*(a, b, c, d, e, f: SEXP): SEXP {.cdecl, importc: "Rf_lang6", dynlib: libname.}
proc install*(a: cstring): SEXP {.cdecl, importc: "Rf_install", dynlib: libname.}
proc mkString*(a: cstring): SEXP {.cdecl, importc: "Rf_mkString", dynlib: libname.}
proc tryEval*(a, b: SEXP, c: ptr cint): SEXP {.cdecl, importc: "R_tryEval", dynlib: libname.}
proc protect*(s: SEXP): SEXP {.cdecl, importc: "Rf_protect", dynlib: libname.}
proc unprotect*(a: cint) {.cdecl, importc: "Rf_unprotect", dynlib: libname.}
proc allocVector*(a: SEXPTYPE, b: R_xlen_t): SEXP {.cdecl, importc: "Rf_allocVector", dynlib: libname.}
proc LENGTH*(x: SEXP): cint {.cdecl, importc: "LENGTH", dynlib: libname.}
proc INTEGER*(x: SEXP): ptr cint {.cdecl, importc: "INTEGER", dynlib: libname.}
proc REAL*(x: SEXP): ptr cdouble {.cdecl, importc: "REAL", dynlib: libname.}
proc DATAPTR*(x: SEXP): ptr cint {.cdecl, importc: "DATAPTR", dynlib: libname.}
proc STDVEC_DATAPTR*(x: SEXP): ptr cint {.cdecl, importc: "STDVEC_DATAPTR", dynlib: libname.}
proc setAttrib*(a, b, c: SEXP): SEXP {.cdecl, importc: "Rf_setAttrib", dynlib: libname.}
proc isInteger*(s: SEXP): Rboolean {.cdecl, importc: "Rf_isInteger", dynlib: libname.}
proc cons*(a, b: SEXP): SEXP {.cdecl, importc: "Rf_cons", dynlib: libname.}
proc SET_TAG*(x, y: SEXP) {.cdecl, importc: "SET_TAG", dynlib: libname.}

template LISTVAL*(x: untyped): untyped = x.u.listsxp
template TAG*(x: untyped): untyped = x.u.listsxp.tagval
template CAR0*(x: untyped): untyped = x.u.listsxp.carval
template CDR*(x: untyped): untyped = x.u.listsxp.cdrval

template STRING_PTR*(x: untyped): untyped =
  #define STRING_PTR(x)	((SEXP *) DATAPTR(x))
  cast[ptr SEXP](DATAPTR(x))

template CHAR*(x: untyped): untyped =
  #cast[cstring](STDVEC_DATAPTR(x)) # had this before. why? impl was different though
  cast[cstring](DATAPTR(x))
