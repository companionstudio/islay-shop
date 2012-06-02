module IslayShop
  module Statuses
    STATUSES = {
      'For Sale'      => 'for_sale',
      'Not for Sale'  => 'not_for_sale',
      'Discontinued'  => 'discontinued'
    }

    def statuses
      STATUSES
    end
  end
end
