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

  # For a given action, provide a human-friendly past-tense name
  #
  # @param String action
  #
  # @return String
  def past_tense(action)
    case action
      when 'add'    then 'Placed'
      when 'bill'   then 'Billed'
      when 'pack'   then 'Packed'
      when 'ship'   then 'Shipped'
      when 'cancel' then 'Cancelled'
      else action
    end
  end

  # Show a representation of an order's state in context of the workflow.
  #
  # @param Order order
  #
  # @return String
  def process_progression(order)
    if order.cancelled?
      process = [
        {action: 'cancel', label: 'Cancelled', done: true}
      ]
    else
      process = case IslayShop::Engine.config.payments.mode
      when :authorize
        [
          {:action => 'add', :label => 'Place'},
          {:action => 'bill', :label => 'Billing'},
          {:action => 'pack', :label => 'Packing'},
          {:action => 'ship', :label => 'Shipping'}
        ]
      when :purchase
        [
          {:action => 'add', :label => 'Place'},
          {:action => 'pack', :label => 'Packing'},
          {:action => 'ship', :label => 'Shipping'}
        ]
      end

      order.logs.summary.reverse.each_with_index do |log, i|
        current_step = (i == order.logs.summary.length - 1)

        matching_process_step = process.find {|p|p[:action] == log.action}
        if matching_process_step
          matching_process_step[:done] = log.succeeded?
          matching_process_step[:error] = !log.succeeded?
          matching_process_step[:label] = log.succeeded? ? past_tense(matching_process_step[:action]) : matching_process_step[:label]
          matching_process_step[:current] = current_step
        else
          process << {:action => log.action, :label => past_tense(log.action), :error => false, :done => true, :current => current_step}
        end
      end
    end

    render :partial => 'order_process_order', :locals => {:process => process}
  end
end
