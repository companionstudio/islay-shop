class PromotionQuery < Islay::Query
  self.model = Promotion

  query :active, %{
    SELECT * FROM promotions
    WHERE active = true
    AND (start_at IS NULL OR start_at <= NOW())
    AND (end_at IS NULL OR end_at >= NOW())
  }
end
