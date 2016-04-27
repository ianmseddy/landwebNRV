################################################################################
#' this function is to classify plot to dominant species based on biomass (>=75%) 
#' 
#' 
#' @param biomassTable, data.table.  It must has three columns, MeasureID, newSpeciesName and Biomass
#'
#'
#' @return species dominant table
#'
#' @note no note
#'
#' @seealso no
#'
#' @include 
#' @export
#' @docType methods
#' @rdname speciesDominanceIdentification
#'
#' @author Yong Luo
#'
#' @examples
#' \dontrun{
#' 
#' }
setGeneric("speciesDominanceIdentification", function(biomassTable) {
  standardGeneric("speciesDominanceIdentification")
})

#' @export
#' @rdname speciesDominanceIdentification
setMethod(
  "speciesDominanceIdentification",
  signature = c(biomassTable = "data.table"),
  definition = function(biomassTable) {
    biomassTable[, PlotBiomass:=sum(Biomass), by = MeasureID]
    biomassTable[, PlotBiomassBySpecies:=sum(Biomass), by = c("newSpeciesName", "MeasureID")]
    biomassTable[, SpeciesPercentage:=PlotBiomassBySpecies/PlotBiomass]
    biomassTable <- biomassTable[SpeciesPercentage>=0.75,]
    summaryTable <- unique(biomassTable[,.(MeasureID, newSpeciesName, PlotBiomass)], by = "MeasureID")
    setnames(summaryTable, "newSpeciesName", "DominantSpecies")
    return(dominantSpeciesTable=summaryTable)
  })




