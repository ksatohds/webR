library(shiny)
library(rpart)
library(rpart.plot)
library(pROC)
library(partykit)
library(sysfonts)
library(showtext)

font_add("IPAexGothic", "ipaexg.ttf")
showtext_auto()
showtext_opts(dpi = 96)

# system() is not available in webR (Shinylive), so fc-cache is skipped there
if (.Platform$OS.type != "windows" && R.version$os != "emscripten") {
  dir.create("~/.fonts", showWarnings = FALSE, recursive = TRUE)
  file.copy("ipaexg.ttf", "~/.fonts/ipaexg.ttf", overwrite = TRUE)
  system("fc-cache -f ~/.fonts")
}

options(shiny.maxRequestSize = 30*1024^2)
shinyServer(function(input, output) {

  output$cp_display <- renderUI({
    cp_val <- round(10^input$numeric3, 6)
    p(paste0("cp = ", cp_val),
      style="margin-top:-12px; color:#666; font-size:90%;")
  })

  observeEvent(input$file1, {
    csv_file <- reactive(read.table(input$file1$datapath,
                                    header=T, sep=input$select0,
                                    stringsAsFactors=T))
    output$result1 = renderPrint({
      p <- ncol(csv_file())
      if(p<=100){print(str(csv_file()))
      }else{
        print("number of columns is over 100")
        print("head of columns...")
        print(str(csv_file()[,1:6]))
        print("tail of columns...")
        print(str(csv_file()[,(p-5):p]))
      }
    })
    
    output$plot1 = renderPlot({
      NULL
    })

    output$plot2 = renderPlot({
      NULL
    })
    
    output$plot3 = renderPlot({
      NULL
    })
    
    output$plot4 = renderPlot({
      NULL
    })

    output$plot5 = renderPlot({
      NULL
    })

    output$html1 = renderUI({ 
      selectInput("select1",
                  label ="", 
                  size=5,multiple=F,selectize=F,
                  choices = colnames(csv_file()),
                  selected=colnames(csv_file())[1])
    })
    output$html2 = renderUI({
      selectInput("checkbox1",
                  label ="variables", 
                  size=10,multiple=T,selectize=F,
                  choices = colnames(csv_file()),selected=F)
    })      
  })
  
  observeEvent(input$submit1, {
    csv_file <- reactive(read.table(input$file1$datapath,
                                    header=T, sep=input$select0,
                                    stringsAsFactors=T))
    
    req(input$select1)
    req(input$checkbox1)

    d1 <- subset(csv_file(),select=input$select1)

    if(input$checkbox0) d1[,1] <- as.factor(d1[,1])
    d2 <- subset(csv_file(),select=input$checkbox1)
    
    dna <- is.na(d2)
    index <-(colSums(dna)==nrow(d2))
    d2 <- d2[,!index]
    dall <- cbind(d1,d2)

    if(isolate(input$select5)<1){
      set.seed(123)
      psp <- as.numeric(isolate(input$select5))
      ind <- sample(2,nrow(dall),replace=T,
                    prob=c(psp,1-psp))
      table(ind)/length(ind)
      dtrain <- dall[ind==1,]
      dtest <- dall[ind==2,]
    }else{
      dtrain <- dall
      dtest <- NULL
    }

    formulast <- paste0(input$select1,"~.")
    yvalues <- unique(dtrain[,1])
    is.logistic <- length(yvalues)==2
    is.category <- !is.logistic & is.factor(dtrain[1,1])

    if(is.logistic|is.category){
      if(input$checkbox2)
        res <- rpart(formulast,dtrain,y=T,method="class",
                     control = rpart.control(
                       minbucket=isolate(input$numeric1),
                       maxdepth=isolate(input$numeric2),
                       cp=10^isolate(input$numeric3)
                     ))
      else
        res <- rpart(formulast,dtrain,y=T,method="class")
      
      fitted.values <- predict(res,type="prob")
      if(is.logistic){
        roc1 <- roc(dtrain[,1]~fitted.values[,2])
        
        youden <- roc1$specificities+roc1$sensitivities
        j.youden <- which(youden==max(youden))
        youdenval <- roc1$thresholds[j.youden]
        youdenval <- youdenval[1]
        closest.topleft <- (1-roc1$specificities)^2+(1-roc1$sensitivities)^2
        j.closest.topleft <- which(closest.topleft==min(closest.topleft))
        closest.topleftval<- roc1$thresholds[j.closest.topleft]
        closest.topleftval <- closest.topleftval[1]

      }  
      if(isolate(input$select5)<1)
        new.fitted.values <- predict(res,type="prob",newdata=dtest)
    }else{
      if(input$checkbox2)
        res <- rpart(formulast,dtrain,y=T,method="anova",
                     control = rpart.control(
                       minbucket=isolate(input$numeric1),
                       maxdepth=isolate(input$numeric2),
                       cp=10^isolate(input$numeric3)
                     ))
      else
        res <- rpart(formulast,dtrain,y=T,method="anova")
      
      fitted.values <- predict(res)
      observation <- dtrain[,1]
      r.squared <- cor(fitted.values,observation)^2
      sigma <- (sum((observation-fitted.values)^2)/length(observation))^0.5
      mae <- mean(abs(observation-fitted.values))
      if(isolate(input$select5)<1){
        new.fitted.values <- predict(res,newdata=dtest)
        new.observation <- dtest[,1]
        new.r.squared <- cor(new.fitted.values,new.observation)^2
        new.sigma <- (sum((new.observation-new.fitted.values)^2)/length(new.observation))^0.5
        new.mae <- mean(abs(new.observation-new.fitted.values))
      }
    }  

    output$plot0 = renderPlot({
      par(family="IPAexGothic")
      if(is.logistic|is.category){
        f1 <- table(dtrain[,1],useNA="ifany")
        mylabel1 <- paste0(names(f1),
                           " (",f1,", ",round(100*f1/sum(f1),1),"%)")
        par(mar=c(1,1,2.5,1))
        pie(f1,main=input$select1,clockwise=T,
            labels=mylabel1)
      }else{
        par(mar=c(2.5,2.5,2,1))
        hist(res$y,main=input$select1,xlab="")
      }  
    })
    
    output$plot1 = renderPlot({
      par(family="IPAexGothic")
      rpart.plot(res,
                 type=as.numeric(input$select41),
                 extra=as.numeric(input$select42))
    })
  
    res2 <- res
    res2$call$data <- dtrain
    party_obj <- as.party(res2)
    output$plot5 = renderPlot({
      plot(party_obj, gp = grid::gpar(fontfamily = "IPAexGothic"))
      grid::grid.force()
      paths <- grid::grid.grep("GRID.text", grep = TRUE, global = TRUE)
      for (p in paths) {
        tryCatch({
          g <- grid::grid.get(p)
          lbl <- g$label
          if (is.expression(lbl)) {
            lbl_str <- as.character(lbl)
            if (grepl(">=", lbl_str, fixed = TRUE)) {
              num <- trimws(sub(".*>=", "", lbl_str))
              grid::grid.edit(p, label = paste0(">= ", num))
            }
          }
        }, error = function(e) NULL)
      }
    })

    output$plot3 = renderPlot({
      par(mar=c(15,4,2,2),family="IPAexGothic")
      if (!is.null(res$variable.importance) && length(res$variable.importance) > 0) {
        barplot(res$variable.importance,las=3,main="importance")
      } else {
        plot.new()
        text(0.5,0.5,"No variable importance\n(tree has no splits)",cex=1.2)
      }
    })

    output$plot4 = renderPlot({
      par(family="IPAexGothic")
      plotcp(res)
    })

    output$plot2 = renderPlot({
      par(family="IPAexGothic")
      if(is.logistic|is.category){
        if(is.logistic){
          plot(1-roc1$specificities,roc1$sensitivities,type="l",
               xlab="1-specificities",ylab="sensitivities",main="",
              xlim=c(0,1),ylim=c(0,1),col=2,lwd=2)
          abline(a=0,b=1,lty=2,col="gray")

          points(1-roc1$specificities[j.youden],roc1$sensitivities[j.youden],pch=2)
          points(1-roc1$specificities[j.closest.topleft],
                 roc1$sensitivities[j.closest.topleft],pch=6)
          youdenst<- paste0("Youden Index=",round(youdenval,3))
          closest.topleftst<- paste0("Closest topleft=",
                                     round(closest.topleftval,3))
          legend(x=0.5,y=0.5,
                 legend=c(youdenst,closest.topleftst),
                 pch=c(2,6),title="optimal threshold",box.col="white")

          if(isolate(input$select5)==1){
            legendst<- paste0("AUC=",round(roc1$auc,3))
            legend("bottomright",legend=c(legendst),lty=1,lwd=3,col=2)
          }else{
            new.roc1 <- roc(dtest[,1]~new.fitted.values[,2])
            lines(1-new.roc1$specificities,new.roc1$sensitivities,col=3,lwd=2)
            legendst<- paste0(c("train: ","test : " ),
                              round(c(roc1$auc,new.roc1$auc),3))
            legend("bottomright",legend=legendst,lty=1,lwd=3,col=2:3,title="AUC")
          }  
        }else{
          predicted <- predict(res,type="class")
          observation <- dtrain[,1]
          f <- xtabs(~predicted+observation)
          nf <- rowSums(f)
          par(mar=c(15,4.5,2,0.5),family="IPAexGothic")
          barplot(100*t(f/nf),las=3,ylim=c(0,100),
                  col=1:ncol(f)+1,
                  xlab="",ylab="observation (%)",
                  main=paste0("Accuracy=",round(100*sum(diag(f))/sum(f),3),"%"),
                  legend=T,args.legend=list(bg="white",x="topleft"))
        }
      }else{
        mylim <- range(res$y,fitted.values)
        plot(fitted.values,res$y,
             xlim=mylim,ylim=mylim,
             xlab="fitted values",ylab="response",
             main="",col=2,pch=2
        )
        abline(a=0,b=1,lty=2,col="gray")
        if(isolate(input$select5)==1){
          legendst<- paste0("Multiple R-squared= ",round(r.squared,3))
          legend("bottomright",legend=c(legendst),pch=2,col=2)
        }else{
          points(new.fitted.values,dtest[,1],col=3,pch=6)
          legendst<- paste0(c("train: ","test : " ),
                            round(c(r.squared,new.r.squared),3))
          legend("bottomright",legend=legendst,pch=c(2,6),col=2:3,
                 title="Multiple R-squared")
        }  
      }
    })

    output$result0 = renderPrint({
      print(res)
    })

    output$result1 = renderPrint({
      print("--- whole data (nrow, ncol): ")
      print(dim(dall))
      print("--- training data (nrow, ncol): ")
      print(dim(dtrain))
      print(paste0("--- response: ",input$select1))
      if(is.logistic) print(table(dtrain[,1]))
        else print(summary(dtrain[,1]))
      if(is.logistic|is.category){
        print("--- confusion matrix")
        
        if(is.logistic){
          predicted <- 1*(fitted.values[,2]>=youdenval)
        }else predicted <- predict(res,type="class")
        
        observation <- dtrain[,1]
        f <- xtabs(~observation+predicted)
        print(f)
        if(is.logistic)
          print(paste0("prediction threshold by Youden Index= ",round(youdenval,3)))
        print(paste0("accuracy= ",round(100*sum(diag(f))/sum(f),3),"%"))
      }else{
        print("--- fitted values v.s. observation")
        print(paste0("Multiple R-squared: ",round(r.squared,5)))
        print(paste0("Residual standard error: ",round(sigma,5)))
        print(paste0("Mean absolute error: ",round(mae,5)))
      }  
    })
    
    output$result2 = renderPrint({
      if(isolate(input$select5)<1){
        print("--- test data (nrow, ncol): ")
        print(dim(dtest))
        print(paste0("--- response: ",input$select1))
        if(is.logistic) print(table(dtest[,1]))
        else print(summary(dtest[,1]))
        if(is.logistic|is.category){
          print("--- confusion matrix")

          if(is.logistic){
            predicted <- 1*(new.fitted.values[,2]>=youdenval)
          }else predicted <- predict(res,type="class",newdata=dtest)
          observation <- dtest[,1]

          f <- xtabs(~observation+predicted)
          print(f)
          print(paste0("accuracy= ",round(100*sum(diag(f))/sum(f),3),"%"))
        }else{
          print("--- fitted values v.s. observation")
          print(paste0("Multiple R-squared: ",round(new.r.squared,5)))
          print(paste0("Residual standard error: ",round(new.sigma,5)))
          print(paste0("Mean absolute error: ",round(new.mae,5)))
        }  
      }
    })
    
        
    fitted <- data.frame(dtrain,fitted.values)
    output$download1 = downloadHandler(
      filename = "train_CP932.csv",
      content = function(file) {
        write.csv(fitted,file,row.names=F,fileEncoding="CP932")
      })  
    
    if(isolate(input$select5)<1){
      new.fitted <- data.frame(dtest,new.fitted.values)
      output$download2 = downloadHandler(
        filename = "test_CP932.csv",
        content = function(file) {
          write.csv(new.fitted,file,row.names=F,fileEncoding="CP932")
        })
      output$download3 = downloadHandler(
        filename = "split_CP932.csv",
        content = function(file) {
          write.csv(ind,file,row.names=F,fileEncoding="CP932")
        })
    }

    output$downloadPlot0 <- downloadHandler(
      filename = "response.pdf",
      content = function(file) {
        pdf(file, width=7, height=7)
        par(family="IPAexGothic")
        if(is.logistic|is.category){
          f1 <- table(dtrain[,1],useNA="ifany")
          mylabel1 <- paste0(names(f1),
                             " (",f1,", ",round(100*f1/sum(f1),1),"%)")
          par(mar=c(1,1,2.5,1))
          pie(f1,main=input$select1,clockwise=T,labels=mylabel1)
        }else{
          par(mar=c(2.5,2.5,2,1))
          hist(res$y,main=input$select1,xlab="")
        }
        dev.off()
      }
    )

    output$downloadPlot1 <- downloadHandler(
      filename = "tree_rpart.pdf",
      content = function(file) {
        pdf(file, width=10, height=7)
        par(family="IPAexGothic")
        rpart.plot(res,
                   type=as.numeric(input$select41),
                   extra=as.numeric(input$select42))
        dev.off()
      }
    )

    output$downloadPlot2 <- downloadHandler(
      filename = "fitting.pdf",
      content = function(file) {
        pdf(file, width=7, height=7)
        par(family="IPAexGothic")
        if(is.logistic|is.category){
          if(is.logistic){
            plot(1-roc1$specificities,roc1$sensitivities,type="l",
                 xlab="1-specificities",ylab="sensitivities",main="",
                 xlim=c(0,1),ylim=c(0,1),col=2,lwd=2)
            abline(a=0,b=1,lty=2,col="gray")
            points(1-roc1$specificities[j.youden],roc1$sensitivities[j.youden],pch=2)
            points(1-roc1$specificities[j.closest.topleft],
                   roc1$sensitivities[j.closest.topleft],pch=6)
            youdenst <- paste0("Youden Index=",round(youdenval,3))
            closest.topleftst <- paste0("Closest topleft=",
                                        round(closest.topleftval,3))
            legend(x=0.5,y=0.5,
                   legend=c(youdenst,closest.topleftst),
                   pch=c(2,6),title="optimal threshold",box.col="white")
            if(isolate(input$select5)==1){
              legendst <- paste0("AUC=",round(roc1$auc,3))
              legend("bottomright",legend=c(legendst),lty=1,lwd=3,col=2)
            }else{
              new.roc1 <- roc(dtest[,1]~new.fitted.values[,2])
              lines(1-new.roc1$specificities,new.roc1$sensitivities,col=3,lwd=2)
              legendst <- paste0(c("train: ","test : "),
                                 round(c(roc1$auc,new.roc1$auc),3))
              legend("bottomright",legend=legendst,lty=1,lwd=3,col=2:3,title="AUC")
            }
          }else{
            predicted <- predict(res,type="class")
            observation <- dtrain[,1]
            f <- xtabs(~predicted+observation)
            nf <- rowSums(f)
            par(mar=c(15,4.5,2,0.5),family="IPAexGothic")
            barplot(100*t(f/nf),las=3,ylim=c(0,100),
                    col=1:ncol(f)+1,
                    xlab="",ylab="observation (%)",
                    main=paste0("Accuracy=",round(100*sum(diag(f))/sum(f),3),"%"),
                    legend=T,args.legend=list(bg="white",x="topleft"))
          }
        }else{
          mylim <- range(res$y,fitted.values)
          plot(fitted.values,res$y,
               xlim=mylim,ylim=mylim,
               xlab="fitted values",ylab="response",
               main="",col=2,pch=2)
          abline(a=0,b=1,lty=2,col="gray")
          if(isolate(input$select5)==1){
            legendst <- paste0("Multiple R-squared= ",round(r.squared,3))
            legend("bottomright",legend=c(legendst),pch=2,col=2)
          }else{
            points(new.fitted.values,dtest[,1],col=3,pch=6)
            legendst <- paste0(c("train: ","test : "),
                               round(c(r.squared,new.r.squared),3))
            legend("bottomright",legend=legendst,pch=c(2,6),col=2:3,
                   title="Multiple R-squared")
          }
        }
        dev.off()
      }
    )

    output$downloadPlot3 <- downloadHandler(
      filename = "importance.pdf",
      content = function(file) {
        pdf(file, width=10, height=7)
        par(mar=c(15,4,2,2),family="IPAexGothic")
        if (!is.null(res$variable.importance) && length(res$variable.importance) > 0) {
          barplot(res$variable.importance,las=3,main="importance")
        } else {
          plot.new()
          text(0.5,0.5,"No variable importance\n(tree has no splits)",cex=1.2)
        }
        dev.off()
      }
    )

    output$downloadPlot4 <- downloadHandler(
      filename = "complexity_parameter.pdf",
      content = function(file) {
        pdf(file, width=7, height=5)
        par(family="IPAexGothic")
        plotcp(res)
        dev.off()
      }
    )

    output$downloadPlot5 <- downloadHandler(
      filename = "tree_partykit.png",
      content = function(file) {
        showtext::showtext_opts(dpi = 150)
        png(file, width = 14 * 150, height = 8 * 150, res = 150)
        plot(party_obj, gp = grid::gpar(fontfamily = "IPAexGothic"))
        grid::grid.force()
        paths <- grid::grid.grep("GRID.text", grep = TRUE, global = TRUE)
        for (p in paths) {
          tryCatch({
            g <- grid::grid.get(p)
            lbl <- g$label
            if (is.expression(lbl)) {
              lbl_str <- as.character(lbl)
              if (grepl(">=", lbl_str, fixed = TRUE)) {
                num <- trimws(sub(".*>=", "", lbl_str))
                grid::grid.edit(p, label = paste0(">= ", num))
              }
            }
          }, error = function(e) NULL)
        }
        dev.off()
        showtext::showtext_opts(dpi = 96)
      }
    )
  })
  
})
