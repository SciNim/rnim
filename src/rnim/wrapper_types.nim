import Rinternals, Rinternals_types
from macros import error

type
  VectorKind = enum
    vkInt, vkFloat

  ## A `RawVector` is a pure wrapper around an `SEXP` containing a numerical vector in R.
  ## This means the underlying data array is *exactly* the same type as the R data storing
  ## it. This means we cannot interpret one type as another.
  RawVector*[T: cint | int32 | float | float64 | cdouble] = object
    obj: SEXP
    data: ptr UncheckedArray[T]
    len*: int

  ## A generic object that wraps an `SEXP` corresponding to a numerical vector in R.
  ## The generic argument is used to store the user's intent on what type we use
  ## on the Nim side. It does however *not* change what data is stored, as `NumericVector`
  ## is a no copy data type, it reuses the memory of the `SEXP`.
  NumericVector*[T] = object
    obj: SEXP # pointer to actual SEXP object
    len*: int
    # variant for the underlying data of `obj`. Slightly easier to access
    case kind: VectorKind
    of vkInt: idata: ptr UncheckedArray[cint]
    of vkFloat: fdata: ptr UncheckedArray[cdouble]
  # NOTE: currently we don't support `var` return types for `NumericVector` (e.g. in `[]` or `mitems`).
  # This is due to how we handle `NumericVector`. If the type does not match exactly (e.g. `float`
  # for an `INTSXP`), we *have* to convert upon returning the value. This means we are not looking at
  # the value from the array anymore, but a copy.
  # For `RawVector` this is possible, as we are restricted to the real type that is contained in the
  # R SEXP array.

template raiseException(typ: untyped, msg: untyped): untyped =
  ## TODO: exceptions if called from R don't work (they are silently ignored)
  echo typeof(typ), ": ", msg
  raise newException(typ, msg)

when false:
  proc copySexpToSeq[T](s: SEXP, res: var seq[T]) =
    # TODO: we can optimize this by using copyMem where memory compatible
    let length = LENGTH(s)
    res.setLen(length)
    case s.sxpinfo.type
    of INTSXP:
      var val = cast[ptr UncheckedArray[cint]](INTEGER(s))
      for i in 0 ..< res.len:
        res[i] = val[i].T
    of REALSXP:
      var val = cast[ptr UncheckedArray[cdouble]](REAL(s))
      for i in 0 ..< res.len:
        res[i] = val[i].T
    else:
      doAssert false, "Invalid type " & $(s.sxpinfo.type) & " to copy to " & $(type(T))

func high*[T](v: NumericVector[T]): int = v.len - 1
func high*[T](v: RawVector[T]): int = v.len - 1

proc initRawVector*[T](s: SEXP): RawVector[T] =
  case s.sxpinfo.type
  of INTSXP:
    when T is cint | int32:
      result = RawVector[T](obj: s, len: LENGTH(s),
                            data: cast[ptr UncheckedArray[T]](INTEGER(s)))
    else:
      raiseException(ValueError, "Cannot initialize a `RawVector[" & $typeof(T) & "]` from an `INTSXP`.")
  of REALSXP:
    when T is cdouble | float | float64:
      result = RawVector[T](obj: s, len: LENGTH(s),
                            data: cast[ptr UncheckedArray[T]](REAL(s)))
    else:
      raiseException(ValueError, "Cannot initialize a `RawVector[" & $typeof(T) & "]` from a `REALSXP`.")
  else:
    raiseException(ValueError, "Cannot store a " & $s.sxpinfo.type & " in a `RawVector`.")

proc initNumericVector*[T](s: SEXP): NumericVector[T] =
  case s.sxpinfo.type
  of INTSXP:
    when T is int32 | cint:
      # perfect match (integers in R are 32 bit)
      result = NumericVector[T](obj: s,
                                kind: vkInt,
                                idata: cast[ptr UncheckedArray[cint]](INTEGER(s)),
                                len: LENGTH(s))
    elif T is int | int64 | float32 | float | float64 | cdouble | cfloat:
      # ~fine
      result = NumericVector[T](obj: s,
                                kind: vkInt,
                                idata: cast[ptr UncheckedArray[cint]](INTEGER(s)),
                                len: LENGTH(s))
      when not defined(release):
        echo "Interpreting input vector of type `INTSXP` as ", typeof(T)
    else:
      static: error("Treating an `INTSXP` (32 bit integer) vector as " & $typeof(T) & " is unsupported!")
  of REALSXP:
    # TODO: do a `sizeof` check, possibly on 32 bit system, so float32 is match?
    when T is float | float64 | cdouble:
      # perfect match
      result = NumericVector[T](obj: s,
                                kind: vkFloat,
                                fdata: cast[ptr UncheckedArray[cdouble]](REAL(s)),
                                len: LENGTH(s))
    elif T is float32 | cfloat:
      # ~loss of information
      result = NumericVector[T](obj: s,
                                kind: vkFloat,
                                fdata: cast[ptr UncheckedArray[cdouble]](REAL(s)),
                                len: LENGTH(s))
      when not defined(release):
        echo "Interpreting input vector of type `REALSXP` as ", typeof(T), " loses information!"
    elif T is cint | int | int64 | int32:
      # possible loss of information, also possible it's real ints (support for >32 bit values)
      result = NumericVector[T](obj: s,
                                kind: vkFloat,
                                fdata: cast[ptr UncheckedArray[cdouble]](REAL(s)),
                                len: LENGTH(s))
      when not defined(release):
        echo "Interpreting input vector of type `REALSXP` as ", typeof(T), " loses information!"
    else:
      static: error("Treating an `INTSXP` (32 bit integer) vector as " & $typeof(T) & " is unsupported!")
  else:
    raiseException(ValueError, "Cannot store SEXP of type " & $s.sxpinfo.type & " as a `NumericVector`!")

proc `[]`*[T](v: RawVector[T], idx: int): T =
  ## Returns the element at index `idx` from the vector `v`
  when compileOption("boundChecks"):
    if unlikely(idx < 0 or idx >= v.len):
      raiseException(IndexDefect, "Index " & $idx & " is out of bounds for vector of length " & $v.len)
  result = v.data[idx]

proc `[]`*[T](v: NumericVector[T], idx: int): T =
  ## Returns the element at index `idx` from the vector `v`
  when compileOption("boundChecks"):
    if unlikely(idx < 0 or idx >= v.len):
      raiseException(IndexDefect, "Index " & $idx & " is out of bounds for vector of length " & $v.len)
  case v.kind
  of vkInt: result = v.idata[idx].T
  of vkFloat: result = v.fdata[idx].T

proc `[]`*[T](v: var RawVector[T], idx: int): var T =
  ## Returns the element at index `idx` from the vector `v`
  when compileOption("boundChecks"):
    if unlikely(idx < 0 or idx >= v.len):
      raiseException(IndexDefect, "Index " & $idx & " is out of bounds for vector of length " & $v.len)
  result = v.data[idx]

proc `[]=`*[T](v: var RawVector[T], idx: int, val: T) =
  ## Writes the value `val` to the index `idx` from the vector `v`
  when compileOption("boundChecks"):
    if unlikely(idx < 0 or idx >= v.len):
      raiseException(IndexDefect, "Index " & $idx & " is out of bounds for vector of length " & $v.len)
  v.data[idx] = val

proc `[]=`*[T](v: var NumericVector[T], idx: int, val: T) =
  ## Writes the value `val` to the index `idx` from the vector `v`
  when compileOption("boundChecks"):
    if unlikely(idx < 0 or idx >= v.len):
      raiseException(IndexDefect, "Index " & $idx & " is out of bounds for vector of length " & $v.len)
  case v.kind
  of vkInt:   v.idata[idx] = val.cint
  of vkFloat: v.fdata[idx] = val.cdouble

iterator items*[T](v: RawVector[T]): T =
  for i in 0 .. v.high:
    yield v[i]

iterator items*[T](v: NumericVector[T]): T =
  for i in 0 .. v.high:
    yield v[i]

iterator mitems*[T](v: var RawVector[T]): var T =
  for i in 0 .. v.high:
    yield v[i]

iterator pairs*[T](v: RawVector[T]): (int, T) =
  for i in 0 .. v.high:
    yield (i, v[i])

iterator pairs*[T](v: NumericVector[T]): (int, T) =
  for i in 0 .. v.high:
    yield (i, v[i])

iterator mpairs*[T](v: var RawVector[T]): (int, var T) =
  for i in 0 .. v.high:
    yield (i, v[i])

proc `==`*[T](v, w: RawVector[T]): bool =
  if v.len != w.len: return false
  for i in 0 ..< v.len:
    if v[i] != w[i]: return false
  result = true

proc `==`*[T](v, w: NumericVector[T]): bool =
  if v.len != w.len: return false
  for i in 0 ..< v.len:
    if v[i] != w[i]: return false
  result = true

proc `$`*[T](v: RawVector[T]): string =
  result = "RawVector[" & $typeof(T) & "](len: "
  result.add $v.len & ", data: ["
  for i, x in v:
    if i == v.high:
      result.add $v[i] & "]"
    else:
      result.add $v[i] & ", "
  result.add ")"

proc `$`*[T](v: NumericVector[T]): string =
  result = "NumericVector[" & $typeof(T) & "](len: "
  result.add $v.len & ", kind: "
  result.add $v.kind & ", data: ["
  for i, x in v:
    if i == v.high:
      result.add $v[i] & "]"
    else:
      result.add $v[i] & ", "
  result.add ")"
