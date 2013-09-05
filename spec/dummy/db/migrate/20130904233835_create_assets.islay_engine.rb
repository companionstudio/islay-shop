# This migration comes from islay_engine (originally 20120516094639)
class CreateAssets < ActiveRecord::Migration
  def change
    create_table :assets do |t|
      t.integer   :asset_group_id,      :null => false, :on_delete => :cascade
      t.string    :type,                :null => false, :limit => 50
      t.string    :name,                :null => false, :limit => 200, :index => {:unique => true, :with => ['type', 'asset_group_id']}

      # Storage info
      t.string    :key,                 :null => false, :limit => 200
      t.string    :dir,                 :null => false, :limit => 6
      t.string    :filename,            :null => false, :limit => 200
      t.string    :original_filename,   :null => false, :limit => 200

      # Metadata
      t.integer   :filesize,            :null => true,  :precision => 20, :scale => 0
      t.string    :content_type,        :null => true,  :limit => 100

      # Image and Video
      t.string    :colorspace,          :null => true,  :limit => 20
      t.integer   :width,               :null => true,  :limit => 20
      t.integer   :height,              :null => true,  :limit => 20

      # Image
      t.boolean   :under_size,          :null => false, :default => false

      # Video
      t.string    :video_codec,         :null => true,  :limit => 50
      t.integer   :video_bitrate,       :null => true,  :limit => 15
      t.float     :video_frame_rate,    :null => true,  :limit => 15

      # Audio
      t.string    :audio_codec,         :null => true,  :limit => 50
      t.integer   :audio_bitrate,       :null => true,  :limit => 15
      t.integer   :audio_sample_rate,   :null => true,  :limit => 15
      t.integer   :audio_channels,      :null => true,  :limit => 2

      # Video and Audio
      t.float     :duration,            :null => true,  :limit => 15

      # Processing (in progress, errors etc)
      t.string    :status,              :null => false, :limit => 20, :default => 'enqueued'
      t.string    :error,               :null => true,  :limit => 255
      t.integer   :retries,             :null => false, :limit => 2, :default => 0

      t.user_tracking
      t.timestamps
    end

    add_column(:assets, :terms, :tsvector)
  end
end
