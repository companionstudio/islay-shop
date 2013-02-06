class IslayShop::Admin::PromotionsController < IslayShop::Admin::ApplicationController
  resourceful :promotion
  nav 'nav'

  def show
    @promotion = Promotion.find(params[:id])
  end

  private

  def invalid_record
    @promotion.prefill
  end

  def find_record
    if params[:action] == 'edit' || params[:action] == 'new'
      Promotion.find(params[:id]).tap(&:prefill)
    else
      Promotion.find(params[:id])
    end
  end

  def new_record
    Promotion.new.tap(&:prefill)
  end
end

