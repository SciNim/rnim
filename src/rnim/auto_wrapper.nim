import macros, strutils, os


type
  ExportProc = object
    name: string
    args: seq[string]

  NimRModule* = object
    file*: string # file that contains these procedures
    procs*: seq[ExportProc]

const dynLoadTmpl = """dyn.load("$#")"""
const fnTmpl = """

$name <- function($args) {
    return(.Call("$name", $args))
}

"""

proc serialize*(pt: NimRModule) {.compileTime.} =
  ## writes an R wrapper for the exported Nim procedures based on the given
  ## procedure table
  var res = dynLoadTmpl % ("lib" & pt.file & ".so")
  for p in pt.procs:
    res.add fnTmpl % ["name", p.name,
                      "args", p.args.join(", ")]
  writeFile(pt.file & ".R", res)

proc add*(pt: var NimRModule, name, params: NimNode) =
  ## Adds the given name and parameters to the proc table
  ## TODO: here we can add support for native Nim types & the wrapping in R code by
  ## checking the 2nd to last child of each nnkIdentDefs & 0th child of nnkFormalParams
  var nparams = newSeq[string]()
  for i in 1 ..< params.len:
    # start at 1 to skip child 0, return type
    let ch = params[i]
    for j in 0 ..< ch.len - 2: # each `nnkIdentDef` can contain multiple arguments, if
                               # they are the same type, e.g. `x, y: SEXP`. Always 0 to N-2
      nparams.add ch[j].toStrLit.strVal
  pt.procs.add ExportProc(name: name.toStrLit.strVal,
                          args: nparams)
