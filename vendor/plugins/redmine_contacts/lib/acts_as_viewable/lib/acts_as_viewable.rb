module ActsAsViewable
  module Viewable
    def self.included(base)
      base.extend ClassMethods
    end    

    module ClassMethods
      def acts_as_viewable(options   = {})
        cattr_accessor :viewable_options
        self.viewable_options        = {}
        viewable_options[:info]      = options.delete(:info) || "info".to_sym

        has_many :views, :class_name => "RecentlyViewed", :as => :viewed, :dependent => :delete_all, :order => "#{RecentlyViewed.table_name}.updated_at DESC"

        # attr_reader :info

        send :include, ActsAsViewable::Viewable::InstanceMethods
      end
    end

    module InstanceMethods
      def self.included(base)
        base.extend ClassMethods
      end

      def viewed(user                = User.current)     
        rv                           = (self.views.find(:first, :conditions => {:viewer_id => User.current.id}) || self.views.new(:viewer => user))
        rv.increment!(:views_count)
        rv.save
      end

      module ClassMethods
      end
    end

  end
end  

Dispatcher.to_prepare do  

  unless ActiveRecord::Base.included_modules.include?(ActsAsViewable::Viewable)
    ActiveRecord::Base.send(:include, ActsAsViewable::Viewable)  
  end
end
