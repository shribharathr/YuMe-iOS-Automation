#!/bin/sh
cloc --by-file --xml -out=Build/cloc.xml YuMeZISTestApp
xsltproc Utils/Sloccount-format.xls Build/cloc.xml > Build/cloccount.sc