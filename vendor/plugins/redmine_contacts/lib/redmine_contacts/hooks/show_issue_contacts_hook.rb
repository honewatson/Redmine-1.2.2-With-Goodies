include ContactsHelper           
include NotesHelper

module RedmineContacts
  module Hooks
    class ShowIssueContactsHook < Redmine::Hook::ViewListener     
      render_on :view_issues_sidebar_planning_bottom, :partial => "issues/contacts", :locals => {:contact_issue => @issue}  
    end   
  end
end
