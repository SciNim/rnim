import Rinternals_types, Rinternals

# TODO: fix this. Also in types file!
type
  Rboolean* = enum
    FALSE, TRUE, MAYBE

  DL_FUNC* = pointer

  R_NativePrimitiveArgType* = uint

  Rf_DotCSymbol* = object
    name*: cstring
    fun*: DL_FUNC
    numArgs*: cint
    types*: R_NativePrimitiveArgType

  Rf_DotFortranSymbol* = Rf_DotCSymbol

  R_CMethodDef* = Rf_DotCSymbol
  R_CallMethodDef* = Rf_DotCallSymbol
  Rf_DotExternalSymbol* = Rf_DotCallSymbol
  R_FortranMethodDef* = Rf_DotCSymbol
  R_ExternalMethodDef* = Rf_DotExternalSymbol


  Rf_DotCallSymbol* = object
    name*: cstring
    fun*: DL_FUNC
    numArgs*: cint

  HINSTANCE* = pointer
  DllInfo* = object
    path*: cstring
    name*: cstring
    handle*: HINSTANCE
    useDynamicLookupg*: Rboolean # Flag indicating whether we use both
                                 # registered and dynamic lookup (TRUE)
                                 # or just registered values if there
                                 # are any.
    numCSymbols*: cint
    CSymbols*: ptr Rf_DotCSymbol

    numCallSymbols*: cint
    CallSymbols*: ptr Rf_DotCallSymbol

    numFortranSymbols*: cint
    FortranSymbols*: ptr Rf_DotFortranSymbol

    numExternalSymbols*: cint
    ExternalSymbols*: ptr Rf_DotExternalSymbol

    forceSymbols*: Rboolean

let R_ClassSymbol* {.importc: "R_ClassSymbol", dynlib: libname.}: SEXP

proc R_registerRoutines*(
  info: ptr DllInfo,
  croutines: ptr R_CMethodDef,
  callRoutines: ptr R_CallMethodDef,
  fortranRoutines: ptr R_FortranMethodDef,
  externalRoutines: ptr R_ExternalMethodDef) {.cdecl, importc: "R_RegisterRoutines", dynlib: libname.}
