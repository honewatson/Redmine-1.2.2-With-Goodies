class ContactsTagsController < ApplicationController
  unloadable
  before_filter :require_admin 
  before_filter :find_tag

  def index
  end

  def edit
  end 
  
  def destroy  
    if @tag.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:notice_unsuccessful_delete)
    end
    redirect_to :back
    
  end
   
  
  def update  
    @tag.color_name = params[:tag][:color_name]
    @tag.name = params[:tag][:name]    
    if @tag.save 
                
      flash[:notice] = l(:notice_successful_update)  
      respond_to do |format| 
        format.html { redirect_to :controller => 'settings', :action => 'plugin', :id => 'contacts', :tab => "tags"} 
        format.xml  { } 
      end  
    else           
      respond_to do |format|
        format.html { render :action => "edit"}
      end
    end
    
  end
  
  private
  
  def find_tag
    @tag = ActsAsTaggableOn::Tag.find(params[:id]) 
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
