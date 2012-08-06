module IslayShop::Admin::OrdersHelper
  def with_count(s, n)
    if n > 0
      "#{content_tag(:span, s, :class => 'link')} #{content_tag(:span, n, :class => 'count')}".html_safe
    else
      s
    end
  end
end
