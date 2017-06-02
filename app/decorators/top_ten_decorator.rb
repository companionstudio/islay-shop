class TopTenDecorator < Draper::Decorator
  decorates :report
  delegate_all

  def long_desc
    "#{report['product_name']} - #{short_desc}"
  end

  def short_desc
    report['short_desc']
  end
end
