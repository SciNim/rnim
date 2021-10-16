import macros

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

macro getInnerType*(TT: typed): untyped =
  ## macro to get the subtype of a nested type by iterating
  ## the AST
  # traverse the AST
  let res = traverseTree(TT.getTypeInst)
  # assign symbol to result
  result = quote do:
    `res`
