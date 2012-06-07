class PromotionQuantityCondition < PromotionCondition
  option(:sku) do
    integer :sku_id,   :required => true
    integer :quantity, :required => true

    qualification :check_sku
  end

  option(:product) do
    integer :product_id,  :required => true
    integer :quantity,    :required => true

    qualification :check_product
  end

  option(:category) do
    integer :product_category_id, :required => true
    integer :quantity,            :required => true

    qualification :check_category
  end

  def check_sku(order)

  end

  def check_product(order)

  end

  def check_category(order)

  end
end
