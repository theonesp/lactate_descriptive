-- The query is calculating whether at least one lab was drawn for each day within the first three days for each patientunitstayid in the dataset.
-- It retrieves the patientunitstayid and a binary column atleast_one_lab_drawn_each_day_first_3days 
-- indicating whether at least one lab was drawn for each day within the first three days for each patient.

  SELECT
    patientunitstayid,
    CASE
      WHEN COUNT(DISTINCT CASE WHEN chartoffset BETWEEN 0 AND (60*24) AND (albumin IS NOT NULL OR bilirubin IS NOT NULL OR BUN IS NOT NULL OR calcium IS NOT NULL OR creatinine IS NOT NULL OR glucose IS NOT NULL OR bicarbonate IS NOT NULL OR TotalCO2 IS NOT NULL OR hematocrit IS NOT NULL OR hemoglobin IS NOT NULL OR INR IS NOT NULL OR lactate IS NOT NULL OR platelets IS NOT NULL OR potassium IS NOT NULL OR ptt IS NOT NULL OR sodium IS NOT NULL OR wbc IS NOT NULL OR bands IS NOT NULL OR alt IS NOT NULL OR ast IS NOT NULL OR alp IS NOT NULL) THEN 1 END) >= 1
        AND COUNT(DISTINCT CASE WHEN chartoffset BETWEEN (60*24) AND (60*48) AND (albumin IS NOT NULL OR bilirubin IS NOT NULL OR BUN IS NOT NULL OR calcium IS NOT NULL OR creatinine IS NOT NULL OR glucose IS NOT NULL OR bicarbonate IS NOT NULL OR TotalCO2 IS NOT NULL OR hematocrit IS NOT NULL OR hemoglobin IS NOT NULL OR INR IS NOT NULL OR lactate IS NOT NULL OR platelets IS NOT NULL OR potassium IS NOT NULL OR ptt IS NOT NULL OR sodium IS NOT NULL OR wbc IS NOT NULL OR bands IS NOT NULL OR alt IS NOT NULL OR ast IS NOT NULL OR alp IS NOT NULL) THEN 1 END) >= 1
        AND COUNT(DISTINCT CASE WHEN chartoffset BETWEEN (60*48) AND (60*72) AND (albumin IS NOT NULL OR bilirubin IS NOT NULL OR BUN IS NOT NULL OR calcium IS NOT NULL OR creatinine IS NOT NULL OR glucose IS NOT NULL OR bicarbonate IS NOT NULL OR TotalCO2 IS NOT NULL OR hematocrit IS NOT NULL OR hemoglobin IS NOT NULL OR INR IS NOT NULL OR lactate IS NOT NULL OR platelets IS NOT NULL OR potassium IS NOT NULL OR ptt IS NOT NULL OR sodium IS NOT NULL OR wbc IS NOT NULL OR bands IS NOT NULL OR alt IS NOT NULL OR ast IS NOT NULL OR alp IS NOT NULL) THEN 1 END) >= 1
      THEN 1
      ELSE 0
    END AS atleast_one_lab_drawn_each_day_first_3days
  FROM
    `physionet-data.eicu_crd_derived.pivoted_lab`
  GROUP BY
    patientunitstayid
