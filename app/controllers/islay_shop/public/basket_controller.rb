class IslayShop::Public::BasketController < IslayShop::Public::ApplicationController
  before_filter :check_for_order

  def contents

  end

  def add

    store
  end

  def remove

    store
  end

  def update

    store
  end

  def clear
    session.delete('order')
  end

  private

  def check_for_order
    redirect_to(:basket_contents) unless @order
  end

  def store
    sesssion['order'] = @order.dump
  end
end
