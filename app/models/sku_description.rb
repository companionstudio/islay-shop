module SkuDescription
  # An extended description of the SKU, which appends the product name to
  # the beginning.
  #
  # @return String
  def long_desc
    "#{product_name} - #{short_desc}"
  end

  # Formats the weight into either string displaying either kilograms or grams.
  #
  # @return String
  def formatted_weight
    if weight >= 1000
      "#{weight / 100}kg"
    else
      "#{weight}g"
    end
  end

  # Formats the volume into either string displaying either litres or
  # millilitres.
  #
  # @return String
  def formatted_volume
    if volume.to_i >= 1000
      "#{volume.to_f / 1000}l"
    else
      "#{volume}ml"
    end
  end
end
