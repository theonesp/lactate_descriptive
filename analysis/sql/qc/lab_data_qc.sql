-- !preview conn=DBI::dbConnect(RSQLite::SQLite())
-- If Hgb is missing it means lab data is unreliable for that patient

SELECT
  DISTINCT patientunitstayid
FROM
  `physionet-data.eicu_crd.lab`
WHERE
    labname = 'Hgb' AND labresulttext IS NOT null