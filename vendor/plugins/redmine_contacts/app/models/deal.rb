class Deal < ActiveRecord::Base  
  unloadable       
    
  belongs_to :project   
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'assigned_to_id'    
  belongs_to :category, :class_name => 'DealCategory', :foreign_key => 'category_id'
  belongs_to :contact  
  belongs_to :status, :class_name => "DealStatus", :foreign_key => "status_id"  
  has_many :deals, :class_name => "deal", :foreign_key => "reference_id"
  has_many :notes, :as => :source, :dependent => :delete_all, :order => "created_on DESC"
  has_many :deal_processes, :dependent => :delete_all
  has_and_belongs_to_many :related_contacts, :class_name => 'Contact', :order => "#{Contact.table_name}.last_name, #{Contact.table_name}.first_name", :uniq => true  
  
  
  named_scope :visible, lambda {|*args| { :include => :project,
                                          :conditions => Project.allowed_to_condition(args.first || User.current, :view_deals)} }                
  
  named_scope :deletable, lambda {|*args| { :include => :project, 
                                            :conditions => Project.allowed_to_condition(args.first || User.current, :delete_deals) }}

  named_scope :live_search, lambda {|search| {:conditions =>   ["(#{Deal.table_name}.name LIKE ?)", "%#{search}%"] }}
  
  named_scope :open, :include => :status, :conditions => ["#{DealStatus.table_name}.is_closed = ?", false]
  
  acts_as_viewable
  acts_as_watchable
  acts_as_attachable :view_permission => :view_deals,
                     :delete_permission => :edit_deals   
                     
  acts_as_event :datetime => :created_on,
               :url => Proc.new {|o| {:controller => 'deals', :action => 'show', :id => o}}, 	
               :type => 'icon-report',  
               :title => Proc.new {|o| o.name },
               :description => Proc.new {|o| [o.price, o.contact ? o.contact.name : nil, o.background].join(' ').strip }     
                     

  validates_presence_of :name   
  validates_numericality_of :price, :allow_nil => true 
  
  after_save :create_deal_process
     
  
  include ActionView::Helpers::NumberHelper
  
  def after_initialize
    if new_record?
      # set default values for new records only
      self.status ||= DealStatus.default
    end
  end
  
  def avatar
    
  end
   
  def full_name
      (self.contact.name + ": " if self.contact) + self.name
  end
  
  def all_contacts
    @all_contacts ||= ([self.contact] + self.related_contacts ).uniq
  end
      
  def self.available_users(prj=nil)  
    cond = "(1=1)"  
    cond << " AND #{Deal.table_name}.project_id = #{prj.id}" if prj
    User.active.find(:all, :select => "DISTINCT #{User.table_name}.*", :joins => "JOIN #{Deal.table_name} ON #{Deal.table_name}.assigned_to_id = #{User.table_name}.id", :conditions => cond, :order => "#{User.table_name}.lastname, #{User.table_name}.firstname")
  end 
  
  
  def init_deal_process(author)
    @current_deal_process ||= DealProcess.new(:deal => self, :author => (author || User.current))
    @deal_status_before_change = self.new_record? ? nil : self.status_id
    updated_on_will_change!  
    @current_deal_process
  end
  
  def create_deal_process
    if @current_deal_process && !(@deal_status_before_change == self.status_id)
      @current_deal_process.old_value = @deal_status_before_change
      @current_deal_process.value = self.status_id 
      @current_deal_process.save
      # reset current journal
      init_deal_process @current_deal_process.author
    end
  end   
  
  def visible?(usr=nil)
    (usr || User.current).allowed_to?(:view_deals, self.project)
  end    
  
  def editable?(usr=nil)
    (usr || User.current).allowed_to?(:edit_deals, self.project)
  end

  def destroyable?(usr=nil)
    (usr || User.current).allowed_to?(:delete_deals, self.project)
  end
  
    
  def info  
   result = ""
   result = self.status.name if self.status
   result = result + " - " + number_to_currency(self.price) if !self.price.blank?    
   result
  end

end
