class TopTenDecorator < Draper::Base
  decorates :report

  def long_desc
    "#{report['product_name']} - #{short_desc}"
  end

  def short_desc
    %w(name formatted_volume formatted_weight size formatted_price).map {|n| report[n]}.compact.join(' - ')
  end
end
