# Redmine contact plugin

require_library_or_gem "acts-as-taggable-on"

begin
  require_library_or_gem 'RMagick' unless Object.const_defined?(:Magick)
rescue LoadError
  # RMagick is not available
end

require 'redmine'    

require 'redmine_contacts/patches/contacts_issue_patch'
require 'redmine_contacts/patches/attachments_patch' 
require 'redmine_contacts/patches/auto_completes_controller_patch'
require 'redmine_contacts/patches/mailer_patch'
require 'redmine_contacts/patches/compatibility'

require 'redmine_contacts/hooks/show_issue_contacts_hook'   

require 'acts_as_viewable/init' 

RAILS_DEFAULT_LOGGER.info 'Starting Contact plugin for RedMine'

Redmine::Plugin.register :contacts do
  name 'Contacts plugin'
  author 'Kirill Bezrukov'
  description 'This is light version of a CRM plugin for Redmine that can be used to track contacts information'
  version '2.2-light'
  url 'http://wwww.redminecrm.com'
  author_url 'mailto:kirill.bezrukov@gmail.com' if respond_to? :author_url

  requires_redmine :version_or_higher => '1.2.0'   
  
  settings :default => {
    :use_gravatars => false, 
    :name_format => :lastname_firstname.to_s,
    :auto_thumbnails  => true,
    :max_thumbnail_file_size => 300
  }, :partial => 'settings/contacts'
  
  
  project_module :contacts_module do
    permission :view_contacts, :contacts => [:show, 
                                             :index, 
                                             :live_search, 
                                             :contacts_notes, 
                                             :context_menu
                                             ],
                               :contacts_tasks => :index, 
                               :notes => [:show]

    permission :edit_contacts, :contacts => [:edit, 
                                             :update, 
                                             :new, 
                                             :create,
                                             :edit_tags],
                                :notes => [:add_note, :destroy, :edit, :update],
                                :contacts_tasks => [:new, :add, :delete, :close],
                                :contacts_duplicates => [:index, :merge, :duplicates],
                                :contacts_projects => [:add, :delete]
    permission :send_contacts_mail, :contacts => [:edit_mails, :send_mails]
    permission :add_notes, :notes => :add_note   
    permission :delete_notes, :notes => [:destroy, :edit, :update]
    permission :delete_own_notes, :notes => [:destroy, :edit, :update]                                      
    permission :delete_contacts, :contacts => [:destroy, :bulk_destroy]
    
  end

  menu :project_menu, :contacts, {:controller => 'contacts', :action => 'index'}, :caption => :contacts_title, :param => :project_id
  # menu :project_menu, :deals, { :controller => 'deals', :action => 'index' }, :caption => :label_deal_plural, :param => :project_id
  
  menu :top_menu, :contacts, {:controller => 'contacts', :action => 'index'}, :caption => :contacts_title
  
  activity_provider :contacts, :default => false, :class_name => ['Note']  

  Redmine::Search.map do |search|
    search.register :contacts
    search.register :notes
  end

  # activity_provider :contacts, :default => false   
end

