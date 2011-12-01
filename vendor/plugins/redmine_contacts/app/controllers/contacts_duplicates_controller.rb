class ContactsDuplicatesController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id, :authorize
  before_filter :find_contact, :except => :duplicates    

  def index     
  end     
  
  def duplicates
    search_first_name = params[:contact][:first_name] if params[:contact] && !params[:contact][:first_name].blank? 
    search_last_name = params[:contact][:last_name] if params[:contact] && !params[:contact][:last_name].blank?   
    search_middle_name = params[:contact][:middle_name] if params[:contact] && !params[:contact][:middle_name].blank?   
                                      
    @contact = (Contact.find(params[:contact_id]) if !params[:contact_id].blank?) || Contact.new  
    @contact.first_name = search_first_name || ""
    @contact.last_name = search_last_name || "" 
    @contact.middle_name = search_middle_name || "" 
    respond_to do |format|   
      format.html {render :partial => "duplicates", :layout => false if request.xhr?} 
    end
  end   
  
  def merge    
    @dublicate = Contact.find(params[:dublicate_id])   
    @dublicate.notes << @contact.notes
    @dublicate.deals << @contact.deals
    @dublicate.issues << @contact.issues
    @dublicate.projects << @contact.projects    
    @dublicate.tags << @contact.tags   
    if @dublicate.save && @contact.destroy
      flash[:notice] = l(:notice_successful_merged)     
      redirect_to :controller => "contacts", :action => "show", :project_id => @project, :id => @dublicate
    else
      render "index"
    end
    
  rescue ActiveRecord::RecordNotFound
     redirect_to :controller => "contacts", :action => "show", :project_id => @project, :id => @contact
  end

  private 
  
  def find_contact 
    @contact = Contact.find(params[:contact_id]) 
  rescue ActiveRecord::RecordNotFound
    render_404 if !request.xhr?
  end
end