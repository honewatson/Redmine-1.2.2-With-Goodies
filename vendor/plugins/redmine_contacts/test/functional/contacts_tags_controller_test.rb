require File.dirname(__FILE__) + '/../test_helper'      
require 'contacts_tags_controller'

class ContactsTagsControllerTest < ActionController::TestCase  
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries,
           :contacts,
           :contacts_projects,
           :tags,
           :taggings
  
  def setup
    RedmineContacts::TestCase.prepare

    @controller = ContactsTagsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil   
    
    @request.env['HTTP_REFERER'] = 'http://localhost:3000'
  end

  # 
  # test "should get index" do
  #   # log_user('admin', 'admin')   
  #   @request.session[:user_id] = 1
  #   
  #   get "/settings/plugin/contacts", :tab => "tags"
  #   assert_response :success
  #   assert_not_nil assigns(:tags)
  #   assert_select 'div#tab-content-tags table td a', "main"
  #   assert_select 'div#tab-content-tags table td a', "test"
  # end  

  test "should get edit" do 
    @request.session[:user_id] = 1
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:tag)
    assert_equal ActsAsTaggableOn::Tag.find(1), assigns(:tag)
  end

  test "should post update" do 
    @request.session[:user_id] = 1
    tag1 = ActsAsTaggableOn::Tag.find(1)  
    old_name = tag1.name
    new_name = "updated main"
    post :update, :id => 1, :tag => {:name => new_name, :color_name=>"#000000"}
    assert_redirected_to :controller => 'settings', :action => 'plugin', :id => "contacts", :tab => "tags"
    tag1.reload
    assert_equal new_name, tag1.name 
  end  

  test "should post destroy" do
    @request.session[:user_id] = 1
    assert_difference 'ActsAsTaggableOn::Tag.count', -1 do
      post :destroy, :id => 1
      assert_response 302
    end
  end    

end
