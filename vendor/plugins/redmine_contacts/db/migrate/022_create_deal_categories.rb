class CreateDealCategories < ActiveRecord::Migration
  def self.up
    create_table :deal_categories do |t|
      t.column :name, :string, :null => false
      t.column :project_id, :integer
    end  
    
    add_column :deals, :category_id, :integer  
    add_column :deal_statuses, :is_closed, :boolean, :null => false, :default => false   
    add_column :deal_statuses, :color, :integer, :null => false, :default => "AAAAAA".hex   
    
    create_table :deal_statuses_projects, :id => false do |t|
      t.column :project_id, :integer, :default => 0, :null => false
      t.column :deal_status_id, :integer, :default => 0, :null => false
    end
    
    add_index :deal_statuses_projects, [:project_id, :deal_status_id]          
    
    self.update_deals   
    
  end

  def self.down
    drop_table :deal_categories
    drop_table :deal_statuses_projects
    remove_column :deals, :category_id
    remove_column :deal_statuses, :is_closed  
    remove_column :deal_statuses, :color  
  end
  
  def self.update_deals
    ds_new = DealStatus.create(:name  => "New", :is_closed => false, :is_default => true, :color => "AAAAAA".hex)
    ds_fc = DealStatus.create(:name  => "First contact", :is_closed => false, :is_default => false, :color => "00BFFF".hex)
    ds_n = DealStatus.create(:name  => "Negotiations", :is_closed => false, :is_default => false, :color => "FFA500".hex)                     
    ds_p = DealStatus.create(:name  => "Pending", :is_closed => false, :is_default => false, :color => "20B2AA".hex)
    ds_won = DealStatus.create(:name  => "Won", :is_closed => true, :is_default => false, :color => "008000".hex)
    ds_lost = DealStatus.create(:name  => "Lost", :is_closed =>true, :is_default => false, :color => "FF0000".hex)
    
    Deal.find(:all).each do |deal|
      deal.status_id = -deal.status_id    
      deal.project.deal_statuses = [ds_new, ds_fc, ds_n, ds_p, ds_won, ds_lost]
      deal.save
    end  
    
    Deal.find(:all).each do |deal|
      case deal.status_id 
      when 0
        deal.status = ds_new
      when -1
        deal.status = ds_fc
      when -2
        deal.status = ds_n
      when -3
        deal.status = ds_p
      when -4
        deal.status = ds_won
      when -5
        deal.status = ds_lost
      end
      deal.save
    end  
    
    DealProcess.find(:all).each do |process|  
      process.old_value = -process.old_value if process.old_value
      process.value = -process.value 
      process.save
    end  
        
    DealProcess.find(:all).each do |process|   
      case process.old_value 
      when 0
        process.old_value = ds_new.id
      when -1
        process.old_value = ds_fc.id
      when -2
        process.old_value = ds_n.id
      when -3
        process.old_value = ds_p.id
      when -4
        process.old_value = ds_won.id
      when -5
        process.old_value = ds_lost.id
      end        
      
      case process.value 
      when 0
        process.value = ds_new.id
      when -1
        process.value = ds_fc.id
      when -2
        process.value = ds_n.id
      when -3
        process.value = ds_p.id
      when -4
        process.value = ds_won.id
      when -5
        process.value  = ds_lost.id
      end
    
      process.save
    end  
    
  end
end
