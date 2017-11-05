#!/bin/awk

BEGIN {
  split(cols,out,",")
}
NR==1 {
  for (i=1; i<=NF; i++)
    ix[$i] = i
}
NR>1 {
  for (i in out)
    printf "%s,", $ix[out[i]]
  print ""
}
