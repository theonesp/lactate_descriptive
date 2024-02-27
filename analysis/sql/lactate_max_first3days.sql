-- Create lactate_max_first3days
-- From that max, create a categorical variable.
-- Lactate max first 3 days: normal <2.5, elev lactate between 2.5-4, severely elevated >4 
-- se_lactate_max_first3days

WITH
  lactate_max_first3days AS (
  SELECT
    patientunitstayid,
    MAX(lactate) AS lactate_max
  FROM
    `physionet-data.eicu_crd_derived.pivoted_lab`
  WHERE
    chartoffset BETWEEN -6*60 AND 3*24*60 -- we only wat to address lactated drawn within the first 3 days
  GROUP BY
    patientunitstayid )
SELECT
  patientunitstayid,
  CASE
    WHEN lactate_max IS NULL THEN 'Not Available'
    WHEN lactate_max < 2.5 THEN 'Normal'
    WHEN lactate_max >= 2.5 AND lactate_max <= 4 THEN 'Elevated'
    WHEN lactate_max > 4 THEN 'Severely Elevated'
END AS lactate_max_first3days_type
FROM
  lactate_max_first3days