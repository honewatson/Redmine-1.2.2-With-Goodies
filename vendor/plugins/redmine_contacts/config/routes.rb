#custom routes for this plugin
ActionController::Routing::Routes.draw do |map|
  map.with_options :controller => 'contacts' do |contacts_routes|
    contacts_routes.connect "contacts", :conditions => { :method => [:get, :post] }, :action => 'index'   
    contacts_routes.connect "contacts.:format", :conditions => { :method => :get }, :action => 'index'   
    contacts_routes.connect "contacts/:id", :conditions => { :method => :get }, :action => 'show', :id => /\d+/
    contacts_routes.connect "contacts/:id.:format", :conditions => { :method => :get }, :action => 'show', :id => /\d+/
    contacts_routes.connect "contacts/notes", :conditions => { :method => [:get, :post] }, :action => 'contacts_notes'
    contacts_routes.connect "projects/:project_id/contacts", :conditions => { :method => [:get, :post] }, :action => 'index'
    contacts_routes.connect "projects/:project_id/contacts.:format", :conditions => { :method => :get }, :action => 'index'
    contacts_routes.connect "projects/:project_id/contacts/create", :conditions => { :method => :post }, :action => 'create'
    contacts_routes.connect "projects/:project_id/contacts/new", :conditions => { :method => :get }, :action => 'new'
    contacts_routes.connect "projects/:project_id/contacts/:id", :conditions => { :method => :get }, :action => 'show', :id => /\d+/
    contacts_routes.connect "projects/:project_id/contacts/:id.:format", :conditions => { :method => :get }, :action => 'show', :id => /\d+/
    contacts_routes.connect "projects/:project_id/contacts/:id/update", :conditions => { :method => :post }, :action => 'update', :id => /\d+/  
    contacts_routes.connect "projects/:project_id/contacts/:id/edit", :conditions => { :method => :get }, :action => 'edit', :id => /\d+/  
    contacts_routes.connect "projects/:project_id/contacts/:id/:action", :conditions => { :method => :post }, :action => /edit|destroy/, :id => /\d+/  
    contacts_routes.connect "projects/:project_id/contacts/notes", :conditions => { :method => [:get, :post]}, :action => 'contacts_notes'
    contacts_routes.connect "projects/:project_id/contacts/edit_tags", :conditions => { :method => :post }, :action => 'edit_tags'
  end
  
  map.with_options :controller => 'contacts_tasks' do |contacts_issues_routes|  
    contacts_issues_routes.connect "projects/:project_id/contacts/tasks", :action => 'index' 
    contacts_issues_routes.connect "projects/:project_id/contacts/:contact_id/new_task", :conditions => { :method => :post }, :action => 'new' 
    contacts_issues_routes.connect "contacts/tasks", :action => 'index'
  end

  map.with_options :controller => 'contacts_duplicates' do |contacts_issues_routes|  
    contacts_issues_routes.connect "contacts/:contact_id/duplicates"
  end
  
  map.with_options :controller => 'deal_categories' do |categories|
    categories.connect 'projects/:project_id/deal_categories/new', :action => 'new'
  end

  map.with_options :controller => 'sale_funel' do |sale_funel|
    sale_funel.connect 'projects/:project_id/sale_funel', :action => 'index'
    sale_funel.connect 'sale_funel', :action => 'index'
  end


  map.with_options :controller => 'deals' do |deals_routes|
    deals_routes.connect "deals", :conditions => { :method => :get }, :action => 'index'
    deals_routes.connect "projects/:project_id/deals", :action => 'index'
    deals_routes.connect "projects/:project_id/deals/create", :conditions => { :method => :post }, :action => 'create'
    deals_routes.connect "projects/:project_id/deals/new", :conditions => { :method => :get }, :action => 'new'
    deals_routes.connect "deals/:id", :conditions => { :method => :get }, :action => 'show', :id => /\d+/
    deals_routes.connect "deals/:id/update", :conditions => { :method => :post }, :action => 'update', :id => /\d+/
    deals_routes.connect "deals/:id/destroy", :conditions => { :method => :post}, :action => 'destroy', :id => /\d+/
    deals_routes.connect "deals/:id/edit", :conditions => { :method => :get }, :action => 'edit', :id => /\d+/
  end
  
  map.with_options :controller => 'notes' do |notes_routes|
    notes_routes.connect "notes/:note_id", :conditions => { :method => :get }, :action => 'show', :note_id => /\d+/
    notes_routes.connect "notes/show/:note_id", :conditions => { :method => :get }, :action => 'show', :note_id => /\d+/
    notes_routes.connect "notes/:note_id/edit", :conditions => { :method => :get }, :action => 'edit', :note_id => /\d+/
    notes_routes.connect "notes/:note_id/update", :conditions => { :method => :post }, :action => 'update', :note_id => /\d+/
    notes_routes.connect "notes/:note_id/destroy_note", :action => 'destroy_note', :note_id => /\d+/
  end
  
end