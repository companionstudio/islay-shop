namespace :islay_shop do
  namespace :db do
    desc "Rebuilds the search term index for each record in the DB."
    task :rebuild_search_index => :environment do
      PgSearch::Multisearch.rebuild(Product)
      PgSearch::Multisearch.rebuild(ProductCategory)
      PgSearch::Multisearch.rebuild(ProductRange)
      PgSearch::Multisearch.rebuild(Manufacturer)
      PgSearch::Multisearch.rebuild(Sku)
      PgSearch::Multisearch.rebuild(Order)
    end

    desc "Fixes ordering of product categories and products"
    task :order_fix => :environment do
      Product.all.group_by {|p| p.product_category_id}.each do |g, a|
        a.each_with_index {|p, i| p.update_attribute :position, i + 1}
      end

      ProductCategory.all.group_by {|p| p.product_category_id || 'NULL'}.each do |g, a|
        a.each_with_index {|p, i| p.update_attribute :position, i + 1}
      end
    end

    desc "Loads in seed data for bootstrapping a fresh Islay app."
    task :seed => :environment do
      require 'islay/spec'
      ProductCategory.make!(15)

      now = Time.now
      time = 1.months.ago
      while time < now
        # Generate a random number of completed records
        OrderProcess.make(rand(30) + 1).map do |o|
          begin
            o.created_at, o.updated_at = time
            o.run!(:add)
            o.update_attribute(:status, 'complete')
          rescue Sku::InsufficientStock
            # Just ignore this guy
          end
        end

        # Increment time to a random step between 1 and 3 days
        time = time.advance(:days => 1)
      end
    end
  end
end