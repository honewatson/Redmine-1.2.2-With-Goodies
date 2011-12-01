class ContactsProjectsController < ApplicationController
  unloadable
  
  before_filter :find_project_by_project_id, :authorize 
  before_filter :find_contact, :except => [:index, :close]    
  
  helper :contacts
  
  def add
    @show_form = "true"          
    # find_contact
    if params[:new_project_id] then    
      project = Project.find(params[:new_project_id])
      @contact.projects << project
      @contact.save if request.post?   
    end
    respond_to do |format|
      format.html { redirect_to :back }  
      format.js do
        render :update do |page|   
          page.replace_html 'contact_projects', :partial => 'related'
        end
      end
    end
    
  end       

  def delete  
    deny_access if @contact.projects.size <= 1 
    @contact.projects.delete(Project.find(params[:disconnect_project_id]))
    respond_to do |format|
      format.html { redirect_to :back }
      format.js do
        render :update do |page|
          page.replace_html 'contact_projects', :partial => 'related'
        end
      end
    end    
  end
  
  private
  
  def find_contact 
    @contact = Contact.find(params[:contact_id]) 
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
end