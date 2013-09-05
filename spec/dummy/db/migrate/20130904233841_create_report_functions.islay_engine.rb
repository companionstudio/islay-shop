# This migration comes from islay_engine (originally 20120905053324)
class CreateReportFunctions < ActiveRecord::Migration
  def up
    execute %{
      CREATE OR REPLACE FUNCTION movement_dir(in numeric, in numeric, out text) AS $$
        SELECT
          CASE
            WHEN $1 = $2 THEN 'none'
            WHEN $1 > $2 THEN 'up'
            WHEN $1 < $2 THEN 'down'
            ELSE 'na'
          END
      $$ LANGUAGE SQL;

      CREATE OR REPLACE FUNCTION movement_dir(in double precision, in double precision, out text) AS $$
        SELECT
          CASE
            WHEN $1 = $2 THEN 'none'
            WHEN $1 > $2 THEN 'up'
            WHEN $1 < $2 THEN 'down'
            ELSE 'na'
          END
      $$ LANGUAGE SQL;

      CREATE OR REPLACE FUNCTION within_this(in text, in timestamp, out boolean) AS $$
        SELECT
          CASE
            WHEN DATE_TRUNC($1, $2) = DATE_TRUNC($1, NOW()) THEN true
            ELSE false
          END
      $$ LANGUAGE SQL;

      CREATE OR REPLACE FUNCTION is_revenue(in text, out boolean) AS $$
        SELECT
          CASE
            WHEN $1 NOT IN ('pending', 'cancelled') THEN true
            ELSE false
          END
      $$ LANGUAGE SQL;

      CREATE OR REPLACE FUNCTION within_last(in text, in timestamp, out boolean) AS $$
        SELECT
          CASE
            WHEN DATE_TRUNC($1, $2) = DATE_TRUNC($1, NOW() - ('1 ' || $1)::interval) THEN true
            ELSE false
          END
      $$ LANGUAGE SQL;

      CREATE OR REPLACE FUNCTION within_month(in numeric, in numeric, in timestamp, out boolean) AS $$
        SELECT
          CASE
            WHEN DATE_PART('year', $3) = $1 AND DATE_PART('month', $3) = $2 THEN true
            ELSE false
          END
      $$ LANGUAGE SQL;

      CREATE OR REPLACE FUNCTION within_previous_month(in numeric, in numeric, in timestamp, out boolean) AS $$
        SELECT
          CASE
            WHEN current_month = true AND last_day = false THEN
              (SELECT $3 >= previous_start AND $3 <= (NOW() - '1 month'::interval))
            ELSE
              (SELECT $3 >= previous_start AND $3 <= previous_end)
          END
        FROM (
          SELECT
            TO_TIMESTAMP($1::text || $2::text, 'YYYYMM') - '1 month'::interval AS previous_start,
            TO_TIMESTAMP($1::text || $2::text, 'YYYYMM') - '1 second'::interval AS previous_end,
            (DATE_PART('month', CURRENT_DATE) = $2) AS current_month,
            (DATE_PART('day',(DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 MONTH - 1 day')) = DATE_PART('day', CURRENT_DATE)) AS last_day
        ) AS tests
      $$ LANGUAGE SQL;

      CREATE OR REPLACE FUNCTION within_dates(in text, in text, in timestamp, out boolean) AS $$
        SELECT
          CASE
            WHEN DATE_TRUNC('day', $3) >= $1 ::timestamp
            AND DATE_TRUNC('day', $3) <= $2 ::timestamp THEN true
            ELSE false
          END
      $$ LANGUAGE SQL;

      CREATE OR REPLACE FUNCTION within_previous_dates(in text, in text, in timestamp, out boolean) AS $$
        WITH times AS (
          SELECT
            $1::timestamp AS start_time,
            ($2 || ' 23:59:59')::timestamp AS end_time
        )

        SELECT
          $3 >= (start_time - span) AND $3 <= (end_time - span)
        FROM (
          SELECT
            (SELECT start_time FROM times) AS start_time,
            (SELECT end_time FROM times) AS end_time,
            (SELECT end_time FROM times) - (SELECT start_time FROM times) AS span
        ) AS vals
      $$ LANGUAGE SQL
    }
  end

  def down
    execute %{
      DROP FUNCTION IF EXISTS movement_dir(numeric, numeric);
      DROP FUNCTION IF EXISTS movement_dir(double precision, double precision);
      DROP FUNCTION IF EXISTS within_this(text, timestamp);
      DROP FUNCTION IF EXISTS is_revenue(text);
      DROP FUNCTION IF EXISTS within_month(numeric, numeric, timestamp);
      DROP FUNCTION IF EXISTS within_previous_month(numeric, numeric, timestamp);
      DROP FUNCTION IF EXISTS within_last(text, timestamp);
      DROP FUNCTION IF EXISTS within_dates(text, text, timestamp);
      DROP FUNCTION IF EXISTS within_previous_dates(text, text, timestamp);
    }
  end
end
