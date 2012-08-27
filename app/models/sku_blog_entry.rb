class SkuBlogEntry < ActiveRecord::Base
  belongs_to :sku
  belongs_to :blog_entry
end
