class RecentlyViewed < ActiveRecord::Base
  unloadable       

  RECENTLY_VIEWED_LIMIT = 5

  belongs_to :viewer, :class_name => 'User', :foreign_key => 'viewer_id'     
  belongs_to :viewed, :polymorphic => true    

  validates_presence_of :viewed, :viewer

  # after_save :increment_views_count
  def self.last(limit=RECENTLY_VIEWED_LIMIT, usr=nil)
    RecentlyViewed.find_all_by_viewer_id(usr || User.current, :limit => limit, :order => "#{RecentlyViewed.table_name}.updated_at DESC").collect{|v| v.viewed}
  end

  private

  def increment_views_count  
    self.increment!(:views_count)
  end   

end
