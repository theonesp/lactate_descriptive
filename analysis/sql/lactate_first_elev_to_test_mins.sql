-- this query extracts
-- After the elevated one, how many minutes did it take to withdraw the next one.
-- Elevated lactate is greater than 2

WITH
  lactate_elevated_order AS (
  SELECT
    patientunitstayid,
    lactate,
    chartoffset,
    ROW_NUMBER() OVER (PARTITION BY patientunitstayid ORDER BY chartoffset ASC) AS rn
  FROM
    `physionet-data.eicu_crd_derived.pivoted_lab`
  WHERE
    lactate IS NOT NULL
    AND lactate > 2
  ORDER BY
    patientunitstayid,
    chartoffset),
  lactate_elevated_first AS (
  SELECT
    patientunitstayid,
    lactate AS lactate_elevated_first,
    chartoffset AS lactate_elevated_first_offset,
  FROM
    lactate_elevated_order
  WHERE
    rn = 1
  ORDER BY
    patientunitstayid,
    chartoffset ),
  only_lactates AS (
  SELECT
    patientunitstayid,
    lactate,
    chartoffset
  FROM
    `physionet-data.eicu_crd_derived.pivoted_lab`
  WHERE
    lactate IS NOT NULL),
  all_tests_after_elevated AS(
  SELECT
    lactate_elevated_first.patientunitstayid,
    lactate_elevated_first.lactate_elevated_first,
    lactate_elevated_first.lactate_elevated_first_offset,
    chartoffset AS first_testafter_elevated_offset,
    (chartoffset - lactate_elevated_first_offset) AS mins_from_first_elev_to_test,
    ROW_NUMBER() OVER (PARTITION BY patientunitstayid ORDER BY chartoffset ASC) AS rn,
  FROM
    lactate_elevated_first
  LEFT JOIN
    only_lactates
  USING
    (patientunitstayid)
  WHERE
    chartoffset > lactate_elevated_first_offset )
SELECT
  patientunitstayid,
  mins_from_first_elev_to_test
FROM
  all_tests_after_elevated
WHERE
  rn = 1