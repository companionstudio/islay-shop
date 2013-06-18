class PromotionQuery < Islay::Query
  self.model = Promotion

  query :active, %{
    SELECT * FROM promotions
    WHERE active = true
    AND (start_at IS NULL OR start_at <= NOW())
    AND (end_at IS NULL OR end_at >= NOW())
  }

  # Finds code based promotions.
  #
  # @return ActiveRecord::Relation
  query :active_code_based, %{
      SELECT * FROM promotions
      WHERE active = true
      AND (start_at IS NULL OR start_at <= NOW())
      AND (end_at IS NULL OR end_at >= NOW())
      AND EXISTS (
        SELECT 1 FROM promotion_conditions AS pcs
        WHERE pcs.promotion_id = promotions.id AND pcs.type IN ('PromotionCodeCondition', 'PromotionUniqueCodeCondition')
      )
    }
end
