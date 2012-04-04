

##
#Function that allow you to plot a number of pedestrian categorie (put them in toPLot) on a same graph
plotAllCategories<-function(data,toPlot=c("total","A","B","C","D","notOnSidewalk"),col=c("black","lightgreen","lightblue","orange","yellow","grey"),...){
	imax=max(data[,toPlot])
	plot(data[,toPlot[1]],ylim=c(0,imax),type="n",xlab="time",ylab="Nb of Ind.",...)
	for(i in 1:length(toPlot)){
		points(data[,toPlot[i]],col=col[i])

	}
	legend("topleft",toPlot,fill=col)
}

#usefull to concatenate time series together
#in the column "col" of the array "data", value beetwen t and t+resolution will be merged together

concate<-function(data,resolution,col="time"){

	res=data
	res[,col] = res[,col] - res[,col]%%resolution	
	return(res)
	

}


tableAllCase<-function(data){
	res=c()
	mycol=c()
	myrow=c()
	for(s in unique(data$site)){
		myrow=c(myrow,s)
		newline=c()
		mycol=c()
		for(fx in sort(unique(data$feux))){
			for(z in sort(unique(data$legalx))){
				newline=cbind(newline,length(data[ data$feux == fx & data$legalx == z & data$site == s,1])/length(data[data$site == s,1]))
				mycol=c(mycol,paste(fx,z,sep="-"))
			}
		}
		colnames(newline)=mycol
		res=rbind(res,newline)
	}
	
	rownames(res)=myrow
	return(res)
}

myBarplot2<-function(data,beside=T,legend=T,main="Repartition des Differents types \n de traversées pour 4 carrefour et notre modèle",xlab="types de traversée",ylab="pourcentage d'individus",...){
library(gplots)

barplot2(data,beside=T,legend=T,main="Repartition des Differents types \n de traversées pour 4 carrefour et notre modèle",xlab="types de traversée",ylab="pourcentage d'individus",col=c(heat.colors(nrow(a)-1),"black"),...)


}


