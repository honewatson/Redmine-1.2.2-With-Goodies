class CreateDeals < ActiveRecord::Migration
  def self.up
    rename_table :customers, :contacts
    
    create_table :deals do |t|
      t.string :name
      t.text :background  
      t.integer :comments_count, :default => 0,  :null => false  
      t.integer :currency        
      t.decimal :price, :precision => 12, :scale => 2
      t.integer :price_type
      t.integer :duration

      t.references :project
      t.references :author
      
      t.timestamps
    end  
    add_index :deals, :project_id
    
     
    
    create_table :contacts_deals, :force => true, :id => false  do |t|
      t.references :deal
      t.references :contact
    end
    add_index :contacts_deals, [:deal_id, :contact_id]
         
    
    create_table :contacts_issues, :id => false do |t|
      t.column :issue_id, :integer, :default => 0, :null => false
      t.column :contact_id, :integer, :default => 0, :null => false
    end       
    add_index :contacts_issues, [:issue_id, :contact_id]

    
    add_column :contacts, :author_id, :integer, :default => 0,  :null => false    
    
  end

  def self.down      
    remove_column :contacts, :author_id
    
    drop_table :contacts_issues
    drop_table :contacts_deals
    drop_table :deals   
    
    rename_table :contacts, :customers
    
    
  end
end
