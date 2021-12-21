import rnim
# set up the R environment
let R = setupR()
# source the R file
R.source("examples/foo_README.R")
# call the procedure and check it works
doAssert R.hello("User").to(string) == "Hello User"
