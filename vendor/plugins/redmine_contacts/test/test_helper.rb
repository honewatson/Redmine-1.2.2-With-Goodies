require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

Engines::Testing.set_fixture_path    

class RedmineContacts::TestCase       
  def self.prepare
    Role.find(1, 2, 3, 4).each do |r| 
      r.permissions << :view_contacts
      r.save
    end
    Role.find(1, 2).each do |r| 
      r.permissions << :edit_contacts
      r.save
    end

    Role.find(1, 2, 3).each do |r| 
      r.permissions << :view_deals
      r.save
    end 
    Project.find(1, 2, 3, 4, 5).each do |project| 
      EnabledModule.create(:project => project, :name => 'contacts_module')
    end
  end   
  
end