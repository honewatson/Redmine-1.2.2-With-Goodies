class Contact < ActiveRecord::Base
  unloadable  
  
  CONTACT_FORMATS = {
    :lastname_firstname_middlename => '#{last_name} #{first_name} #{middle_name}',
    :firstname_middlename_lastname => '#{first_name} #{middle_name} #{last_name}',
    :firstname_lastname => '#{first_name} #{last_name}',
    :lastname_coma_firstname => '#{last_name}, #{first_name}'
  }
  
  has_many :notes, :as => :source, :dependent => :delete_all, :order => "created_on DESC"
  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'assigned_to_id'    
  has_and_belongs_to_many :issues, :order => "#{Issue.table_name}.due_date", :uniq => true   
  has_and_belongs_to_many :projects, :uniq => true   
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'   
  has_one :avatar, :class_name => "Attachment", :as  => :container, :conditions => "#{Attachment.table_name}.description = 'avatar'", :dependent => :destroy
  
  attr_accessor :phones     
  attr_accessor :emails 
  
  acts_as_viewable
  acts_as_taggable
  acts_as_watchable
  acts_as_attachable :view_permission => :view_contacts,  
                     :delete_permission => :edit_contacts   

                     
  acts_as_event :datetime => :created_on,
                :url => Proc.new {|o| {:controller => 'contacts', :action => 'show', :id => o}}, 	
                :type => 'icon-user',  
                :title => Proc.new {|o| o.name },
                :description => Proc.new {|o| [o.info, o.company, o.email, o.address, o.background].join(' ') }     
  
  acts_as_searchable :columns => ["#{table_name}.first_name", 
                                  "#{table_name}.middle_name", 
                                  "#{table_name}.last_name", 
                                  "#{table_name}.company", 
                                  "#{table_name}.address", 
                                  "#{table_name}.background"], 
                     :project_key => "#{Project.table_name}.id",             
                     :include => [:projects],
                     # sort by id so that limited eager loading doesn't break with postgresql
                     :order_column => "#{table_name}.id"

                
                
  named_scope :visible, lambda {|*args| { :include => :projects,
                                          :conditions => Contact.allowed_to_condition(args.first || User.current, :view_contacts) }}                
  named_scope :deletable, lambda {|*args| { :include => :projects, 
                                            :conditions => Project.allowed_to_condition(args.first || User.current, :delete_contacts) }}

  named_scope :editable, lambda {|*args| { :include => :projects, 
                                            :conditions => Project.allowed_to_condition(args.first || User.current, :edit_contacts) }}
  
  named_scope :in_project, lambda {|*args| { :include => :projects, :conditions => ["#{Project.table_name}.id = ?", args.first]}}
  
  named_scope :like_by, lambda {|field, search| {:conditions =>   ["#{Contact.table_name}.#{field} LIKE ?", search + "%"] }}    

  named_scope :live_search, lambda {|search| {:conditions =>   ["(#{Contact.table_name}.first_name LIKE ? or 
                                                                  #{Contact.table_name}.last_name LIKE ? or 
                                                                  #{Contact.table_name}.middle_name LIKE ? or 
                                                                  #{Contact.table_name}.company LIKE ? or 
                                                                  #{Contact.table_name}.job_title LIKE ?)", 
                                                                 "%" + search + "%",
                                                                 "%" + search + "%",
                                                                 "%" + search + "%",
                                                                 "%" + search + "%",
                                                                 "%" + search + "%"] }}
  
  
  named_scope :order_by_name, :order => "#{Contact.table_name}.last_name, #{Contact.table_name}.first_name"               
                
  # name or company is mandatory
  validates_presence_of :first_name 
  validates_uniqueness_of :first_name, :scope => [:last_name, :middle_name, :company]
   
  def self.allowed_to_condition(user, permission, options={})
    Project.allowed_to_condition(user, permission)
  end 
      
  
  def self.available_tags(options = {})
    name_like = options[:name_like]
    limit = options[:limit]
    options   = {}
    cond   = ARCondition.new
    
    if name_like
      cond << ["#{ActsAsTaggableOn::Tag.table_name}.name LIKE ?", "%#{name_like.downcase}%"]
    end

    options[:conditions] = cond.conditions
    options[:limit] = limit if limit
    self.all_tag_counts(options)
  end
  
  def duplicates(limit=5)    
    scope = Contact.scoped({})  
    scope = scope.like_by("first_name",  self.first_name.strip) if !self.first_name.blank?
    scope = scope.like_by("middle_name",  self.middle_name.strip) if !self.middle_name.blank?  
    scope = scope.like_by("last_name",  self.last_name.strip) if !self.last_name.blank?  
    scope = scope.scoped(:conditions => ["#{Contact.table_name}.id <> ?", self.id]) if !self.new_record? 
    @duplicates ||= (self.first_name.blank? && self.last_name.blank? && self.middle_name.blank?) ? [] : scope.visible.find(:all, :limit => limit)  
  end
  
  def employees
    @employees ||= Contact.order_by_name.find(:all, :conditions => ["#{Contact.table_name}.company = ? AND #{Contact.table_name}.id <> ?", self.first_name, self.id])
  end  
  
  def redmine_user
    @redmine_user ||= User.find_by_mail(self.emails.first) unless self.email.blank?
  end

  def contact_company
    @contact_company ||= Contact.find_by_first_name(self.company) 
  end
  
  def notes_attachments 
    @contact_attachments ||= Attachment.find(:all, 
                                    :conditions => { :container_type => "Note", :container_id => self.notes.map(&:id)},   
                                    :order => "created_on DESC")
  end
  
  # usr for mailer
  def visible?(usr=nil)    
    @visible ||= 0 < self.projects.visible.count(:conditions => Project.allowed_to_condition((usr || User.current), :view_contacts))     
  end      
  
  def editable?(usr=nil) 
    @editable ||= 0 < self.projects.visible.count(:conditions => Project.allowed_to_condition((usr || User.current), :edit_contacts))     
  end

  def deletable?(usr=nil)  
    @deletable ||= 0 < self.projects.visible.count(:conditions => Project.allowed_to_condition((usr || User.current), :delete_contacts))     
  end
  
  def send_mail_allowed?(usr=nil)  
    @send_mail_allowed ||= 0 < self.projects.visible.count(:conditions => Project.allowed_to_condition((usr || User.current), :send_contacts_mail))     
  end
  
  def self.projects_joins
    joins = []
    joins << ["JOIN contacts_projects ON contacts_projects.contact_id = #{self.table_name}.id"]
    joins << ["JOIN #{Project.table_name} ON contacts_projects.project_id = #{Project.table_name}.id"]
  end

  def project(current_project=nil)     
    return @project if @project
    if current_project && self.projects.visible.include?(current_project) 
      @project  = current_project
    else    
      @project  = self.projects.visible.find(:first, :conditions => Project.allowed_to_condition(User.current, :view_contacts))
    end 
     
    @project ||= self.projects.first
  end   
  
  def name(formatter=nil)
    if !self.is_company   
      if formatter
        eval('"' + (CONTACT_FORMATS[formatter] || CONTACT_FORMATS[:firstname_lastname]) + '"')
      else
        @name ||= eval('"' + (Setting.plugin_contacts[:name_format] && CONTACT_FORMATS[Setting.plugin_contacts[:name_format].to_sym] || CONTACT_FORMATS[:firstname_lastname]) + '"')
      end
      
      # [self.last_name, self.first_name, self.middle_name].each {|field| result << field unless field.blank?}
    else
      self.first_name
    end    

  end   
  
  def info
    self.job_title
  end
     
  def phones                            
    @phones || self.phone ? self.phone.split( /, */) : []
  end   
  
  def emails                            
    @emails || self.email ? self.email.split( /, */) : []
  end
  
  private
  
  def assign_phone      
    if @phones
      self.phone = @phones.uniq.map {|s| s.strip.delete(',').squeeze(" ")}.join(', ')
    end
  end 
  
end
