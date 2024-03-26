import macros, strutils, os, tables

type
  ExportProc* = object
    name*: string
    origFn*: NimNode ## The original function NimNode
    isVoid*: bool
    params*: NimNode
    body*: NimNode

  NimRModule* = object
    file*: string # file that contains these procedures
    procs*: seq[ExportProc]

const getScriptPathTmpl = """
# Get the directory of the currently running script. We need it, because
# if the auto generated R file is sourced from a different directory (and assuming the shared
# library is next to the autogen'd R file) the R interpreter won't find it.
# So we need to fix the path based on the location of the autogen'd script.
scriptDir <- dirname(sys.frame(1)$ofile)
# This is a bit of a hack, see:
# https://stackoverflow.com/a/16046056https://stackoverflow.com/a/16046056
# Otherwise we could depend on the `here` library...
"""
const adjustPathTmpl = """
# Construct the path to another script in the same directory (or a subdirectory)
libPath <- file.path(scriptDir, "$#")
"""
const dynLoadTmpl = """dyn.load($#)"""
const fnTmpl = """
$name <- function($args) {
  $body
}

"""

const nonVoidBody = """
    return(.Call("$name", $args))
"""

const voidBody = """
    invisible(.Call("$name", $args))
"""

## Handy identifiers for a bit more clarity
let SEXPIdent {.compileTime.} = ident"SEXP"
let ResIdent  {.compileTime.} = ident"result"
let NilIdent  {.compileTime.} = ident"NilValue"

## Our global CT variable that stores all information to auto serialize the
## Nim exported procedures to a corresponding R wrapper.
var moduleTable {.compileTime.} = initTable[string, NimRModule]()

proc fixUpExportProc*(fn: ExportProc): ExportProc =
  ## Given a procedure, apply the necessary changes to the parameters and body
  # check if return type is void, in that case
  result = fn
  result.isVoid = result.params[0].kind == nnkEmpty
  if result.isVoid:
    # fix up the parameters and body
    result.params[0] = SEXPIdent
    result.body.add nnkAsgn.newTree(ResIdent, NilIdent)

proc argsToSeq*(expProc: ExportProc): seq[string] =
  let params = expProc.origFn.params
  result = newSeq[string]()
  for i in 1 ..< params.len:
    # start at 1 to skip child 0, return type
    let ch = params[i]
    for j in 0 ..< ch.len - 2: # each `nnkIdentDef` can contain multiple arguments, if
                               # they are the same type, e.g. `x, y: SEXP`. Always 0 to N-2
      result.add ch[j].toStrLit.strVal

proc serialize*(pt: NimRModule) {.compileTime.} =
  ## writes an R wrapper for the exported Nim procedures based on the given
  ## procedure table
  let libName = "lib" & pt.file & ".so"
  var res = getScriptPathTmpl          # get path of autogen'd R script
  res.add adjustPathTmpl % libName # produces a `libPath` local variable
  res.add dynLoadTmpl % "libPath"  # add the dyn.load call
  res.add "\n"
  for p in pt.procs:
    let args = p.argsToSeq.join(", ")
    let body = if p.isVoid:
                 voidBody % ["name", p.name,
                             "args", args]
               else:
                 nonVoidBody % ["name", p.name,
                                "args", args]
    res.add fnTmpl % ["name", p.name,
                      "args", args,
                      "body", body]
  writeFile(pt.file & ".R", res)

proc assignToCtTable*(expProc: ExportProc) =
  ## Assigns the given procedure to the CT table and serializes an R file
  ## from the procedures
  let (_, filename, _) = expProc.origFn.lineInfoObj.filename.extractFilename.splitFile
  var pt = moduleTable.getOrDefault(filename, NimRModule(file: filename))
  pt.procs.add(expProc)
  pt.serialize()
  moduleTable[filename] = pt
