import rnim / [Rinternals, Rembedded, Rinternals_types, Rext, auto_wrapper]
export RInternals, Rembedded, Rinternals_types, Rext, auto_wrapper
import macros, tables, os

type
  RContextObj = object
    replSetup: bool
  RContext* = ref RcontextObj

## Our global CT variable that stores all information to auto serialize the
## Nim exported procedures to a corresponding R wrapper.
var moduleTable {.compileTime.} = initTable[string, NimRModule]()

when defined(gcDestructors):
  proc teardown*(ctx: var RContextObj)
  proc `=destroy`(x: var RContextObj) =
    ## tear down the R repl, if it's up
    if x.replSetup:
      teardown(x)
else:
  proc teardown*(ctx: RContext)
  proc finalize(x: RContext) =
    ## tear down the R repl, if it's up
    ## As far as I understand there's no guarantee that this finalizer will be
    ## called in due time. Probably better to manually tear down R?
    if x.replSetup:
      teardown(x)

proc traverseTree(input: NimNode): NimNode =
  # iterate children
  for i in 0 ..< input.len:
    case input[i].kind
    of nnkSym:
      # if we found a symbol, take it
      result = input[i]
    of nnkBracketExpr:
      # has more children, traverse
      result = traverseTree(input[i])
    else:
      error("Unsupported type: " & $input.kind)

macro getInnerType(TT: typed): untyped =
  ## macro to get the subtype of a nested type by iterating
  ## the AST
  # traverse the AST
  let res = traverseTree(TT.getTypeInst)
  # assign symbol to result
  result = quote do:
    `res`

proc assignToCtTable(fn, name, params: NimNode) =
  ## Assigns the given procedure to the CT table and serializes an R file
  ## from the procedures
  ## TODO: Should we use the full path to always emit next to the Nim file or always
  ## local?
  let (_, filename, _) = fn.lineInfoObj.filename.extractFilename.splitFile
  var pt = moduleTable.getOrDefault(filename, NimRModule(file: filename))
  pt.add(name, params)
  pt.serialize()
  moduleTable[filename] = pt

macro exportR*(fn: untyped): untyped =
  ## Rewrites the pragmas to be correct for export to R.
  ##
  ## This means attaching the following 3 pragmas:
  ## 1. `exportc` with the name of the Nim procedure to be used
  ## 2. `cdecl` for calling convention
  ## 3. `dynlib` to export it to the shared library
  # 0. check it's actually a procedure
  if fn.kind notin {nnkProcDef, nnkFuncDef}:
    error("The {.exportR.} pragma currently may only be used on procedures!")
  # 1. get name of the procedure
  let name = fn.name
  # 2. generate the nnkPragma node
  let prag = nnkPragma.newTree(
    nnkExprColonExpr.newTree(ident"exportc", name.toStrLit),
    ident"cdecl", ident"dynlib"
  )
  # 3. return the modified procedure with correct parameters
  result = fn
  result.pragma = prag
  # 4. add result to proc table to generate an R wrapper for it
  fn.assignToCtTable(result.name, result.params)

## R assignment operators
## Note: these can only use already defined variables. So you cannot
## use them to assign during variable declaration
## TODO: not leave them as untyped
## Also, this is kind of a party trick. Might be useful to use it for
## auto converting a Nim type to SEXP though
template `<-`*(lhs, rhs: untyped): untyped =
  lhs = rhs

template `->`*(lhs, rhs: untyped): untyped =
  rhs = lhs

template PROTECT*(arg: untyped): untyped =
  protect(arg)

template UNPROTECT*(arg: untyped): untyped =
  unprotect(arg)

proc nimToR*[T](arg: T): SEXP =
  ## NOTE: Even basic types like ints and floats are represented by
  ## vectors (of size 1) in R!
  ## TODO: make this a bit more concise?
  var s: SEXP
  when T is seq[int8|int16|int32|uint8|uint16]:
    # TODO: broken for types not matching in size to cint!
    ## NOTE: native 64 bit integers are not supported!
    s = allocVector(INTSXP, arg.len.cint)
    discard PROTECT(s)
    when sizeof(getInnerType(T)) == sizeof(cint):
      copyMem(INTEGER(s), arg[0].unsafeAddr, arg.len * sizeof(cint))
    else:
      # copy manually and convert to `cint`
      var buf = cast[ptr UncheckedArray[cint]](INTEGER(s))
      for i in 0 ..< arg.len:
        buf[i] = arg[i].cint
  elif T is seq[uint32|int|int64|uint64]:
    # have to be handled as floats
    s = allocVector(REALSXP, arg.len.cint)
    discard PROTECT(s)
    var buf = cast[ptr UncheckedArray[cdouble]](REAL(s))
    for i in 0 ..< arg.len:
      buf[i] = arg[i].cdouble
  elif T is seq[float|float32|float64]:
    s = allocVector(REALSXP, arg.len.cint)
    discard PROTECT(s)
    when sizeof(getInnerType(T)) == sizeof(cdouble):
      copyMem(REAL(s), arg[0].unsafeAddr, arg.len * sizeof(cdouble))
    else:
      var buf = cast[ptr UncheckedArray[cdouble]](REAL(s))
      for i in 0 ..< arg.len:
        buf[i] = arg[i].cdouble
  elif T is int8|int16|int32|uint8|uint16:
    s = allocVector(INTSXP, 1)
    discard PROTECT(s)
    INTEGER(s)[] = arg.cint
  elif T is float|float32|float64|uint32|uint64|int|int64:
    s = allocVector(REALSXP, 1.cint)
    discard PROTECT(s)
    REAL(s)[] = arg.cdouble
  elif T is string:
    s = mkString(arg.cstring)
  elif T is SEXP:
    s = arg
  else:
    doAssert false, "Type not impld yet " & $(typeof(T))
  UNPROTECT(1)
  s

proc setTagInList*(s: SEXP, val: SEXP, idx: int) =
  ## recursively walks cdr of `s` until `idx == 0` and sets the
  ## `val` there
  if idx == 0 and TYPEOF(s) != NILSXP:
    SET_TAG(s, val)
  elif idx > 0:
    setTagInList(CDR(s), val, idx - 1)
  elif TYPEOF(s) != NILSXP:
    doAssert false, "CDR of list is nil!"
  else:
    doAssert false, "Invalid call to `setTagInList`"

macro call*(fn: untyped, args: varargs[untyped]): untyped =
  # Setup a call to the R function
  var callIdent: NimNode
  # TODO: replace by macro generated
  callIdent = ident("lang" & $(args.len + 1))
  doAssert args.len < 6, "Unsupported number of arguments " & $(args.len) &
    " to call " & $(fn.toStrLit)
  # TODO: copy to Nim type to be able to unprotect R?
  let fnName = block:
    var res: NimNode
    case fn.kind
    of nnkIdent: res = fn.toStrLit
    of nnkStrLit: res = fn
    of nnkAccQuoted: res = fn[0].toStrLit
    else: res = newLit fn.repr #doAssert false, "Invalid kind of func " & $(fn.kind)
    res
  var callNode = nnkCall.newTree(
    callIdent,
    # `install` (Rf_install) returns a pointer to the given symbol
    nnkCall.newTree(ident"install", fnName)
  )

  var tagsToAdd: seq[(int, NimNode)]
  var idx = 1
  for arg in args:
    case arg.kind
    of nnkIdent, nnkSym, nnkPrefix, nnkIntLit .. nnkFloatLit, nnkStrLit, nnkCall:
      callNode.add nnkCall.newTree(ident"nimToR", arg)
    of nnkExprEqExpr:
      callNode.add nnkCall.newTree(ident"nimToR", arg[1])
      tagsToAdd.add((idx, arg[0].toStrLit))
    else: doAssert false, "Unsupported node kind " & $arg.kind & " of val " & $(arg.repr)
    inc idx
  var tagsSet = newStmtList()
  var callRes = ident"callRes"
  for (i, tag) in tagsToAdd:
    tagsSet.add nnkCall.newTree(ident"setTagInList", callRes,
                                nnkCall.newTree(ident"install", tag),
                                newLit i)
  result = quote do:
    block:
      var `callRes`: SEXP
      `callRes` = `callNode`
      discard PROTECT(`callRes`)
      `tagsSet`
      `callRes`

template eval*(s: SEXP): untyped =
  var errorOccurred: cint
  var ret = tryEval(s, R_GlobalEnv, errorOccurred.addr)
  doAssert errorOccurred == 0, "Eval of sexp failed." # TODO: add sexp repr once impld
  ret

macro callEval*(fn: untyped, args: varargs[untyped]): untyped =
  let unprotectLen = args.len + 1
  result = quote do:
    let fnCall = call(`fn`, `args`)
    let ret = eval(fnCall)
    UNPROTECT(`unprotectLen`) # fn, args
    ret

proc source*(R: RContext, name: string) =
  ## Invokes the command source("foo.R").
  doAssert R.replSetup, "Cannot source a file if the given R context isn't initialized!"
  discard callEval(source, name)

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

proc copySexpValToNim[T](s: SEXP, res: var T) =
  case s.sxpinfo.type
  of INTSXP:
    var val = cast[ptr UncheckedArray[cint]](INTEGER(s))
    res = val[0].T
  of REALSXP:
    var val = cast[ptr UncheckedArray[cdouble]](REAL(s))
    res = val[0].T
  else:
    doAssert false, "Invalid type " & $(s.sxpinfo.type) & " to copy to " & $(type(T))

proc to*[T](s: SEXP, dtype: typedesc[T]): T =
  ## NOTE: Even basic types like ints and floats are represented by
  ## vectors (of size 1) in R!
  when T is seq[SomeNumber]:
    copySexpToSeq(s, result)
  elif T is SomeNumber:
    copySexpValToNim(s, result)
  elif T is string:
    var val = cast[ptr UncheckedArray[SEXP]](STRING_PTR(s))
    result = $(CHAR(val[0]).cstring)
  else:
    doAssert false, "Type unsupported so far " & $typeof(dtype)

template `.()`*(ctx: RContext, fn: untyped, args: varargs[untyped]): untyped =
  callEval(fn, args)

proc toFnName(n: NimNode): NimNode =
  case n.kind
  of nnkIdent, nnkSym: result = n
  of nnkDotExpr: result = n.toStrLit
  else: doAssert false, "Invalid kind " & $n.kind & " for a function name!"

proc makeValidRCall(n: NimNode, toDiscard: bool): NimNode =
  case n.kind
  of nnkAsgn:
    result = n
    # make sure child [1] is handled correctly
    result[1] = makeValidRCall(n[1], toDiscard = false)
  of nnkLetSection, nnkVarSection:
    result = n
    # handle the [2] child node of the identDef
    expectKind(n[0], nnkIdentDefs)
    result[0][2] = makeValidRCall(n[0][2], toDiscard = false)
  of nnkCall:
    let fnName = toFnName(n[0])
    var newCall = nnkCall.newTree(ident"callEval", fnName)
    for i in 1 ..< n.len:
      newCall.add n[i]
    result = if toDiscard: nnkDiscardStmt.newTree(newCall) else: newCall
  else:
    doAssert false, "Unsupported node kind " & $n.kind & " in `Rctx` macro!"

macro Rctx*(body: untyped): untyped =
  expectKind(body, nnkStmtList)
  # construct correct R calls from each statement in the body
  result = newStmtList()
  for arg in body:
    result.add makeValidRCall(arg, true)

proc setupR*(): RContext =
  const r_argc = 2;
  let r_argv = ["R".cstring, "--silent".cstring]
  discard Rf_initEmbeddedR(r_argc, r_argv[0].unsafeAddr)
  when defined(gcDestructors):
    result = new RContext
  else:
    new(result, finalize)
  result.replSetup = true

template tdBody(): untyped {.dirty.} =
  # TODO: this does not seem to have any effect? Setting up a new
  # R repl will print that a repl is running already.
  Rf_endEmbeddedR(0)
  ctx.replSetup = false

## Note: we separate the two teardown procs for the simple reason that
## if we combine them we run into a weird issue where the resulting
## generic won't accept the `ctx.replSetup` assignment for the `gcDestructors`
## case.
when defined(gcDestructors):
  proc teardown*(ctx: var RContextObj) =
    tdBody()
else:
  proc teardown*(ctx: RContext) =
    tdBody()

template withR*(body: untyped): untyped =
  let R {.inject.} = setupR()
  body
  R.teardown()
