class PromotionBonusEffect < PromotionEffect
  desc "Bonus SKU"

  belongs_to :sku
  has_one :product, :through => :sku

  metadata(:config) do
    foreign_key :sku_id,    :required => true, :values => lambda {Sku.tree}
    integer     :quantity,  :required => true, :greater_than => 0
  end

  def reward_sku?(sku)
    sku_id == sku.id
  end

  def reward_product?(product)
    product.skus.map {|s| s.id == sku_id}.any?
  end

  # Indicates if the effect provides a product or sku as an award
  #
  # @return Boolean
  def reward_any_product?
    true
  end

  # Which product is provided by this effect?
  #
  # @return Product
  def reward_product
    product
  end

  # When the conditions do not specify a sku, the whole order is considered to be the qualifying object
  def apply!(order, qualifications)
    if qualifications.class == CustomerOrder
      bonus_item = order.add_bonus_item(sku_id, quantity)
      order.applied_promotions << applications.build(
        :promotion        => promotion,
        :bonus_item       => bonus_item,
        :qualifying_item  => nil
      )
    else
      qualifications.each do |id, count|
        bonus_item = order.add_bonus_item(sku_id, quantity * count)

        order.applied_promotions << applications.build(
          :promotion        => promotion,
          :bonus_item       => bonus_item,
          :qualifying_item  => order.items.by_sku_id(sku_id)
        )
      end
    end
    
  end

  def product_categories
    top_level = ProductCategory.where('parent_id IS NULL').order('name ASC').includes(:children)
    values = []
    top_level.each do |category|
      if category.children.empty?
        values << [{:label => category.name, :id => category.id}, [[category.name, category.id]]]
      else
        children = category.children.map do |child|
          [child.name, child.id]
        end
        values << [{:label => category.name, :id => category.id}, children]
      end
    end
    values
  end

  def position
    3
  end
end
