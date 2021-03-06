################################################################################
#' organize the BC PSP data based on sampling protocols, 
#' and select the data that can be used in LandWeb project
#' 
#' 
#' @param treeDataRaw  data table, 
#'
#' 
#' @param plotHeaderDataRaw data.table, 
#'        
#'
#' @return  two data tables, the first one header data, 
#'                           which contains the location and SA info.
#'                           the second one is organized tree data, 
#'                           which contains inividual tree information.
#'                           for the tree data, all trees are alive.
#'  
#' @importFrom data.table setkey setnames ':=' set
#'
#' @note no note
#'
#' @seealso no
#'
#' @include 
#' @export
#' @docType methods
#' @rdname dataPurification_BCPSP
#'
#' @author Yong Luo
#'
#' @examples
#' \dontrun{
#' 
#' }
setGeneric("dataPurification_BCPSP", function(treeDataRaw, plotHeaderDataRaw) {
  standardGeneric("dataPurification_BCPSP")
})
#' @export
#' @rdname dataPurification_BCPSP
setMethod(
  "dataPurification_BCPSP",
  signature = c(treeDataRaw = "data.table", 
                plotHeaderDataRaw = "data.table"),
  definition = function(treeDataRaw, plotHeaderDataRaw) {
    # purifying headData
    # like AB data, the BC PSP have two level heirachical design (SAMP_ID and plot)
    
    # get the plots with SA
    headerData <- plotHeaderDataRaw[tot_stand_age != -99,][
      ,':='(utmtimes = length(unique(utm_zone)),
            eastingtimes = length(unique(utm_easting)),
            northingtimes = length(unique(utm_northing)),
            SAtimes = length(unique(tot_stand_age)),
            plotsizetimes = length(unique(area_pm)),
            standorigtimes = length(unique(stnd_org)),
            treatmenttimes = length(unique(treatment))),
      by = SAMP_ID]
    # unique(headDataRaw$utmtimes)#1
    # unique(headDataRaw$eastingtimes)#1
    # unique(headDataRaw$northingtimes)# 1
    # unique(headDataRaw$SAtimes) # no NA
    # unique(headDataRaw$plotsizetimes)#1
    # unique(headDataRaw$standorigtimes) # 1
    
    
    # select the natural originated and untreated  
    headerData <- headerData[stnd_org == "N" | stnd_org == "F",]
                               
    headerData[,treatmenttimes := length(unique(treatment)), by = c("SAMP_ID", "meas_yr")]
    # unique(headDataRaw$treatmenttimes) # 1 2
    headerData <- headerData[treatmenttimes == 1 & treatment == "UNTREATED", .(SAMP_ID, utm_zone, utm_easting,
                 utm_northing, area_pm, tot_stand_age,
                 meas_yr)]
    

    headerData[, baseYear := min(meas_yr),
                by = SAMP_ID]
    headerData[, baseSA := as.integer(tot_stand_age-(meas_yr-baseYear))]
    # get the plots with locations
    headerData <- headerData[!is.na(utm_zone) & !is.na(utm_easting) & !is.na(utm_northing),]
    # get plots with plot size
    headerData <- headerData[!is.na(area_pm),][,':='(tot_stand_age = NULL, meas_yr = NULL)]
    names(headerData)[1:5] <- c("OrigPlotID1", "Zone", "Easting",
                              "Northing", "PlotSize")
    headerData <- unique(headerData, by = c("OrigPlotID1"))
    
    
    
    # for tree data
    setnames(treeDataRaw, c("SAMP_ID", "plot_no"),
             c("OrigPlotID1", "OrigPlotID2"))
    treeData <- treeDataRaw[OrigPlotID1 %in% unique(headerData$OrigPlotID1),]
    # range(treeData$meas_yr) # 1926 2014
    # unique(treeData$Plotnumber) # 01 02 03
    treeData <- treeData[sub_plot_tree == "N",][, OrigPlotID2 := as.numeric(OrigPlotID2)]
    treeData <- treeData[tree_cls == 1 | tree_cls == 2,.(OrigPlotID1, OrigPlotID2, meas_yr, tree_no, species,
                            dbh, height)]
    # unique(treeData$ld)
    names(treeData)[3:7] <- c("MeasureYear", "TreeNumber", "Species", "DBH", "Height")
    
    measreidtable <- unique(treeData[,.(OrigPlotID1, OrigPlotID2, MeasureYear)], by = c("OrigPlotID1", "OrigPlotID2", "MeasureYear"))
    measreidtable[,MeasureID:= paste("BCPSP_",row.names(measreidtable), sep = "")]
    measreidtable <- measreidtable[,.(MeasureID, OrigPlotID1, OrigPlotID2, MeasureYear)]
    headerData <- setkey(measreidtable, OrigPlotID1)[setkey(headerData, OrigPlotID1), nomatch = 0]
    set(headerData, ,"OrigPlotID2", NULL)
    headerData <- headerData[,.(MeasureID, OrigPlotID1, MeasureYear, Longitude = NA,
                                Latitude = NA, Zone, Easting, Northing, PlotSize, baseYear,
                                baseSA)]
    treeData <- setkey(measreidtable, OrigPlotID1, OrigPlotID2, MeasureYear)[setkey(treeData, OrigPlotID1, OrigPlotID2, MeasureYear),
                                                                             nomatch = 0]
    return(list(plotHeaderData = headerData, treeData = treeData))
})
