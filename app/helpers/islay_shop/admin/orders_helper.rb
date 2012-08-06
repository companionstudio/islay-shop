module IslayShop::Admin::OrdersHelper
  # For counts over 0, adds an annotating span with the count.
  #
  # @param String title
  # @param Integer count
  #
  # @return String
  def with_count(title, n)
    if n > 0
      "#{content_tag(:span, title, :class => 'link')} #{content_tag(:span, n, :class => 'count')}".html_safe
    else
      title
    end
  end
end
