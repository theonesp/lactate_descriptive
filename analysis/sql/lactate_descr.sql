-- this query extracts
-- first lactate per admission
-- Max lactate per admission
-- Number of lactates per admission

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
    patientunitstayid )
SELECT
  lactate_fst.patientunitstayid,
  lactate_fst.lactate_fst,
  lactate_max.lactate_max,
  lactate_num.lactate_num
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