class DealCategory < ActiveRecord::Base
  unloadable      
  belongs_to :project
  has_many :deals, :foreign_key => 'category_id', :dependent => :nullify
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:project_id]
  validates_length_of :name, :maximum => 30
  
  alias :destroy_without_reassign :destroy
  
  # Destroy the category
  # If a category is specified, issues are reassigned to this category
  def destroy(reassign_to = nil)
    if reassign_to && reassign_to.is_a?(DealCategory) && reassign_to.project == self.project
      Deal.update_all("category_id = #{reassign_to.id}", "category_id = #{id}")
    end
    destroy_without_reassign
  end
  
  def <=>(category)
    name <=> category.name
  end
  
  def to_s; name end
end
