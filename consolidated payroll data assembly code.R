#################################################
#### consolidated payroll data assembly.R #######
#################################################

remove(list=ls()) #clear memory

library(readxl) #call package for reading excel files

#setwd("C:/Users/jherndon/Desktop/XXXX") #point R to temporary folder

###############################################################################
#Overall: download & merge the data, then add columns, expandeding as needed ##
###############################################################################

#################################
## Merge Data ###################
#################################

#change working directory to folder with all files
setwd("C:/Users/jherndon/Desktop/XXXX/XXXX")

files <- list.files()

#setting up first row to merge with files
syd <- data.frame(matrix(0,nrow = 0,ncol=18))

#loop to download files and merge data by row

for(i in 1:length(files)){
  #i <- 7
  sheet_1 <- read_excel(files[i], sheet = 1) #extracting pay and P/E date from sheet 1
  
  pay_date <- as.character(sheet_1[4,2])
  p_e_date <- as.character(sheet_1[5,2])
  
  remove(sheet_1)
  
  sheet_syd <- read_excel(files[i], sheet = 2) #pulling data from sheet 2
  
  #adding dates
  sheet_syd$`Pay Date` <- pay_date 
  sheet_syd$`P/E Date` <- p_e_date
  
  #identifying KS1 or SYD
  if(grepl("SYD",files[i])){ 
    sheet_syd$'Data Source' <- "SYD"
  }else  sheet_syd$'Data Source' <- "KS1"
  
  sheet_syd$file <- files[i]
  
  syd <- rbind(syd,sheet_syd)
}


#drop objects no longer in use
remove(sheet_syd)
remove(files)
remove(pay_date)
remove(p_e_date)

#removing rows by what's in the 1st column
syd <- syd[!grepl("Paid-In Department", syd$Personnel),]
syd <- syd[!grepl("Dept. Total", syd$Personnel),]
syd <- syd[!grepl("Hours Analysis", syd$Personnel),]
syd <- syd[!grepl("Earnings Analysis", syd$Personnel),]
syd <- syd[!grepl("Memo Analysis", syd$Personnel),]
syd <- syd[!grepl("Voluntary Ded. Analysis", syd$Personnel),]
syd <- syd[!grepl("Statutory Ded. Analysis", syd$Personnel),]
syd <- syd[is.na(syd$Personnel)==FALSE,]
#remove a rows if a leter is in the overtime hours cell
syd <- syd[!grepl("[A-Z]",syd$...3),]

############################################
#adding names to lines without them ########
############################################

for(i in 2:nrow(syd)){
  #i <- 3
  if(startsWith(syd$Personnel[i],"W-In Dept:")){
    loop_name <- strex::str_before_nth(syd$Personnel[i-1],"\n",2)
    syd$Personnel[i] <-  paste0(loop_name, "\n",syd$Personnel[i])
  }
}

###################
#name the columns #
###################

colnames(syd) <- c("Personnel",
                   "Hours Reg","Hours OT", "Hours H 3/4",
                   "Earnings Reg", "Earnings OT","Earnings E 3/4", "Earnings E5",
                   "Gross", 
                   "Stat Deduc Fed", "Stat Deduc State/Local", "Vol Deduc",
                   "Net Pay", "Memos",
                   "Pay Date", "P/E Date","Data Source","file")

#full name column

syd$Full_name <- NA

for(i in 1:nrow(syd)){
  #i <- 1
  syd$Full_name[i] <-   strex::str_before_nth(syd$Personnel[i],"\n",1)
}


#temporary files save
#setwd("C:/Users/jherndon/Desktop/XXX")
#save(syd,file = "syd.RData")

###############################################
#Breaking down the "Personnel" cell ###########
###############################################

add_cols_6 <- seq(ncol(syd)+1,ncol(syd)+6)
syd[,add_cols_6] <- NA


colnames(syd)[add_cols_6] <- c("Last","First and Middle","File","W-In Dept.","H Dept","Rate")

for(i in 1:nrow(syd)){
  #i <- 1
  loop_cell <- strsplit(syd$Personnel[i],"\n") #break apart what's in the cell by the "\n" , which is how R reports line breaks
  
  syd$Last[i] <- gsub(",.*","",loop_cell[[1]][1])
  syd$`First and Middle`[i] <- gsub(".*, ","",loop_cell[[1]][1])
  
  syd$File[i] <- gsub(".*File #:     ","",loop_cell[[1]][2])
  syd$`W-In Dept.`[i] <- gsub(".*W-In Dept:","",loop_cell[[1]][3]) 
  syd$`H Dept`[i] <- gsub(".*H Dept:","",loop_cell[[1]][4])
  syd$Rate[i] <- gsub(".*Rate:","",loop_cell[[1]][5])
}


#save(syd,file = "syd.RData")


##############################
#repeating hours columns #####
##############################


syd$hours_reg <- NA
syd$hours_ot <- NA

syd$hours_reg <- syd$`Hours Reg`
syd$hours_ot <- syd$`Hours OT`

##########################
#extra columns for H 3/4 #
##########################

#adding columns
add_cols_2 <- seq(ncol(syd)+1,ncol(syd)+2)
syd[,add_cols_2] <- NA
colnames(syd)[add_cols_2] <- c("Hours H 3/4 Code", "Hours H 3/4 Amount")

#break apart by looking for the " " space

for(i in 1:nrow(syd)){
  #i <- 2
  if(is.na(syd$`Hours H 3/4`[i])==FALSE){
    syd$`Hours H 3/4 Code`[i] <- gsub("   .*","",syd$`Hours H 3/4`[i])
    syd$`Hours H 3/4 Amount`[i] <- gsub(".*   ","",syd$`Hours H 3/4`[i])
  }
}


#save(syd,file = "syd.RData")

##############################################################
#repeating columns for "simple"  (numerical only) earnings ###
##############################################################

syd$earnings_reg <- syd$`Earnings Reg`
syd$earngs_ot <- syd$`Earnings OT`

#################################
#extra columns for Earnings 3/4 #
#################################

#adding columns
add_cols_2 <- seq(ncol(syd)+1,ncol(syd)+2)
syd[,add_cols_2] <- NA
colnames(syd)[add_cols_2] <- c("Earnings H 3/4 Code", "Earnings H 3/4 Amount")


#break apart by looking for the " " space

for(i in 1:nrow(syd)){
  #i <- 2
  if(is.na(syd$`Earnings E 3/4`[i])==FALSE){
    syd$`Earnings H 3/4 Code`[i] <- gsub("   .*","",syd$`Earnings E 3/4`[i])
    syd$`Earnings H 3/4 Amount`[i] <- gsub(".*   ","",syd$`Earnings E 3/4`[i])
  }
}


#save(syd,file = "syd.RData")

##################################
## Adding E5 columns ##############
###################################
add_cols_2 <- seq(ncol(syd)+1,ncol(syd)+2)
syd[,add_cols_2] <- NA

#break apart by looking for the " " space

colnames(syd)[add_cols_2] <- c("Earnings E5 Code", "Earnings E 5 Amount")

for(i in 1:nrow(syd)){
  #i <- 2
  if(is.na(syd$`Earnings E5`[i])==FALSE){
    syd$`Earnings E5 Code`[i] <- gsub("   .*","",syd$`Earnings E5`[i])
    syd$`Earnings E 5 Amount`[i] <- gsub(".*   ","",syd$`Earnings E5`[i])
  }
}



syd$gross <- syd$Gross

save(syd,file = "syd.RData")


#############################################################
### break up federal deductions #############################
#############################################################

#syd$filler <- NA #done to make sure that the evens & odss line up

#look for total number of \n  or spaces to find the max
look <- as.data.frame(syd$`Stat Deduc Fed`)
look$count <- NA
for(i in 1:nrow(look)){
  #i <- 1
  look[i,2] <- stringr::str_count(look[i,1], pattern = "\n") #" " or "\n"
}

#the first three letters represent the code for each
#max of 3 rows, so we need to add 6 columns

add_cols_6 <- seq(ncol(syd)+1,ncol(syd)+6)
syd[,add_cols_6] <- ""

#careful:  verify if it starts odd or even!!!!!
odd <- seq(from=add_cols_6[1], to =add_cols_6[length(add_cols_6)-1] , by=2)
even <- seq(from=add_cols_6[2], to = add_cols_6[length(add_cols_6)], by=2)

#name columns
for(i in 1:length(odd)){
  #i <- 1
  colnames(syd)[odd[i]] <- paste0("Fed Cat ", i)
}

for(i in 1:length(even)){
  #i <- 1
  colnames(syd)[even[i]] <- paste0("Fed Qty ", i)
}

#for each row, break up, then look to distinguish script from amount

for(i in 1:nrow(syd)){
  # i <- 12566
  loop_cell <- strsplit(syd$`Stat Deduc Fed`[i],"\n")
  
  
  for(j in 1:length(loop_cell[[1]])){
    #j <- 1
    #description
    type <- gsub("  .*","",loop_cell[[1]][j])
    col <- odd[j]
    syd[i,col] <- type
    
    #number
    amount <- gsub(".*  ","",loop_cell[[1]][j])
    
    #checking for negative numbers, listed as (XXX) instead of -XXX#
    if(is.na(amount)==FALSE&
       substr(amount,1,1)=="("){
      amount <- substr(amount,2,nchar(amount)-1)
      amount <- paste0("-",amount)
    }
    
    amount <- gsub(",","",amount)
    syd[i,even[j]] <- amount
  }
}

#save(syd,file = "syd.RData")

###########################################################
### break up state deductions ############################
###########################################################


#look for total number of \n  or spaces to find the max
look <- as.data.frame(syd$`Stat Deduc State/Local`)
look$count <- NA
for(i in 1:nrow(look)){
  #i <- 1
  look[i,2] <- stringr::str_count(look[i,1], pattern = "\n") #" " or "\n"
}

#the first three letters represent the code for each
#max of 5 rows, so we need to add 10 columns

add_cols_10 <- seq(ncol(syd)+1,ncol(syd)+10)
syd[,add_cols_10] <- ""

#careful:  verify if it starts odd or even!!!!!
odd <- seq(from=add_cols_10[1], to =add_cols_10[length(add_cols_10)-1] , by=2)
even <- seq(from=add_cols_10[2], to = add_cols_10[length(add_cols_10)], by=2)

for(i in 1:length(odd)){
  #i <- 1
  colnames(syd)[odd[i]] <- paste0("State_Local Cat ", i)
}

for(i in 1:length(even)){
  #i <- 1
  colnames(syd)[even[i]] <- paste0("State_Local Qty ", i)
}

#for each row, break up, then look to distinguish script from amount

for(i in 1:nrow(syd)){#nrow(syd)
  # i <- 1
  loop_cell <- strsplit(syd$`Stat Deduc State/Local`[i],"\n")
  
  
  for(j in 1:length(loop_cell[[1]])){
    #j <- 1
    #description
    type <- strex::str_before_nth(loop_cell[[1]][j], "  ", 2)
    col <- odd[j]
    syd[i,col] <- type
    
    #number
    amount <- strex::str_after_nth(loop_cell[[1]][j], "  ", 2)
    #negative numbers#
    if(is.na(amount)==FALSE&
       substr(amount,1,1)=="("){
      amount <- substr(amount,2,nchar(amount)-1)
      amount <- paste0("-",amount)
    }
    
    amount <- gsub(",","",amount)
    syd[i,even[j]] <- amount
  }
}

#save(syd,file = "syd.RData")

#############################################
## Break up Voluntary Deductions ############
#############################################

#look for total number of \n  or spaces to find the max
look <- as.data.frame(syd$`Vol Deduc`)
look$count <- NA
for(i in 1:nrow(look)){
  #i <- 1
  look[i,2] <- stringr::str_count(look[i,1], pattern = "\n") #" " or "\n"
}

#the first three letters represent the code for each
#max of 20 rows, so we need to add 40 columns
add_cols_40 <- seq(ncol(syd)+1,ncol(syd)+40)
syd[,add_cols_40] <- ""

#careful:  verify if it starts odd or even!!!!!
odd <- seq(from=add_cols_40[1], to =add_cols_40[length(add_cols_40)-1] , by=2)
even <- seq(from=add_cols_40[2], to = add_cols_40[length(add_cols_40)], by=2)

for(i in 1:length(odd)){
  #i <- 1
  colnames(syd)[odd[i]] <- paste0("Vol Cat ", i)
}

for(i in 1:length(even)){
  #i <- 1
  colnames(syd)[even[i]] <- paste0("Vol Qty ", i)
}

#for each row, break up, then look to distinguish script from 

for(i in 1:nrow(syd)){
  # i <- 12566
  loop_cell <- strsplit(syd$`Vol Deduc`[i],"\n")
  
  
  for(j in 1:length(loop_cell[[1]])){
    #j <- 1
    #description
    type <- gsub("   .*","",loop_cell[[1]][j])
    col <- odd[j]
    syd[i,col] <- type
    #number
    amount <- gsub(".*   ","",loop_cell[[1]][j])
    #negatives#
    if(is.na(amount)==FALSE&
       substr(amount,1,1)=="("){
      amount <- substr(amount,2,nchar(amount)-1)
      amount <- paste0("-",amount)
    }
    
    amount <- gsub(",","",amount)
    syd[i,even[j]] <- amount
  }
}

#save(syd,file = "syd.RData")

###########################################################
####### news columns for total deductions #################
###########################################################

add_cols_3 <- seq(ncol(syd)+1,ncol(syd)+3)
syd[,add_cols_3] <- NA


colnames(syd)[add_cols_3] <- c("Total Federal Deductions", "Total State & Local Deductions",
                               "Total Voluntary Deductions")

for(i in 1:nrow(syd)){
  #i <- 27
  
  
  #break cell into line, extract the number at the end of the line,
  #remove commas, change to number, add for entire cell then assign "total"
  #for that type
  
  #note: we create & use the same "loop_cell" object 3 times
  loop_cell <- strsplit(syd$`Stat Deduc Fed`[i],"\n")
  
  sum <- 0
  for(j in 1:length(loop_cell[[1]])){
    #j <- 27
    amount <- gsub(".*  ","",loop_cell[[1]][j])
    #new#
    if(is.na(amount)==FALSE&
       substr(amount,1,1)=="("){
      amount <- substr(amount,2,nchar(amount)-1)
      amount <- paste0("-",amount)
    }
    
    #end new#  
    amount <- gsub(",","",amount)
    sum <- sum + as.numeric(amount)
  }
  
  syd$`Total Federal Deductions`[i] <- sum
  
  #note: we create & use the same "loop_cell" object 3 times
  loop_cell <- strsplit(syd$`Stat Deduc State/Local`[i],"\n")
  
  sum <- 0
  for(j in 1:length(loop_cell[[1]])){
    #j <- 1
    amount <- gsub(".*  ","",loop_cell[[1]][j])
    #new#
    if(is.na(amount)==FALSE&
       substr(amount,1,1)=="("){
      amount <- substr(amount,2,nchar(amount)-1)
      amount <- paste0("-",amount)
    }
    
    #end new#  
    amount <- gsub(",","",amount)
    sum <- sum + as.numeric(amount)
  }
  
  syd$`Total State & Local Deductions`[i] <- sum
  
  #note: we create & use the same "loop_cell" object 3 times
  loop_cell <- strsplit(syd$`Vol Deduc`[i],"\n")
  
  sum <- 0
  for(j in 1:length(loop_cell[[1]])){
    #j <- 1
    amount <- gsub(".*   ","",loop_cell[[1]][j])
    #new#
    if(is.na(amount)==FALSE&
       substr(amount,1,1)=="("){
      amount <- substr(amount,2,nchar(amount)-1)
      amount <- paste0("-",amount)
    }
    
    #end new#  
    amount <- gsub(",","",amount)
    sum <- sum + as.numeric(amount)
  }
  
  syd$`Total Voluntary Deductions`[i] <- sum
  
}


#save(syd,file = "syd.RData")



add_cols_1 <- seq(ncol(syd)+1,ncol(syd)+1)
syd[,add_cols_1] <- NA
colnames(syd)[add_cols_1] <- c("Net Pay Amount")

net_pay_summary <- as.data.frame(table(syd$`Net Pay`))


for(i in 1:nrow(syd)){
  
  
  if(is.na(syd$`Net Pay`[i])==FALSE &
     substr(syd$`Net Pay`[i],1,6)=="Check#"){ #looks at first 6 characters
    #syd$`Net Pay Amount`[i] <- 1
    #remove "extra" characters
    syd$`Net Pay Amount`[i] <- substr(syd$`Net Pay`[i], 8, nchar(syd$`Net Pay`[i]))  
    syd$`Net Pay Amount`[i] <- gsub(" ", "",syd$`Net Pay Amount`[i])
    syd$`Net Pay Amount`[i] <- gsub("\n", "",syd$`Net Pay Amount`[i])#new
    syd$`Net Pay Amount`[i] <- gsub(",", "",syd$`Net Pay Amount`[i])#new
    syd$`Net Pay Amount`[i] <- gsub("*", "",syd$`Net Pay Amount`[i])#new
  }
  
  if(is.na(syd$`Net Pay`[i])==FALSE &
     substr(syd$`Net Pay`[i],1,6)=="Adjust"){
    
    #syd$`Net Pay Amount`[i] <- 1
    syd$`Net Pay Amount`[i] <- -1*as.numeric(
      stringr::str_extract(string = syd$`Net Pay`[i], pattern = "(?<=\\().*(?=\\))"))
    #remove empty space
    
  }
  
  
}

syd$`Net Pay Amount` <- gsub("^\\*", "", syd$`Net Pay Amount`) #remove "*" from some entries
syd$`Net Pay Amount` <- gsub("^\\*", "", syd$`Net Pay Amount`) #remove "*" from some entries

#source for code to pull info out of parentheses
#https://community.rstudio.com/t/extract-text-between-brakets/43448/5

save(syd,file = "syd.RData")

#############################################
## Break up Notes ###########################
#############################################

#look for total number of \n  or spaces to find the max
look <- as.data.frame(syd$Memos)
look$count <- NA
for(i in 1:nrow(look)){
  #i <- 1
  look[i,2] <- stringr::str_count(look[i,1], pattern = "\n") #" " or "\n"
}

#max of 12 rows, so we need to add 12 columns (one memo per line)
add_cols_12 <- seq(ncol(syd)+1,ncol(syd)+12)
syd[,add_cols_12] <- ""


for(i in 1:length(add_cols_12)){
  #i <- 1
  colnames(syd)[add_cols_12[i]] <- paste0("Memo ",i)
}


for(i in 1:nrow(syd)){#nrow(syd)
  #i <- 1
  loop_cell <- strsplit(syd$Memos[i],"\n")
  
  for(j in 1:length(loop_cell[[1]])){
    syd[i,add_cols_12[j]] <- loop_cell[[1]][j] 
  }
  
  
}


#save(syd,file = "syd.RData")


#Note: each of these secitons uses the same code/logic/order of operations to 
#generate and populate the new columns

###################################
#federal deductions ###############
###################################

#adding a columns for every unique federal deduction
#first by fiding all the unique types, then creates & populating a 
#column for each

fed_cats <- syd[,c("Fed Cat 1","Fed Cat 2","Fed Cat 3")]
fed_unique <- as.data.frame(unique(fed_cats[,1]))

for(i in 2:ncol(fed_cats)){
  loop_unique <- as.data.frame(unique(fed_cats[,i]))
  colnames(loop_unique) <- colnames(fed_unique)
  fed_unique <- rbind(fed_unique,loop_unique)
}

fed_unique <- unique(fed_unique)
colnames(fed_unique)[1] <- "col_1"
fed_unique <- fed_unique[is.na(fed_unique$col_1)==FALSE,]
fed_unique <- as.data.frame(fed_unique)
fed_unique <- fed_unique[fed_unique$fed_unique!="",]

add_cols <- length(fed_unique)

#add and name new columns
new_cols <- seq(ncol(syd)+1,ncol(syd)+add_cols)
syd[,new_cols] <- ""

for(i in 1:length(new_cols)){
  #i <- 1
  col_name <- paste0("Total ",fed_unique[i])
  colnames(syd)[new_cols[i]] <- col_name
}

source_cols <- c(37,39,41) #double-check this to verfiy it's the correct columns

colnames(syd)

#loop by row, then over each "source" column... where a match is found, takes value to the
#appropraite column with only that type of deduction

for(i in 1:nrow(syd)){#nrow(syd)
  # i <- 1
  
  for(j in 1:length(source_cols)){
    #j <- 15
    code <- syd[i,source_cols[j]]
    
    if(code!="" & is.na(code)==FALSE){
      col <- match(code,fed_unique)
      syd[i,new_cols[col]] <- syd[i,source_cols[j]+1]
    }
  }
  
  print(i)
}

#data.table::fwrite(syd,file = "testing.csv")


###########################################
#state and local deductions ###############
###########################################

#changing as little code as possible

fed_cats <- syd[,c("State_Local Cat 1" ,"State_Local Cat 2" ,"State_Local Cat 3" ,
                   "State_Local Cat 4" ,"State_Local Cat 5" )] #changed
fed_unique <- as.data.frame(unique(fed_cats[,1]))

for(i in 2:ncol(fed_cats)){
  loop_unique <- as.data.frame(unique(fed_cats[,i]))
  colnames(loop_unique) <- colnames(fed_unique)
  fed_unique <- rbind(fed_unique,loop_unique)
}

fed_unique <- unique(fed_unique)
colnames(fed_unique)[1] <- "col_1"
fed_unique <- fed_unique[is.na(fed_unique$col_1)==FALSE,] #check the col name!
fed_unique <- as.data.frame(fed_unique)
fed_unique <- fed_unique[fed_unique$fed_unique!="",]

add_cols <- length(fed_unique)

#add and name new columns
new_cols <- seq(ncol(syd)+1,ncol(syd)+add_cols)
syd[,new_cols] <- ""

for(i in 1:length(new_cols)){
  #i <- 1
  col_name <- paste0("Total ",fed_unique[i])
  colnames(syd)[new_cols[i]] <- col_name
}
colnames(syd)

source_cols <- seq(from=43, to=51, by=2) #changed... verify!.. source: the code, not the amount

for(i in 1:nrow(syd)){#nrow(syd)
  # i <- 1
  
  for(j in 1:length(source_cols)){
    #j <- 15
    code <- syd[i,source_cols[j]]
    
    if(code!="" & is.na(code)==FALSE){
      col <- match(code,fed_unique)
      syd[i,new_cols[col]] <- syd[i,source_cols[j]+1]
    }
  }
  
  print(i)
}

#data.table::fwrite(syd,file = "testing.csv")


###########################################
#voluntary  deductions       ##############
###########################################

#changing as little code as possible

fed_cats <- syd[,c("Vol Cat 1","Vol Cat 2","Vol Cat 3","Vol Cat 4","Vol Cat 5","Vol Cat 6","Vol Cat 7",
                   "Vol Cat 8","Vol Cat 9","Vol Cat 10","Vol Cat 11","Vol Cat 12","Vol Cat 13","Vol Cat 14",
                   "Vol Cat 15","Vol Cat 16","Vol Cat 17","Vol Cat 18","Vol Cat 19", "Vol Cat 20")] #changed

fed_unique <- as.data.frame(unique(fed_cats[,1]))

for(i in 2:ncol(fed_cats)){
  loop_unique <- as.data.frame(unique(fed_cats[,i]))
  colnames(loop_unique) <- colnames(fed_unique)
  fed_unique <- rbind(fed_unique,loop_unique)
}

fed_unique <- unique(fed_unique)
colnames(fed_unique)[1] <- "col_1"
fed_unique <- fed_unique[is.na(fed_unique$col_1)==FALSE,] #chech coln name
fed_unique <- as.data.frame(fed_unique)
fed_unique <- fed_unique[fed_unique$fed_unique!="",]

add_cols <- length(fed_unique)

#add and name new columns
new_cols <- seq(ncol(syd)+1,ncol(syd)+add_cols)
syd[,new_cols] <- ""

for(i in 1:length(new_cols)){
  #i <- 1
  col_name <- paste0("Total ",fed_unique[i])
  colnames(syd)[new_cols[i]] <- col_name
}
colnames(syd)

source_cols <- seq(from=53, to=91, by=2) #changed... verify!.. source: the code, not the amount


for(i in 1:nrow(syd)){#nrow(syd)
  # i <- 1
  
  for(j in 1:length(source_cols)){
    #j <- 15
    code <- syd[i,source_cols[j]]
    
    if(code!="" & is.na(code)==FALSE){
    col <- match(code,fed_unique)
    syd[i,new_cols[col]] <- syd[i,source_cols[j]+1]
  }
}

print(i)
}


#data.table::fwrite(syd,file = "testing.csv")

###########################################
#types of hours              ##############
###########################################

#changing as little code as possible

fed_cats <- syd[,c("Hours H 3/4 Code")] #changed

fed_unique <- as.data.frame(unique(fed_cats)) #changed from above becuase it's one column


fed_unique <- unique(fed_unique)
colnames(fed_unique)[1] <- "col_1"
fed_unique <- fed_unique[is.na(fed_unique$col_1)==FALSE,] #chech coln name
fed_unique <- as.data.frame(fed_unique)
fed_unique <- fed_unique[fed_unique$fed_unique!="",]

add_cols <- length(fed_unique)

#add and name new columns
new_cols <- seq(ncol(syd)+1,ncol(syd)+add_cols)
syd[,new_cols] <- ""

for(i in 1:length(new_cols)){
  #i <- 1
  col_name <- paste0("Total ",fed_unique[i], " Hours")
  colnames(syd)[new_cols[i]] <- col_name
}
colnames(syd)

source_cols <- 28 #changed... verify!.. source: the code, not the amount

#new loop... hopefully faster

for(i in 1:nrow(syd)){#nrow(syd)
  # i <- 1
  
  for(j in 1:length(source_cols)){
    #j <- 15
    code <- syd[i,source_cols[j]]
    
    if(code!="" & is.na(code)==FALSE){
      col <- match(code,fed_unique)
      syd[i,new_cols[col]] <- syd[i,source_cols[j]+1]
    }
  }
  
  print(i)
}


#data.table::fwrite(syd,file = "testing.csv")

###########################################
#types of 3/4 hours eanrings ##############
###########################################

#changing as little code as possible

fed_cats <- syd[,c("Earnings H 3/4 Code")] #changed

fed_unique <- as.data.frame(unique(fed_cats)) #changed from above becuase it's one column


fed_unique <- unique(fed_unique)
colnames(fed_unique)[1] <- "col_1"
fed_unique <- fed_unique[is.na(fed_unique$col_1)==FALSE,] #chech coln name
fed_unique <- as.data.frame(fed_unique)
fed_unique <- fed_unique[fed_unique$fed_unique!="",]

add_cols <- length(fed_unique)

#add and name new columns
new_cols <- seq(ncol(syd)+1,ncol(syd)+add_cols)
syd[,new_cols] <- ""

for(i in 1:length(new_cols)){
  #i <- 1
  col_name <- paste0("Total ",fed_unique[i], " Earnings")
  colnames(syd)[new_cols[i]] <- col_name
}
colnames(syd)

source_cols <- 32 #changed... verify!.. source: the code, not the amount

#new loop... hopefully faster

for(i in 1:nrow(syd)){#nrow(syd)
  # i <- 1
  
  for(j in 1:length(source_cols)){
    #j <- 15
    code <- syd[i,source_cols[j]]
    
    if(code!="" & is.na(code)==FALSE){
      col <- match(code,fed_unique)
      syd[i,new_cols[col]] <- syd[i,source_cols[j]+1]
    }
  }
  
  print(i)
}

#############################################
### Save Work ###############################
#############################################

setwd("C:/Users/jherndon/Desktop/XXXX")

save(syd,file = "syd.RData")

data.table::fwrite(syd,file = "testing.csv")

