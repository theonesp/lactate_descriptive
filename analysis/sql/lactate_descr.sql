-- this query extracts 
-- first lactate per admission 
-- Max lactate per admission 
-- Number OF lactates per admission
-- Was lactate drawn yes/NO WITHIN first three days 
-- How many lactates were drawn WITHIN first 3 days
----In first 3 days, what % of patients in each group had a lactate redrawn (within 8 hours) 
WITH
  lactate_order AS (
  SELECT
    patientunitstayid,
    lactate,
    chartoffset,
    ROW_NUMBER() OVER (PARTITION BY patientunitstayid ORDER BY chartoffset ASC) AS rn,
  FROM
    `physionet-data.eicu_crd_derived.pivoted_lab`
  WHERE
    lactate IS NOT NULL
  ORDER BY
    patientunitstayid,
    chartoffset),
  lactate_fst AS (
  SELECT
    patientunitstayid,
    chartoffset,
    lactate AS lactate_fst,
    rn
  FROM
    lactate_order
  WHERE
    rn=1),
  lactate_max AS (
  SELECT
    patientunitstayid,
    MAX(lactate) AS lactate_max,
  FROM
    lactate_order
  GROUP BY
    patientunitstayid ),
  lactate_num AS (
  SELECT
    patientunitstayid,
    COUNT(lactate) AS lactate_num,
  FROM
    lactate_order
  GROUP BY
    patientunitstayid ),
  lactate_num_first3days AS (
  SELECT
    patientunitstayid,
    COUNT(lactate) AS lactate_num_first3days
  FROM
    lactate_order
  WHERE
    chartoffset BETWEEN -6*60 AND 3*24*60 -- we only wat to address lactated drawn within the first 3 days
  GROUP BY
    patientunitstayid ),
lactate_order_first3days AS (
  SELECT
    patientunitstayid,
    lactate,
    chartoffset,
    ROW_NUMBER() OVER (PARTITION BY patientunitstayid ORDER BY chartoffset ASC) AS rn,
  FROM
    `physionet-data.eicu_crd_derived.pivoted_lab`
  WHERE
    lactate IS NOT NULL 
    AND
    chartoffset BETWEEN -6*60 AND 3*24*60
  ORDER BY
    patientunitstayid,
    chartoffset),
  lactate_fst_first3days AS (
  SELECT
    patientunitstayid,
    chartoffset AS lactate_fst_first3days_offset,
    lactate AS lactate_fst_first3days,
    rn
  FROM
    lactate_order_first3days
  WHERE
    rn=1 )
,
  lactate_2nd_first3days AS (
  SELECT
    patientunitstayid,
    chartoffset AS lactate_2nd_first3days_offset,
    lactate AS lactate_2nd_first3days,
    rn
  FROM
    lactate_order_first3days
  WHERE
    rn=2 ),
lactateredrawn_wt8hrs_bin_first3days AS (
  SELECT
  lactate_fst_first3days.patientunitstayid,
  CASE WHEN lactate_2nd_first3days_offset - lactate_fst_first3days_offset <= 8*60 THEN 1 ELSE 0
  END AS lactateredrawn_wt8hrs_bin_first3days
  FROM
  lactate_fst_first3days 
  JOIN
  lactate_2nd_first3days
  USING (patientunitstayid)
)    
SELECT
  lactate_fst.patientunitstayid,
  lactate_fst.lactate_fst,
  lactate_max.lactate_max,
  lactate_num.lactate_num,
  CASE
    WHEN lactate_num_first3days.lactate_num_first3days IS NULL THEN CAST( 0 as INT64)
    ELSE  CAST(lactate_num_first3days.lactate_num_first3days AS INT64 )
    END AS lactate_num_first3days,
 CASE
    WHEN lactate_num_first3days.lactate_num_first3days IS NULL THEN 0
    ELSE 1
    END AS lactate_bin_first3days,
 lactateredrawn_wt8hrs_bin_first3days.lactateredrawn_wt8hrs_bin_first3days   
FROM
  lactate_fst
LEFT JOIN
  lactate_max
USING
  (patientunitstayid)
LEFT JOIN
  lactate_num
USING
  (patientunitstayid)
LEFT JOIN
  lactate_num_first3days
USING
  (patientunitstayid)
LEFT JOIN
  lactateredrawn_wt8hrs_bin_first3days
USING
  (patientunitstayid)  