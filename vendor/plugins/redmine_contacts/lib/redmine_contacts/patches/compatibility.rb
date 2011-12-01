require_dependency 'application_controller'  

module RedmineContacts
  module Patches    
    
    module ApplicationControllerCompatibilityPatch
      
      module InstanceMethods    

        # Find project of id params[:id]
        def find_project
          @project = Project.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render_404
        end

        # Find project of id params[:project_id]
        def find_project_by_project_id
          @project = Project.find(params[:project_id])
        rescue ActiveRecord::RecordNotFound
          render_404
        end

        # Find a project based on params[:project_id]
        # TODO: some subclasses override this, see about merging their logic
        def find_optional_project
          @project = Project.find(params[:project_id]) unless params[:project_id].blank?
          allowed = User.current.allowed_to?({:controller => params[:controller], :action => params[:action]}, @project, :global => true)
          allowed ? true : deny_access
        rescue ActiveRecord::RecordNotFound
          render_404
        end
        
      end
  
      def self.included(base) # :nodoc: 
        base.send(:include, InstanceMethods)
      end
        
    end
    
    
    
  end
end  

Dispatcher.to_prepare do  

  if !ApplicationController.included_modules.include?(RedmineContacts::Patches::ApplicationControllerCompatibilityPatch) && (Redmine::VERSION.to_a.first(3).join('.') < '1.1.0')
    ApplicationController.send(:include, RedmineContacts::Patches::ApplicationControllerCompatibilityPatch)
  end

end