class ContactsController < ApplicationController
  unloadable    
  
  Mime::Type.register "text/x-vcard", :vcf     
  
  default_search_scope :contacts    
  
  before_filter :find_contact, :only => [:show, :edit, :update, :destroy, :edit_tags]  
  before_filter :find_project_by_project_id, :only => [:new, :create]
  before_filter :authorize, :except => [:index, :contacts_notes, :context_menu, :bulk_destroy, :bulk_edit, :bulk_update, :edit_mails, :send_mails]
  before_filter :find_optional_project, :only => [:index, :contacts_notes] 
   
  accept_rss_auth :index, :show
  accept_api_auth :index, :show, :create, :update, :destroy 
  
  helper :attachments
  helper :contacts  
  helper :watchers  
  helper :notes    
  helper :custom_fields
  include WatchersHelper
  
  def show   
    @open_issues = @contact.issues.visible.open(:order => "#{Issue.table_name}.due_date DESC")   
    source_id_cond = @contact.is_company ? Contact.order_by_name.find_all_by_company(@contact.first_name).map(&:id) << @contact.id : @contact.id 
    @note = Note.new  
    @notes_pages, @notes = paginate :notes,
                                    :per_page => 30,
                                    :conditions => {:source_id  => source_id_cond,  
                                                   :source_type => 'Contact'},
                                    :include => [:attachments],               
                                    :order => "created_on DESC" 

    respond_to do |format|
      format.js if request.xhr?  
      format.html { @contact.viewed }  
      format.atom { render_feed(@notes, :title => "#{@contact.name || Setting.app_title}: #{l(:label_note_plural)}")  }
      format.xml { render :xml => @contact }   
      format.json { render :text => @contact.to_json, :layout => false } 
      format.vcf { send_data(contact_to_vcard(@contact), :filename => "#{@contact.name}.vcf", :type => 'text/x-vcard;', :disposition => 'attachment') }            
    end
  end
  
  def index   
    find_contacts  
    respond_to do |format|   
      format.html do
        last_notes
        find_tags 
      end
      format.js { render :partial => "list", :layout => false } 
      format.xml { render :xml => find_contacts(false) }  
      format.json { render :text => find_contacts(false).to_json, :layout => false }   
      format.atom { render_feed(find_contacts(false), :title => "#{@project || Setting.app_title}: #{l(:label_contact_plural)}") }
    end
  end
  
  def edit    
  end

  def update  
    if @contact.update_attributes(params[:contact])
      flash[:notice] = l(:notice_successful_update)     
      attach_avatar  
      respond_to do |format|
        format.html { redirect_to :action => "show", :project_id => params[:project_id], :id => @contact }
        format.api  { head :ok }
      end
    else
      respond_to do |format|
        format.html { render "edit", :project_id => params[:project_id], :id => @contact  }
        format.api  { render_validation_errors(@contact) }
      end
    end
  end

  def destroy
    if @contact.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end
    redirect_to :action => "index", :project_id => params[:project_id]
  end
  
  def new  
    @duplicates = []
    @contact = Contact.new   
    @contact.company = params[:company_name] if params[:company_name] 
  end

  def create
    @contact = Contact.new(params[:contact])
    @contact.projects << @project 
    @contact.author = User.current
    if @contact.save
      flash[:notice] = l(:notice_successful_create)
      attach_avatar  
      respond_to do |format|  
        format.html { redirect_to :action => "show", :project_id => params[:project_id], :id => @contact }
        format.api  { render :action => 'show', :status => :created, :location => contact_url(@contact) } 
      end
    else 
      respond_to do |format|      
        format.api  { render_validation_errors(@contact) }   
        format.html { render :action => "new" }
      end
    end
  end

 
  def edit_tags   
    @contact.tags.clear
    @contact.update_attributes(params[:contact])
    redirect_to :action => 'show', :id => @contact, :project_id => @project
  end
  
  def contacts_notes   
    unless request.xhr?  
      find_tags
    end  
    # @notes = Comment.find(:all, 
    #                            :conditions => { :commented_type => "Contact", :commented_id => find_contacts.map(&:id)}, 
    #                            :order => "updated_on DESC")  
   
    contacts = find_contacts(false)
    deals = find_deals
    
    joins = " "
    joins << " LEFT OUTER JOIN #{Contact.table_name} ON #{Note.table_name}.source_id = #{Contact.table_name}.id AND #{Note.table_name}.source_type = 'Contact' "

    cond = "(1 = 1) " 
    cond << "and (#{Contact.table_name}.id in (#{contacts.any? ? contacts.map(&:id).join(', ') : 'NULL'}))"
    cond << " and (#{Note.table_name}.content LIKE '%#{params[:search_note]}%')" if params[:search_note] and request.xhr?
    cond << " and (#{Note.table_name}.author_id = #{params[:note_author_id]})" if !params[:note_author_id].blank?

                                                                                
    @notes_pages, @notes = paginate :notes,
                                    :per_page => 20, 
                                    :joins => joins,      
                                    :conditions => cond, 
                                    :order => "created_on DESC"   
    @notes.compact!   
    
    
    respond_to do |format|   
      format.html { render :partial => "notes/notes_list", :layout => false, :locals => {:notes => @notes, :notes_pages => @notes_pages} if request.xhr?} 
      format.xml { render :xml => @notes }  
    end
  end    
  
  def context_menu 
    @project = Project.find(params[:project_id]) unless params[:project_id].blank? 
    @contacts = Contact.visible.all(:conditions => {:id => params[:selected_contacts]})
    @contact = @contacts.first if (@contacts.size == 1)
    @can = {:edit => (@contact && @contact.editable?) || (@contacts && @contacts.collect{|c| c.editable?}.inject{|memo,d| memo && d}),  
            :delete => @contacts.collect{|c| c.deletable?}.inject{|memo,d| memo && d},
            }   
            
    # @back = back_url        
    render :layout => false  
  end   
  
  def bulk_destroy    
    @contacts = Contact.deletable.find_all_by_id(params[:ids])
    raise ActiveRecord::RecordNotFound if @contacts.empty?
    @contacts.each(&:destroy)
    redirect_to :action => "index", :project_id => params[:project_id]
  end
  
  
private      
  def attach_avatar
    if params[:contact_avatar]    
      params[:contact_avatar][:description] = 'avatar'     
      @contact.avatar.destroy if @contact.avatar 
      Attachment.attach_files(@contact, {"1" => params[:contact_avatar]})  
      render_attachment_warning_if_needed(@contact)    
    end
  end

  def last_notes(count=5)    
    # TODO: Very slow place. n^mю Need to rewrite 
    # @last_notes = find_contacts(false).find(:all, :include => :notes, :limit => count,  :order => 'notes.created_on DESC').map{|c| c.notes}.flatten.first(count)
     
    @last_notes = Note.find(:all, 
                                :conditions => { :source_type => "Contact", :source_id => find_contacts(false).map(&:id).uniq }, 
                                :limit => count,
                                :order => "created_on DESC")                  
    # @last_notes = []                            
  end
  
  def find_contact  
    @contact = Contact.find(params[:id])   
    @project = (@contact.projects.visible.find(params[:project_id]) rescue false) if params[:project_id]
    @project ||= @contact.project 
    # if !(params[:project_id] == @project.identifier)
    #   params[:project_id] = @project.identifier     
    #   redirect_to params
    # end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_tags     
    cond  = ARCondition.new  
    cond << ["#{Project.table_name}.id = ?", @project.id] if @project
    cond << [Contact.allowed_to_condition(User.current, :view_contacts)]   
                                                                                   
    joins = []
    joins << "JOIN #{ActsAsTaggableOn::Tagging.table_name} ON #{ActsAsTaggableOn::Tagging.table_name}.tag_id = #{ActsAsTaggableOn::Tag.table_name}.id "
    joins << "JOIN #{Contact.table_name} ON #{Contact.table_name}.id = #{ActsAsTaggableOn::Tagging.table_name}.taggable_id AND #{ActsAsTaggableOn::Tagging.table_name}.taggable_type =  '#{Contact.name}' " 
    joins << Contact.projects_joins
    
    options = {}
    options[:select] = "#{ActsAsTaggableOn::Tag.table_name}.*, COUNT(DISTINCT #{ActsAsTaggableOn::Tagging.table_name}.taggable_id) AS count"
    options[:conditions] = cond.conditions  
    options[:joins] = joins.flatten   
    options[:group] = "#{ActsAsTaggableOn::Tag.table_name}.id, #{ActsAsTaggableOn::Tag.table_name}.name, #{ActsAsTaggableOn::Tag.table_name}.created_at, #{ActsAsTaggableOn::Tag.table_name}.updated_at, #{ActsAsTaggableOn::Tag.table_name}.color"
    options[:order] = "#{ActsAsTaggableOn::Tag.table_name}.name"
         
    @tags = ActsAsTaggableOn::Tag.find(:all, options) 
  end
  
  def find_deals   
    @deals = []
  end
  
  def find_contacts(pages=true)   
    @tag = ActsAsTaggableOn::TagList.from(params[:tag]).map{|tag| ActsAsTaggableOn::Tag.find_by_name(tag) } unless params[:tag].blank? 

    cond  = ARCondition.new      
    cond << ["#{Contact.table_name}.job_title = ?", params[:job_title]] unless params[:job_title].blank? 
    cond << ["#{Contact.table_name}.assigned_to_id = ?", params[:assigned_to_id]] unless params[:assigned_to_id].blank? 
    cond << ["#{Contact.table_name}.is_company = ?", params[:is_company]] unless params[:is_company].blank?   
                                                             
    scope = Contact.scoped({}) 
    scope = scope.in_project(@project.id) if @project  
    params[:search].split(' ').collect{ |search_string| scope = scope.live_search(search_string) } if !params[:search].blank? 
    scope = scope.visible
    
    scope = scope.tagged_with(params[:tag]) if !params[:tag].blank?  
    scope = scope.scoped(:conditions => cond.conditions)
    scope = scope.order_by_name
    
    @contacts_count = scope.count
    
    
    if pages    
      page_size = params[:page_size].blank? ? 20 : params[:page_size].to_i
      @contacts_pages = Paginator.new(self, @contacts_count, page_size, params[:page])     
      @offset = @contacts_pages.current.offset  
      @limit =  @contacts_pages.items_per_page 
       
      scope = scope.scoped :include => [:tags, :avatar], :limit  => @limit, :offset => @offset
      @contacts = scope
      fake_name = @contacts.first.name if @contacts.length > 0
    end
    scope

  end  
  
  def parse_params_for_bulk_contact_attributes(params)
    attributes = (params[:contact] || {}).reject {|k,v| v.blank?}
    attributes.keys.each {|k| attributes[k] = '' if attributes[k] == 'none'}
    attributes[:custom_field_values].reject! {|k,v| v.blank?} if attributes[:custom_field_values]
    attributes
  end
  
  
end
