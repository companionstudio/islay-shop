class OrderAggregateDecorator < Draper::Decorator
  decorates :report

  delegate_all

  def total(value, money = true)
    this = report["this_#{value}"] || 0
    h.content_tag(:p, format(this, money), :class => "total")
  end

  def movement(value, money = true)
    this      = report["#{value}_movement"]
    previous  = report["previous_#{value}"]

    if this and previous
      h.content_tag(:p, "#{this.humanize} from #{format(previous, money)}", :class => "move-#{this}")
    end
  end

  def best(value, money = true)
    best        = report["best_#{value}"]
    best_month  = report["best_#{value}_month"]

    if best and best_month
      h.content_tag(:p, "Best: #{format(best, money)} for #{h.format_month(best_month)}", :class => 'best')
    end
  end

  def average(value, money = true)
    key = "average_#{value}"
    if report[key]
      h.content_tag(:p, "Average: #{format(report[key], money)}", :class => 'average')
    end
  end

  private

  def format(val, money)
    money ? h.format_money(val) : val
  end
end
