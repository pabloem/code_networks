# Coursera SNA optional Programming Project
# Author: Pablo Estrada

# load igraph
library(igraph)

# The files for this project exist in Pajek .NET format 
# as it was the easiest to generate using simple shell scripting
print("Input the file which contains the graph ->")
file_name <- readLines(n=1)

# The functionality to import Pajek type graphs in R is kind of sketchy.
# I imported the script-generated files into Gephi, and exported that graph from gephi
# to Pajek format again, just to make sure the format is more standardized, and does not
# give R any trouble.
git <- read.graph(file=file_name,format="pajek")

# Calculate the in/out degree distributions
outdegrees <- degree(git,mode="in")

indegrees <- degree(git,mode="out")

degrees <- degree(git,mode="all")

sprintf("The file that includes the most other files is \"%s\". It includes %d files", 
        V(git)$id[which.max(indegrees)], max(indegrees))

sprintf("The file that is included the most by other files is \"%s\". It is included %d times", 
        V(git)$id[which.max(outdegrees)], max(outdegrees))

plot(tabulate(indegrees))
plot(tabulate(outdegrees))
plot(tabulate(degrees))

source("http://tuvalu.santafe.edu/~aaronc/powerlaws/plfit.r")
a <- plfit(degrees)
if (a$D <= 0.05)
{
  print("The distribution of all the degrees in the given graph is power-law")
  sprintf("xmin is %.2f | alpha (the exponent) is %.2f",a$xmin,a$alpha)
} else {
  print("The degree distribution is not power-law, as the $D coefficient is over 0.05")
}

a <- plfit(outdegrees[outdegrees!=0])
if (a$D <= 0.05)
{
  print("The outdegree distribution in the given graph is power-law")
  sprintf("xmin is %.2f | alpha (the exponent) is %.2f",a$xmin,a$alpha)
} else {
  print("The outdegree distribution is not power-law, as the $D coefficient is over 0.05")
}

# plot(c((degrees[outdegrees==0])[order(indegrees[outdegrees==0],decreasing=TRUE)],(degrees[outdegrees!=0])[order(outdegrees[outdegrees!=0])]))

# I have the theory that the files in a software project can usually be considered of two types:
# # # 1. Service files. These files provide functionality. They provide functions and services that can be called by other files
# # # 2. Execution files. These files guide the execution path, and use functions and services provided by the service files.

## If this theory is true, there will be a set of files that are mostly included, and do not include many files; and another set 
## of files that mostly include other files, and are not included by many other files.

# Here we plot the outdegrees: The file inclusions made by other files. Files that are most included will be on the right,
# with a high value of Y
# par(mfcol=c(1,3)) ## UNCOMMENT THIS LINE TO PLOT THE INFORMATION OF ALL THREE GRAPHS ON THE SAME CANVAS
                    ## Then run the graph reading, outdegree and indegree calculations, and plotting functions for all three files
plot(
  c((outdegrees[outdegrees==0])[order(indegrees[outdegrees==0],decreasing=TRUE)],
    (outdegrees[outdegrees!=0])[order(outdegrees[outdegrees!=0])]),
  pch=15, col="blue ", type="b",
  main=paste("Service files & Execution files (",file_name,")"),
  xlab="Nodes on the graph",
  ylab="Indegree/Outdegree"
  )

# Now we add the indegrees: The file inclusions made by the file in question; ordered in the same way: Files that are least included
# will be on the left, and the most included will be on the right. According to my theory, the files on the left will also be the 
# files that include the most other files.
points(
  c((indegrees[outdegrees==0])[order(indegrees[outdegrees==0],decreasing=TRUE)],
    (indegrees[outdegrees!=0])[order(outdegrees[outdegrees!=0])]),
  pch=20 ,col="red"
  )
usr <- par("usr")
chw<-par()$cxy[1]
chh<-par()$cxy[2]

points(pch=15,col="blue",
       usr[1]+chw,usr[4]-chh)
points(pch=20,col="red",
       usr[1]+chw,usr[4]-2*chh)
text(usr[1]+chw,usr[4]+c(-chh,-2*chh),labels=c("outdegrees","indegrees"), pos=4)

# As we can see from the plot; the general trend is that files that are included many times don't include many other files, and
# the inverse is also true: Files that include many files are not really included by many other files.

# Now let's look at the community structure

# fastgreedy community finding algorithm
fc <- fastgreedy.community(as.undirected(git))

# community sizes
sizes(fc)

# Now we print a random sample of each of the communities, to see if it can be inferred what kind of files were added to the
# community.
for(i in 1:length(fc)){
  print(paste("Community number",i," size: ",sizes(fc)[i]," random sample:"))
  print(sample(V(git)$id[membership(fc)==i],size=if(sizes(fc)[i]>=6) 6 else sizes(fc)[i]))
  print("")
}


# Now we want to analyze the small-world effect in code networks, so we want to calculate the shortest path lengths in the networks
avg_sp <- average.path.length(as.undirected(git),directed=FALSE)
print(paste("The average shortest path is",avg_sp))
hist_sp <- path.length.hist(as.undirected(git),directed=FALSE)

# Now should plot the path length histogram
# par(mfcol=c(1,3)) ## UNCOMMENT THIS LINE TO PLOT THE INFORMATION OF ALL THREE GRAPHS ON THE SAME CANVAS
b<-barplot(hist_sp$res/sum(hist_sp$res), xaxt="s", names.arg=1:length(hist_sp$res),
     main=paste("Shortest path distribution (",file_name,")"),
     ylab="Frequency", xlab="Shortest path length")
text(x=b[,1],hist_sp$res/sum(hist_sp$res),pos=3,
     labels=paste(round(hist_sp$res/sum(hist_sp$res)*100,digits=2),"%",sep=""))

# Now follows the code to plot the average path lengths for all three projects in a lin-log scale
#plot(y=c(2.3159,2.5568,4.7614),x=c(70,258,2981),col="red",pch=20,type="b",lty=2,
#     main="Average path length vs file count",
#     xlab="File count (log)", ylab="Average path length",
#     log="x")