module IslayShop::Admin::ReportsHelper

  # Provide a link to the current URL, with the params controlling date adjusted according to :action
  #
  # @param Symbol action
  # @param Hash date_range
  #
  # @return URL
  def report_date_link(action, date_range)
    current_date = DateTime.new(@report_range[:year], @report_range[:month], 1)
    new_date = case action
    when :previous_month then current_date - 1.month
    when :next_month then current_date + 1.month
    end

    url_for(params.merge(year: new_date.year, month: new_date.month))
  end
end