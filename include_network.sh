#!/bin/sh
#This script should generate one file:
# code_network.net
# This is a .net Pajek format network file, with all the nodes and the
# edges obtained by recursively going into the directories and parsing
# all the include statements in the files.

# NODENAMES
# The NODENAMES file contains all the code files that include or are included
# by any other file. These will be used as the list of nodes
# The name of a node is the filename, without extension
# The nodenames file is deleted after generating the code_network.net file

# EDGES
# The EDGES file contains all the inclusions of files that could be found
# parsing through the directory. One edge is contained on every line, on
# the following form:
### node1:node2
# The previous example means that the file NODE1 includes file NODE2. This is
# an edge going out of NODE1, into NODE2
# The edges* files are deleted after generating the code_network.net file

echo "Going to generate the node and edge list of the C codebase in $PWD"

#1. GET ALL THE NODES THAT ARE TO BE INCLUDED. 
#These are the file names without extension
# To do this, we get all the files that have the #include pattern at least once
# and add their names to the node list.
# This step gets only the filenames that include at least one other file.
# This step does not get the filenames of files that are included. This will be
# done at a later point.

grep '^\ *#include' -irl * | sed 's/\..*//' | sort | uniq >  nodenames_1
#THIS assumes that directories do not contain dots as part of their names

#2. GET ALL THE EDGES THAT ARE TO BE INCLUDED
# This exposes all the includes that are happening. These are edges.
# There are code files that implement routines that are 'prototyped' in header 
# files. We are going to make these files a single node by removing the 
# extension of the files.
#"

grep '^#include' -sr * | sed 's/\/\*.*//' |sed 's/\t/ /' | sed 's/:#include\ *[\"\<\ ]/:/' | sed 's/:\.\//:/' |sed 's/\..*:/\ /' | sed 's/\(^.\)\.\//\1/' | sed 's/\(\.\.\/\)\1*//' | sed 's/[\.\>\"].*//' | sort | uniq > edges_1

#3. WE ALSO NEED TO ADD THE FILES THAT ARE INCLUDED BUT DON'T INCLUDE ANYBODY
# The following command prints the list of files that have been included into a
# temporary file, and we then get the missing nodes.
cat edges_1 | sed 's/^.*\ //' | sort | uniq > temporaryfile

# Now we add the difference between files including and files included but 
# not including to the nodenames file
fgrep -x -f nodenames_1 -v temporaryfile >> nodenames_1

# Finally, just for formatting, sort the nodenames file
sort nodenames_1 | nl > nodenames
echo "Node names available in file 'nodenames'"

#Remove the temporary files!
rm temporaryfile nodenames_1 

#4. FINALLY, WE GENERATE A .NET FILE WITH THE WHOLE NETWORK
# To write the edges, we substitute filenames with their corresponding node number
# using awk and the nodenames file
export a=`cat nodenames | wc -l`
echo "*Vertices $a" > code_network.net
cat nodenames >> code_network.net
export a=`cat edges_1 | wc -l`
echo "*Edges $a" >> code_network.net
awk 'NR==FNR{a[$2]=$1;next}{$1=a[$1];}1' nodenames edges_1 > edges_2
awk 'NR==FNR{a[$2]=$1;next}{$2=a[$2];}1' nodenames edges_2 > edges_3
cat edges_3 | sed s/$/\ 1/ | sed s/^/\ \ / >> code_network.net

rm edges* nodenames
