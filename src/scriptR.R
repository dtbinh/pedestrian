

##
#Function that allow you to plot a number of pedestrian categorie (put them in toPLot) on a same graph
plotAllCategories<-function(data,toPlot=c("total","A","B","C","D","notOnSidewalk"),col=c("black","lightgreen","lightblue","orange","yellow","grey"),...){
	imax=max(data[,toPlot])
	plot(allData[,toPlot[1]],ylim=c(0,imax),type="n",xlab="time",ylab="Nb of Ind.",...)
	for(i in 1:length(toPlot)){
		points(data[,toPlot[i]],col=col[i])

	}
	legend("topleft",toPlot,fill=col)
}


