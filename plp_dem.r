## First time run
# install.packages('remotes')

## you may need to setup github personal access token and modify the .REnviron file
# remotes::install_github('ohdsi/ROhdsiWebApi')
# remotes::install_github('ohdsi/CohortGenerator')
# remotes::install_github('ohdsi/FeatureExtraction')
# remotes::install_github('ohdsi/PatientLevelPrediction')
# remotes::install_github('ohdsi/DeepPatientLevelPrediction')

library(PatientLevelPrediction)
#options(reticulate.conda_binary = "~/anaconda3")

## setting workdir, assuming you use RStudio, otherwise you may need to change the working directory manually
current_script <- rstudioapi::getSourceEditorContext()$path
setwd(dirname(current_script))

## assuming you have a conda based python environment, create a test environment first using the following command
#PatientLevelPrediction::configurePython(envname='test', envtype='python')
PatientLevelPrediction::setPythonEnvironment(envname = 'test', envtype='conda')

## otherwise, use the following command to use the default python virtual environment
#PatientLevelPrediction::setPythonEnvironment(envname = 'test', envtype='python')

## or sometimes you may need to use rereticulate to set the python environment
#reticulate::use_virtualenv('test')

# define target-outcome pair
pairs <- list(
  dm2d = list(
    analysisId = "Type 2 DM to Dementia",
    analysisDesc = "DM2D prediction",
    outcomeId = 243, # change to your own Atlas generated cohort ID
    targetId = 242, # change to your own Atlas generated cohort ID
    cohortTable = "plpDemCohort"
  ),
  ht2d = list(
    analysisId = "Hyypertension to Dementia",
    analysisDesc = "HT2D prediction",
    outcomeId = 243, #  change to your own Atlas generated cohort ID
    targetId = 262, #  change to your own Atlas generated cohort ID
    cohortTable = "plpDemCohort"
  ),
  dep2d = list(
    analysisId = "Depression to Dementia",
    analysisDesc = "DEP2D prediction",
    outcomeId = 243, #  change to your own Atlas generated cohort ID
    targetId = 267, #  change to your own Atlas generated cohort ID
    cohortTable = "plpDemCohort"
  )
)

saveDir <- "./out_"

## you may need to download the jdbc driver first, based on your database server
#DatabaseConnector::downloadJdbcDrivers('sql server','~/.config/jdbc/')

## change the following to your own database connection details
conn <- DatabaseConnector::createConnectionDetails(
  'sql server',
  user = '<<db_user>>',
  password = '<<db_password>>',
  server = '<<server_address>>',
  pathToDriver = '~/.config/jdbc/'
)

for (key in names(pairs)) {
  targetId <- pairs[[key]][['targetId']]
  outcomeId <- pairs[[key]][['outcomeId']]
  cohortTable <- pairs[[key]][['cohortTable']]
  outcomeTable <- pairs[[key]][['cohortTable']]
  
  cohortIds <- c(targetId, outcomeId)
  
  ## if your Atlas uses user/password for authentication, you may need to use the following command to authorize the web api
  ## you also need to change the webapi url
  # ROhdsiWebApi::authorizeWebApi('http://<<your_webapi>>:8080/WebAPI', authMethod = 'db', webApiUsername = 'ohdsi', webApiPassword = 'ohdsi')
  cohortDef <- ROhdsiWebApi::exportCohortDefinitionSet(
    baseUrl = "http://<<your_webapi>>:8080/WebAPI",
    cohortIds = cohortIds
  )
  
  ## Change the database name to your own database name and id, as well as the schema names
  databaseDetails <- PatientLevelPrediction::createDatabaseDetails(
    connectionDetails = conn,
    cdmDatabaseSchema = 'OHDSI_V5_V2.dbo',
    cdmDatabaseName = 'TMU_CRD',
    cdmDatabaseId = 'tmudb',
    cohortDatabaseSchema = 'OHDSI_ACHILLES.dbo',
    outcomeDatabaseSchema = 'OHDSI_ACHILLES.dbo',
    cohortTable = cohortTable,
    outcomeTable = cohortTable,
    targetId = targetId,
    outcomeIds = outcomeId,
    cdmVersion = 5
  )
  tableNames<-CohortGenerator::getCohortTableNames(cohortTable = cohortTable)
  CohortGenerator::createCohortTables(
    connectionDetails = conn,
    cohortDatabaseSchema = "OHDSI_ACHILLES.dbo",
    cohortTableNames = tableNames
  )
  
  ## Change the database name to your own database name and id, as well as the schema names
  cohortGen<-CohortGenerator::generateCohortSet(
    conn,
    cdmDatabaseSchema = 'OHDSI_V5_V2.dbo',
    tempEmulationSchema = NULL,
    cohortDatabaseSchema = 'OHDSI_ACHILLES.dbo',
    cohortTableNames = tableNames,
    cohortDefinitionSet = cohortDef
  )
  covariateSettings <- FeatureExtraction::createCovariateSettings(
    useDemographicsGender = TRUE,
    useDemographicsAgeGroup = TRUE,
    useDemographicsIndexMonth = TRUE,
    useDemographicsPriorObservationTime = TRUE,
    useDemographicsPostObservationTime = TRUE,
    useDemographicsTimeInCohort = TRUE,
    useConditionOccurrenceAnyTimePrior = TRUE,
    useConditionOccurrenceLongTerm = TRUE,
    useConditionOccurrenceMediumTerm = TRUE,
    useConditionOccurrenceShortTerm = TRUE,
    useConditionEraAnyTimePrior = TRUE,
    useConditionGroupEraLongTerm = TRUE,
    useConditionGroupEraShortTerm = F,
    useDrugGroupEraLongTerm = TRUE,
    useDrugGroupEraShortTerm = F,
    useDrugGroupEraOverlapping = TRUE,
    useDrugExposureAnyTimePrior = TRUE,
    useDrugExposureLongTerm = TRUE,
    useDrugExposureMediumTerm = TRUE,
    useDrugExposureShortTerm = TRUE,
    useDcsi = TRUE,
    useChads2 = TRUE,
    useChads2Vasc = TRUE,
    useCharlsonIndex = TRUE
  )
  restrictPlpDataSettings <- PatientLevelPrediction::createRestrictPlpDataSettings(sampleSize = NULL)
  populationSettings <- PatientLevelPrediction::createStudyPopulationSettings(
    washoutPeriod = 365,
    firstExposureOnly = F,
    removeSubjectsWithPriorOutcome = T,
    priorOutcomeLookback = 365,
    riskWindowStart = 1,
    riskWindowEnd = (365*5),
    startAnchor = 'cohort start',
    endAnchor = 'cohort start',
    minTimeAtRisk = 1,
    requireTimeAtRisk = T,
    includeAllOutcomes = T
  )
  splitSettings <- PatientLevelPrediction::createDefaultSplitSetting(
    trainFraction = 0.8,
    testFraction = 0.2,
    splitSeed = 1
  )
  sampleSettings <- PatientLevelPrediction::createSampleSettings()
  featureEngineeringSettings <- PatientLevelPrediction::createFeatureEngineeringSettings()
  preprocessSettings <- PatientLevelPrediction::createPreprocessSettings(
    minFraction = 0.01,
    normalize = T,
    removeRedundancy = T
  )
  models <- list(
    PatientLevelPrediction::setLassoLogisticRegression(),
    PatientLevelPrediction::setLightGBM(
      isUnbalance = T,
      seed=1,
      numLeaves = c(20),
      minDataInLeaf = c(10)
    ),
    PatientLevelPrediction::setKNN()
  )
  modelList <- list()
  
  for (i in 1:length(models)){
    modelList[[i]] <- PatientLevelPrediction::createModelDesign(
      targetId = targetId,
      outcomeId = outcomeId,
      restrictPlpDataSettings = restrictPlpDataSettings,
      populationSettings = populationSettings,
      featureEngineeringSettings = featureEngineeringSettings,
      sampleSettings = sampleSettings,
      preprocessSettings = preprocessSettings,
      modelSettings = models[[i]],
      splitSettings = splitSettings,
      runCovariateSummary = T
    )
  }
  
  PatientLevelPrediction::runMultiplePlp(
    databaseDetails = databaseDetails,
    modelDesignList = modelList,
    logSettings = PatientLevelPrediction::createLogSettings(
      verbosity = "DEBUG", timeStamp = T, logName = "runPlp Log"),
    saveDirectory = paste0(saveDir, key),
    sqliteLocation = file.path(paste0(saveDir,key), 'sqlite')
  )
}

PatientLevelPrediction::viewMultiplePlp('out_dep2d')
PatientLevelPrediction::viewMultiplePlp('out_dm2d')
PatientLevelPrediction::viewMultiplePlp('out_ht2d')

## ZIP and share the result.zip file
zip('result.zip', files = c("out_dep2d", "out_dm2d", "out_ht2d"))
