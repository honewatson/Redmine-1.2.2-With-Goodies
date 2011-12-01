require File.dirname(__FILE__) + '/../test_helper'
require 'notes_controller'

class NotesControllerTest < ActionController::TestCase
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
           :tags,
           :taggings

  def setup
    RedmineContacts::TestCase.prepare

    @controller  = NotesController.new
    @request     = ActionController::TestRequest.new
    @response    = ActionController::TestResponse.new
    User.current = nil  
    @request.env['HTTP_REFERER'] = 'http://localhost:3000'
  end
  
  test "should post add note to contact" do
    @request.session[:user_id] = 1
    assert_difference 'Note.count' do
      post :add_note, :project_id => 1,  
                    :note => {
                                :subject => "Note subject", 
                                :content => "Note *content*"},
                    :source_type => Contact.to_s,
                    :source_id => 1

    end

    note = Note.find(:first, :conditions => {:subject => "Note subject", :content => "Note *content*"})
    assert_not_nil note
    assert_equal 1, note.source_id
    assert_equal Contact, note.source.class
  end  
  
  test "should put update" do
    @request.session[:user_id] = 1

    note = Note.find(1)
    old_content = note.content
    new_content = 'New note content'
    
    put :update, :note_id => 1, :project_id => 1, :note => {:content => new_content}
    assert_redirected_to :action => 'show', :project_id => note.source.project, :note_id => note.id
    note.reload
    assert_equal new_content, note.content 

  end
  
end
