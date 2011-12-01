require_dependency 'issue'  

require 'dispatcher'   
 
# Patches Redmine's Issues dynamically. Adds a relationship
# Issue +has_many+ to ArchDecisionIssue
# Copied from dvandersluis' redmine_resources plugin: 
# http://github.com/dvandersluis/redmine_resources/blob/master/lib/resources_issue_patch.rb
module RedmineContacts
  module Patches    
    
    module IssuePatch
      def self.included(base) # :nodoc: 
        base.class_eval do    
          unloadable # Send unloadable so it will not be unloaded in development
          has_and_belongs_to_many :contacts, :order => "last_name, first_name", :uniq => true
        end  
      end  
    end  

    module ProjectPatch
      def self.included(base) # :nodoc: 
        base.class_eval do    
          unloadable # Send unloadable so it will not be unloaded in development
          has_and_belongs_to_many :contacts, :order => "last_name, first_name", :uniq => true  
        end  
      end  
    end  
    
    module TagPatch   
      module InstanceMethods    
        def color_name
          return "#" + "%06x" % self.color unless self.color.nil?
        end

        def color_name=(clr)
          self.color = clr.from(1).hex
        end

        def assign_color
          self.color = (rand * 0xffffff)  
        end
      end
  
      def self.included(base) # :nodoc: 
    
        # base.extend(ClassMethods)
 
        # base.send(:include, InstanceMethods)
    
        # Same as typing in the class    
        base.send :include, InstanceMethods
        
        base.class_eval do    
          before_create :assign_color
        end  
      end  
      
    end     
    
       

  end
end

Dispatcher.to_prepare do  

  unless Project.included_modules.include?(RedmineContacts::Patches::ProjectPatch)
    Project.send(:include, RedmineContacts::Patches::ProjectPatch)
  end

  unless Issue.included_modules.include?(RedmineContacts::Patches::IssuePatch)
    Issue.send(:include, RedmineContacts::Patches::IssuePatch)
  end

  unless ActsAsTaggableOn::Tag.included_modules.include?(RedmineContacts::Patches::TagPatch)
    ActsAsTaggableOn::Tag.send(:include, RedmineContacts::Patches::TagPatch)
  end
end

