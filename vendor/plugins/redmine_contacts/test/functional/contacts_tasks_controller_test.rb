require File.dirname(__FILE__) + '/../test_helper'      
require 'contacts_tasks_controller'

class ContactsTasksControllerTest < ActionController::TestCase  
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
           :notes,
           :contacts_issues,
           :tags,
           :taggings
  
  def setup
    RedmineContacts::TestCase.prepare

    @controller = ContactsTasksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil    
    
    
  end
  
  test "should get index" do
    @request.session[:user_id] = 1
    
    get :index # TODO: DEPRECATION WARNING
    assert_response :success
    assert_template :index
    assert_not_nil assigns(:contacts_issues)
  end  

  test "should get index in project" do
    # log_user('admin', 'admin')   
    @request.session[:user_id] = 1
    Setting.default_language = 'en'
    
    get :index, :project_id => 1
    assert_response :success
    assert_template :index
    assert_not_nil assigns(:contacts_issues)
    assert_not_nil assigns(:project)
    assert_select 'tr#issue_1 td a', "Can't print recipes"       
    

    # private projects hidden
    # assert_no_tag :tag => 'a', :content => /Issue of a private subproject/
    # assert_no_tag :tag => 'a', :content => /Issue on project 2/
    # project column
    # assert_tag :tag => 'th', :content => /Project/
  end  

  test "should get new" do      
    @request.session[:user_id] = 1
    @request.env['HTTP_REFERER'] = 'http://localhost:3000/contacts/1'
    get :new, :project_id => 1, :contact_id => 1, :task_subject => "test subject", :task_tracker => 1, :due_date => Date.to_s, :assigned_to => 1, :task_description => "Test task descripiton"    
    assert_response 302   
    # assert_not_nil Issue.find_by_subject("test subject")
  end
  

end
