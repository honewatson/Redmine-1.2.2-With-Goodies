class CreateContactsProjects < ActiveRecord::Migration         
  def self.up  
    create_table :contacts_projects, :id => false do |t|
      t.column :project_id, :integer, :default => 0, :null => false
      t.column :contact_id, :integer, :default => 0, :null => false
    end
    
    add_index :contacts_projects, [:project_id, :contact_id]          

    
    Contact.find(:all).each do |contact|
      project = Project.find_by_id(contact.project_id)
      contact.projects << project if project 
    end      
    
    remove_column :contacts, :project_id
    
  end

  def self.down
    drop_table :contacts_projects 
  end      
                                                  
end         
