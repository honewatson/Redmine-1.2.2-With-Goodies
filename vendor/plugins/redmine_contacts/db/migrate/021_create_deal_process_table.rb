class CreateDealProcessTable < ActiveRecord::Migration
  def self.up
    create_table :deal_processes, :force => true do |t|
      t.references :deal, :null => false
      t.references :author, :null => false
      t.integer :old_value
      t.integer :value, :null => false
      t.datetime :created_at
    end  
    
    add_index :deal_processes, :author_id
    add_index :deal_processes, :deal_id
    
    add_column :deals, :contact_id, :integer
    add_index :deals, :contact_id
    
    create_table :deal_statuses, :force => true do |t|
      t.string :name, :null => false
      t.integer :position
      t.boolean :is_default, :null => false
    end  

    Deal.find(:all).each do |deal|
      deal.contact = deal.contacts.first 
      deal.status_id = -deal.status_id  
      deal.save
    end  
    
    Deal.find(:all).each do |deal|
      case deal.status_id 
      when -1
        deal.status_id = 4
      when -2
        deal.status = 5
      end
      deal.save 
      
      DealProcess.create(:deal_id => deal.id, :author_id => deal.author_id, :value => deal.status_id, :created_at => deal.created_on)
      
    end      
        
    
  end

  def self.down
    remove_index :deals, :contact_id
    remove_index :deal_processes, :deal_id
    remove_index :deal_processes, :author_id
    remove_column :deals, :contact_id
    drop_table :deal_statuses
    drop_table :deal_processes
  end
end
