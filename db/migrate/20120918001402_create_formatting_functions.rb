class CreateFormattingFunctions < ActiveRecord::Migration
  def up
    execute %{
      CREATE OR REPLACE FUNCTION formatted_volume(in numeric, out text) AS $$
        SELECT
          CASE
            WHEN $1 IS NULL THEN NULL
            WHEN $1 >= 1000 THEN ($1::float / 1000)::text || 'l'
            ELSE $1::text || 'ml'
          END
      $$ LANGUAGE SQL;

      CREATE OR REPLACE FUNCTION formatted_weight(in numeric, out text) AS $$
        SELECT
          CASE
            WHEN $1 IS NULL THEN NULL
            WHEN $1 >= 1000 THEN ($1::float / 1000)::text || 'kg'
            ELSE $1::text || 'g'
          END
      $$ LANGUAGE SQL;

      CREATE OR REPLACE FUNCTION formatted_money(in double precision, out text) AS $$
        SELECT
          CASE
            WHEN $1 IS NULL OR $1 = 0 THEN '$0.00'
            ELSE '$' || TRIM(TO_CHAR($1, '999999999999D99'))
          END
      $$ LANGUAGE SQL
    }
  end

  def down
    execute %{
      DROP FUNCTION IF EXISTS formatted_volume(numeric);
      DROP FUNCTION IF EXISTS formatted_weight(numeric);
      DROP FUNCTION IF EXISTS formatted_money(numeric)
    }
  end
end
