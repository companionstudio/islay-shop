class ManufacturerAsset < ActiveRecord::Base
  belongs_to :asset
  belongs_to :manufacturer
end

