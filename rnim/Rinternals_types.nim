##  ran Rinternals.h through `gcc -E` and took out the types to
##  run c2nim on

type
  sxpinfo_struct* {.bycopy.} = object
    `type`* {.bitsize: 5.}: SEXPTYPE
    scalar* {.bitsize: 1.}: cuint
    obj* {.bitsize: 1.}: cuint
    alt* {.bitsize: 1.}: cuint
    gp* {.bitsize: 16.}: cuint
    mark* {.bitsize: 1.}: cuint
    debug* {.bitsize: 1.}: cuint
    trace* {.bitsize: 1.}: cuint
    spare* {.bitsize: 1.}: cuint
    gcgen* {.bitsize: 1.}: cuint
    gccls* {.bitsize: 3.}: cuint
    named* {.bitsize: 16.}: cuint
    extra* {.bitsize: 16.}: cuint

  vecsxp_struct* {.bycopy.} = object
    length*: R_xlen_t
    truelength*: R_xlen_t

  primsxp_struct* {.bycopy.} = object
    offset*: cint

  symsxp_struct* {.bycopy.} = object
    pname*: ptr SEXPREC
    value*: ptr SEXPREC
    internal*: ptr SEXPREC

  listsxp_struct* {.bycopy.} = object
    carval*: ptr SEXPREC
    cdrval*: ptr SEXPREC
    tagval*: ptr SEXPREC

  envsxp_struct* {.bycopy.} = object
    frame*: ptr SEXPREC
    enclos*: ptr SEXPREC
    hashtab*: ptr SEXPREC

  closxp_struct* {.bycopy.} = object
    formals*: ptr SEXPREC
    body*: ptr SEXPREC
    env*: ptr SEXPREC

  promsxp_struct* {.bycopy.} = object
    value*: ptr SEXPREC
    expr*: ptr SEXPREC
    env*: ptr SEXPREC

  INNER_C_UNION_Rinternals_types_69* {.bycopy.} = object {.union.}
    primsxp*: primsxp_struct
    symsxp*: symsxp_struct
    listsxp*: listsxp_struct
    envsxp*: envsxp_struct
    closxp*: closxp_struct
    promsxp*: promsxp_struct

  SEXPREC* {.bycopy.} = object
    sxpinfo*: sxpinfo_struct
    attrib*: ptr SEXPREC
    gengc_next_node*: ptr SEXPREC
    gengc_prev_node*: ptr SEXPREC
    u*: INNER_C_UNION_Rinternals_types_69

  VECTOR_SEXPREC* {.bycopy.} = object
    sxpinfo*: sxpinfo_struct
    attrib*: ptr SEXPREC
    gengc_next_node*: ptr SEXPREC
    gengc_prev_node*: ptr SEXPREC
    vecsxp*: vecsxp_struct

  VECSEXP* = ptr VECTOR_SEXPREC
  SEXPREC_ALIGN* {.bycopy.} = object {.union.}
    s*: VECTOR_SEXPREC
    align*: cdouble

  SEXPTYPE* = enum
    NILSXP      = 0,    # nil = NULL */
    SYMSXP      = 1,    # symbols */
    LISTSXP     = 2,    # lists of dotted pairs */
    CLOSXP      = 3,    # closures */
    ENVSXP      = 4,    # environments */
    PROMSXP     = 5,    # promises: [un]evaluated closure arguments */
    LANGSXP     = 6,    # language constructs (special lists) */
    SPECIALSXP  = 7,    # special forms */
    BUILTINSXP  = 8,    # builtin non-special forms */
    CHARSXP     = 9,    # "scalar" string type (internal only)*/
    LGLSXP      = 10,   # logical vectors */
    INTSXP      = 13,   # integer vectors */
    REALSXP     = 14,   # real variables */
    CPLXSXP     = 15,   # complex variables */
    STRSXP      = 16,   # string vectors */
    DOTSXP      = 17,   # dot-dot-dot object */
    ANYSXP      = 18,   # make "any" args work */
    VECSXP      = 19,   # generic vectors */
    EXPRSXP     = 20,   # expressions vectors */
    BCODESXP    = 21,   # byte code */
    EXTPTRSXP   = 22,   # external pointer */
    WEAKREFSXP  = 23,   # weak reference */
    RAWSXP      = 24,   # raw bytes */
    S4SXP       = 25,   # S4 non-vector */
    NEWSXP      = 30,   # fresh node creaed in new page */
    FREESXP     = 31,   # node released by GC */
    FUNSXP      = 99    # Closure or Builtin */

  # SEXPTYPE* = uint
  R_xlen_t* = cint

  SEXP* = ptr SEXPREC

  Rboolean* = enum
    TRUE, FALSE

import strformat
proc TYPEOF*(s: SEXP): SEXPTYPE = s.sxpinfo.type
proc isNilSxp*(s: SEXP): bool = s.TYPEOF == NILSXP

proc `$`*(s: SEXP): string
proc toStr*(s: SEXP): string =
  case TYPEOF(s)
  of NILSXP: result = "NIL"
  of SYMSXP: result = &"SYM: pname = {s.u.symsxp.pname}, value = {s.u.symsxp.value}, internal = {s.u.symsxp.internal}"
  of LISTSXP: result = &"LIST: car = {s.u.listsxp.carval}, cdr = {s.u.listsxp.cdrval}, internal = {s.u.listsxp.tagval}"
  else: discard

proc `$`*(s: SEXP): string =
  if s.isNilSxp: return "nil"
  result = &"Type: {s.sxpinfo.type}\n"
  if not s.attrib.isNilSxp:
    result.add &"attrib: {toStr(s.attrib)}\n"
  # if not s.gengc_next_node.isNilSxp:
  #   result.add &"gengc_next_node: {$s.gengc_next_node}\n"
  # if not s.gengc_prev_node.isNilSxp:
  #   result.add &"gengc_prev_node: {$s.gengc_prev_node}\n"
