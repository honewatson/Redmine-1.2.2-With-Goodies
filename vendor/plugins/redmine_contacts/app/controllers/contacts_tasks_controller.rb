class ContactsTasksController < ApplicationController
  unloadable    
  
  before_filter :find_project_by_project_id, :authorize, :except => [:index] 
  before_filter :find_optional_project, :only => :index  
  before_filter :find_contact, :except => [:index, :add, :close]    
  before_filter :find_issue, :except => [:index, :new]
  
  helper :contacts
  
  def index   
    cond = "(1=1)"
    # cond = "issues.assigned_to_id = #{User.current.id}"
    cond << " and issues.project_id = #{@project.id}" if @project      
    cond << " and (issues.assigned_to_id = #{params[:assigned_to]})" unless params[:assigned_to].blank?
    
    @contacts_issues = Issue.visible.find(:all, 
                                          :joins => "INNER JOIN contacts_issues ON issues.id = contacts_issues.issue_id", 
                                          # :group => :issue_id,
                                          :conditions => cond,
                                          :order => "issues.due_date")    
    @users = assigned_to_users                                      
  end   
  
  def new
    issue = Issue.new
    issue.subject = params[:task_subject]
    issue.project = @project
    issue.tracker_id = params[:task_tracker]
    issue.author = User.current
    issue.due_date = params[:due_date]
    issue.assigned_to_id = params[:assigned_to]
    issue.description = params[:task_description]
    issue.status = IssueStatus.default
    if issue.save
      flash[:notice] = l(:notice_successful_add)
      @contact.issues << issue
      @contact.save
      redirect_to :back
      return
    else
      redirect_to :back 
    end           
  end   
  
  
  def add    
    @show_form = "true"    

    if params[:contact_id] && request.post? then    
      find_contact
      @contact.issues << @issue
      @contact.save
    end
    
    respond_to do |format|
      format.html { redirect_to :back }  
      format.js do
        render :update do |page|   
          page.replace_html 'issue_contacts', :partial => 'issues/contacts'
        end
      end
    end
  end  

  def delete    
    @issue.contacts.delete(@contact)
    respond_to do |format|
      format.html { redirect_to :back }
      format.js do
        render :update do |page|
          page.replace_html 'issue_contacts', :partial => 'issues/contacts'
        end
      end
    end    
  end

  def close
    @issue.status = IssueStatus.find(:first, :conditions =>  { :is_closed => true })    
    @issue.save
    respond_to do |format|
      format.js do 
        render :update do |page|  
            page["issue_#{params[:issue_id]}"].visual_effect :fade 
        end
      end     
      format.html {redirect_to :back }
    end
    
  end     
  
  private
  
  def find_contact 
    @contact = Contact.find(params[:contact_id]) 
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_issue 
    @issue = Issue.find(params[:issue_id]) 
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def assigned_to_users
    user_values = []  
    project = @project
    user_values << ["<< #{l(:label_all)} >>", ""]
    user_values << ["<< #{l(:label_me)} >>", User.current.id] if User.current.logged?
    if project
      user_values += project.users.sort.collect{|s| [s.name, s.id.to_s] }
    else
      project_ids = Project.all(:conditions => Project.visible_condition(User.current)).collect(&:id)
      if project_ids.any?
        # members of the user's projects
        user_values += User.active.find(:all, :conditions => ["#{User.table_name}.id IN (SELECT DISTINCT user_id FROM members WHERE project_id IN (?))", project_ids]).sort.collect{|s| [s.name, s.id.to_s] }
      end
    end    
  end
  
  
end