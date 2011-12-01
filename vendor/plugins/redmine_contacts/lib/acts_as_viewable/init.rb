$LOAD_PATH.unshift(File.dirname(__FILE__))

require "lib/acts_as_viewable"

$LOAD_PATH.shift

Dispatcher.to_prepare do  
  unless ActiveRecord::Base.included_modules.include?(ActsAsViewable::Viewable)
    ActiveRecord::Base.send(:include, ActsAsViewable::Viewable)  
  end
end
