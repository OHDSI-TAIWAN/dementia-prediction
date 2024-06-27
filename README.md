# PLP Dementia Prediction
<img src="https://img.shields.io/badge/Study%20Status-Repo%20Created-lightgray.svg" alt="Study Status: Repo Created">

- Analytics use case(s): **Clinical Application**
- Study type: **Patient-Level Prediction**
- Tags: **Taiwan Chapter**
- Study lead: **Jason Hsu, Alex Nguyen, Phan Thanh Phuc, Solie Maz**
- Study lead forums tag: **-**
- Study start date: **-**
- Study end date: **-**
- Protocol: **https://github.com/OHDSI-TAIWAN/dementia-prediction/tree/main#:~:text=Dementia_AI_Protocol_v2_Nov16.docx**
- Publications: **-**
- Results explorer: **http://35.229.190.150/shiny/dementia/**

# Introduction
This study aims to develop a personalized predictive model, utilizing artificial intelligence, to assess the 5-year dementia risk among patients with chronic diseases who are prescribed medications.

# How to run the study
1. Download the JSON files for cohort definition
2. Import the JSON files to create cohorts in your ATLAS system
3. Download the `plp_dem.r` script, adjust the cohort IDs for the target and outcome, and other setting based on your environment
4. Run the script, for the first running, you may need to install some required libraries, as well as the database driver. Refer to the `plp_dem.r` script for the details.
5. Share the result.zip by contacting the PI 
