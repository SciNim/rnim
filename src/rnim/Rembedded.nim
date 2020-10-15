##
##   R : A Computer Language for Statistical Data Analysis
##   Copyright (C) 2006-2016  The R Core Team.
##
##   This program is free software; you can redistribute it and/or modify
##   it under the terms of the GNU General Public License as published by
##   the Free Software Foundation; either version 2 of the License, or
##   (at your option) any later version.
##
##   This program is distributed in the hope that it will be useful,
##   but WITHOUT ANY WARRANTY; without even the implied warranty of
##   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##   GNU General Public License for more details.
##
##   You should have received a copy of the GNU General Public License
##   along with this program; if not, a copy is available at
##   https://www.R-project.org/Licenses/
##
##  A header for use with alternative front-ends. Not formally part of
##  the API so subject to change without notice.

import Rext, Rinternals

proc Rf_initEmbeddedR*(argc: cint; argv: ptr cstring): cint {.
    importc: "Rf_initEmbeddedR", dynlib: libname.}
proc Rf_endEmbeddedR*(fatal: cint) {.importc: "Rf_endEmbeddedR",
                                  dynlib: libname.}
##  From here on down can be helpful in writing tailored startup and
##    termination code

# when not defined(LibExtern):
proc Rf_initialize_R*(ac: cint; av: cstringArray): cint {.importc: "Rf_initialize_R",
    dynlib: libname.}
proc setup_Rmainloop*() {.importc: "setup_Rmainloop", dynlib: libname.}
proc R_ReplDLLinit*() {.importc: "R_ReplDLLinit", dynlib: libname.}
proc R_ReplDLLdo1*(): cint {.importc: "R_ReplDLLdo1", dynlib: libname.}
proc R_setStartTime*() {.importc: "R_setStartTime", dynlib: libname.}
proc R_RunExitFinalizers*() {.importc: "R_RunExitFinalizers", dynlib: libname.}
proc CleanEd*() {.importc: "CleanEd", dynlib: libname.}
proc Rf_KillAllDevices*() {.importc: "Rf_KillAllDevices", dynlib: libname.}
var R_DirtyImage* {.importc: "R_DirtyImage", dynlib: libname.}: cint

proc R_CleanTempDir*() {.importc: "R_CleanTempDir", dynlib: libname.}
var R_TempDir* {.importc: "R_TempDir", dynlib: libname.}: cstring

proc R_SaveGlobalEnv*() {.importc: "R_SaveGlobalEnv", dynlib: libname.}
when defined(Windows):
  proc getDLLVersion*(): cstring {.importc: "getDLLVersion", dynlib: libname.}
  proc getRUser*(): cstring {.importc: "getRUser", dynlib: libname.}
  proc get_R_HOME*(): cstring {.importc: "get_R_HOME", dynlib: libname.}
  proc setup_term_ui*() {.importc: "setup_term_ui", dynlib: libname.}
  var UserBreak* {.importc: "UserBreak", dynlib: libname.}: cint
  var AllDevicesKilled* {.importc: "AllDevicesKilled", dynlib: libname.}: Rboolean
  proc editorcleanall*() {.importc: "editorcleanall", dynlib: libname.}
  proc GA_initapp*(a1: cint; a2: cstringArray): cint {.importc: "GA_initapp",
      dynlib: libname.}
  proc GA_appcleanup*() {.importc: "GA_appcleanup", dynlib: libname.}
  proc readconsolecfg*() {.importc: "readconsolecfg", dynlib: libname.}
else:
  proc fpu_setup*(start: Rboolean) {.importc: "fpu_setup", dynlib: libname.}
