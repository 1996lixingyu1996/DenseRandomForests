## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----include=FALSE------------------------------------------------------------
library(randomForestSRC)
library(rio)
library(survival)
library(dplyr)

## -----------------------------------------------------------------------------
mtry_list = c(2, 3)
ntree = 500
nsplit = c(20, 30, 40) 
nodesize = c(50, 70, 100)
nodedepth = c(2, 3)
den_util = 3.5
weight_util = c(30, 40, 50)

## -----------------------------------------------------------------------------
para_list = base::expand.grid(mtry_list, ntree, nodesize, nodedepth, nsplit, den_util, weight_util)
colnames(para_list) = c("mtry", "ntree", "nodesize", "nodedepth", "nsplit", "den_util", "weight_util")
df = para_list

## ----eval = FALSE-------------------------------------------------------------
#  f_simulation <- function(i){
#    options(rf.cores=1, mc.cores = 1)
#  
#    study_id = "309"
#  
#    ### the path is used to save membership matrix
#    result_save_path = ""
#  
#    if(!dir.exists(result_save_path)){ dir.create(result_save_path)}
#  
#    result_folder_path = paste0(result_save_path, "/", study_id)
#    if(!dir.exists(result_folder_path)){ dir.create(result_folder_path)}
#  
#    ### load data
#    data(crc_adsl, package = "randomForestSRC")
#    dat <- base::subset(crc_adsl, crc_adsl$StudyID==study_id)
#    dat <- dat[!is.na(dat$B_ECOG),]
#    dat <- dat[!is.na(dat$KRAS),]
#    dat <- dat[!is.na(dat$AGE),]
#    dat$TRT <- as.factor(dat$TRT)
#    data <- dat[, c("SUBJID","OS","OSevent","KRAS", "AGE", "TRT", "B_ECOG", "ARM", "PFS", "PFSevent")]  # TRT equals ARM
#    train.data = data[, c("SUBJID", "OS", "OSevent", "KRAS", "AGE", "B_ECOG", "TRT", "PFS", "PFSevent","ARM")]
#  
#    train.data$TRT = ifelse(train.data$TRT == "FOLFOX alone", yes = 0, no = 1)
#    train.data$TRT = as.factor(train.data$TRT)
#    train.data$KRAS <- as.factor(train.data$KRAS)
#    train.data$B_ECOG <- as.factor(train.data$B_ECOG)
#    train.data = filter(train.data,B_ECOG == "1"| B_ECOG == "0")
#    train.data$B_ECOG <- as.factor(train.data$B_ECOG)
#    x_name = c("KRAS","B_ECOG", "AGE")
#  
#    df = para_list
#  
#    data.tmp = train.data
#  
#    # train model
#    para.mtry = df[i, "mtry"]
#    para.ntree = df[i, "ntree"]
#    para.nodesize = df[i, "nodesize"]
#    para.nodedepth = df[i, "nodedepth"]
#    para.nsplit = df[i, "nsplit"]
#    para.den_util = df[i, "den_util"]
#    para.weight_util = df[i, "weight_util"]
#    para.seed = 1
#    if(para.nodedepth == 0)
#    {
#      para.nodedepth = NULL
#    }
#      ## train random forests with different parameter set up
#      rf.object = tryCatch(expr = {rfsrc(Surv(OS, OSevent)~KRAS+B_ECOG+AGE,
#                                               data = data.tmp, ntree = para.ntree,
#                                               nodesize = para.nodesize,
#                                               nodedepth = para.nodedepth,
#                                               mtry=para.mtry,
#                                               nsplit = para.nsplit, splitrule = "custom5",
#                                               block.size = NULL, statistics = TRUE,
#                                               forest = TRUE, membership = TRUE,
#                                               weight_util = (para.weight_util/100),
#                                               den_util = para.den_util,
#                                               treatment = data.tmp$TRT,
#                                               xvar.wt = xvar_weight, var.used = "all.trees")},
#                                 error = function(e){0})
#  
#      if (is.list(rf.object)){
#        arg <- list(na.action="na.impute", prox.dist.type="all")
#        rf.object.predict <- predict.rfsrc(object=rf.object,
#                                                 newdata=data.tmp,
#                                                 na.action = arg$na.action,
#                                                 membership=TRUE, proximity = FALSE,
#                                                 treatment_flag = TRUE)
#        predict_membership = rf.object.predict$membership
#        membership_save_path = paste0(result_folder_path, "/",
#                                      "para_id_", i, "_mtry_", para.mtry,
#                                      "_ntree_", para.ntree, "_nodesize_",
#                                      para.nodesize, "_nsplit_",
#                                      para.nsplit, "para_weight_util_",
#                                      para.weight_util, "_nodedepth_",
#                                      para.nodedepth, ".csv")
#  
#        rio::export(predict_membership, membership_save_path)
#        base::rm(rf.object)
#        base::rm(rf.object.predict)
#        base::rm(predict_membership)
#        base::rm(membership_save_path)
#      }
#  
#    }

## ----eval=FALSE---------------------------------------------------------------
#  for (i in 1:dim(df)[1]){
#    f_simulation(i)
#  }

## ----eval=FALSE---------------------------------------------------------------
#  folder_path = ""
#  
#  membership = NULL
#  
#  ## combine all membership matrix
#  for (i in 1:dim(df)[1]){
#    para.mtry = df[i, "mtry"]
#    para.ntree = df[i, "ntree"]
#    para.nodesize = df[i, "nodesize"]
#    para.nodedepth = df[i, "nodedepth"]
#    para.nsplit = df[i, "nsplit"]
#    para.den_util = df[i, "den_util"]
#    para.weight_util = df[i, "weight_util"]
#    para.seed = 1
#    for (j in 1:3){
#      membership_save_path = paste0(folder_path, "/",
#                                    "para_id_", i, "_mtry_", para.mtry,
#                                    "_ntree_", para.ntree, "_nodesize_",
#                                    para.nodesize, "_nsplit_",
#                                    para.nsplit, "para_weight_util_",
#                                    para.weight_util, "_nodedepth_",
#                                    para.nodedepth, ".csv")
#  
#      membership_tmp = rio::import(membership_save_path)
#      membership = rbind.data.frame(membership, membership_tmp)
#    }
#  }

## ----eval=FALSE---------------------------------------------------------------
#  proximity = rfsrc_compute_proximity(membership = membership, inbag=NULL, oob='ALL')

## -----------------------------------------------------------------------------
data(proximity, package = "randomForestSRC")

## -----------------------------------------------------------------------------
study_id = "309"
data(crc_adsl, package = "randomForestSRC")
dat <- base::subset(crc_adsl, crc_adsl$StudyID==study_id)
dat <- dat[!is.na(dat$B_ECOG),]
dat <- dat[!is.na(dat$KRAS),]
dat <- dat[!is.na(dat$AGE),]
dat$TRT <- as.factor(dat$TRT)
data <- dat[, c("SUBJID","OS","OSevent","KRAS", "AGE", "TRT", "B_ECOG", "ARM", "PFS", "PFSevent")]  # TRT equals ARM
train.data = data[, c("SUBJID", "OS", "OSevent", "KRAS", "AGE", "B_ECOG", "TRT", "PFS", "PFSevent","ARM")]
  
train.data$TRT = ifelse(train.data$TRT == "FOLFOX alone", yes = 0, no = 1)
train.data$TRT = as.factor(train.data$TRT)
train.data$KRAS <- as.factor(train.data$KRAS)
train.data$B_ECOG <- as.factor(train.data$B_ECOG)
train.data = filter(train.data,B_ECOG == "1"| B_ECOG == "0")
train.data$B_ECOG <- as.factor(train.data$B_ECOG)
x_name = c("KRAS","B_ECOG", "AGE")
dat = train.data 

## -----------------------------------------------------------------------------

## transform proximity to distance matrix
distance = 1 - proximity
tsne_result = Rtsne::Rtsne(distance,dims=2,is_distance=TRUE,verbose=FALSE,
                               max_iter = 5000, theta = 0)

## K-Means Clustering
kmeans_result_2 = kmeans(tsne_result$Y, centers = 2, iter.max = 50,nstart = 30)
kmeans_result_3 = kmeans(tsne_result$Y, centers = 3, iter.max = 50,nstart = 30)
kmeans_result_4 = kmeans(tsne_result$Y, centers = 4, iter.max = 50,nstart = 30)
kmeans_result_5 = kmeans(tsne_result$Y, centers = 5, iter.max = 50,nstart = 30)

dat$kmeans2 = as.factor(kmeans_result_2$cluster)
dat$kmeans3 = as.factor(kmeans_result_3$cluster)
dat$kmeans4 = as.factor(kmeans_result_4$cluster)
dat$kmeans5 = as.factor(kmeans_result_5$cluster)

pval_flag = 2
result = list()

for (j in 2:5){
    x_name = c("B_ECOG","KRAS","AGE")
    c_name = paste0("kmeans",j)  
    profiles <- tree_fit(Y=dat[,c_name], X=dat[,x_name], seed=1234,maxdepth = 2)
    if(is.null(profiles)){
      next
    }
    for (k in 1:length(profiles$trees)){
      dat = predict_path(profiles$trees[[k]], newdata = dat)
      
      data_tmp = dat
      ## calculate p leaf 
      fit_surv3 = coxph(Surv(OS,OSevent)~TRT, data = data_tmp)
      fit_surv2 = coxph(Surv(OS,OSevent)~leaf*TRT, data = data_tmp)
      pval = as.numeric(na.omit(stats::anova(fit_surv2, fit_surv3)[[4]]))
      
      if(pval < pval_flag){
        pval_flag = pval
        result[[1]] = profiles
        result[[2]] = pval_flag
        result[[3]] = j
        result[[4]] = k
      }
    }
    
}

## -----------------------------------------------------------------------------
plot_profile(result[[1]]$trees[[result[[4]]]])

## -----------------------------------------------------------------------------
cat(result[[2]])

## -----------------------------------------------------------------------------
data("p_leaf_list", package = "randomForestSRC")

## -----------------------------------------------------------------------------
quantile(p_leaf_list,0.01)

