require_dependency 'attachments_controller'  
require_dependency 'attachment' 

module RedmineContacts
  module Patches    
    
    module AttachmentsControllerPatch
      
      module InstanceMethods    

        def thumbnail  
          # Dir.mkdir(Attachment.thumbnails_path) if !File.exists?(Attachment.thumbnails_path)
                
          params[:size] ||= 64       
          size = params[:size].to_i

          # "#{@attachment.diskfile}-#{@attachment.digest} + .#{size}x#{size}.thumb.png"
          thumb_file_name = File.join(Attachment.storage_path, "#{@attachment.digest}.thumb.#{size}x#{size}.png") 

          if FileTest.exists?(thumb_file_name) 
            send_file(thumb_file_name, :disposition => 'inline', :type => 'image/png', :filename => "#{@attachment.filename}.png")
          else  

            img = Magick::Image.read(@attachment.diskfile).first  
            rows, cols = img.rows, img.columns   

            thumb = (size < rows || size < cols) ? img.resize_to_fill(size, size) : img

            thumb = thumb.sharpen(0.7,6)
            # thumb = thumb.background_color = "White"
            # thumb.format = 'PNG'  
            thumb.write(thumb_file_name)     

            send_file(thumb_file_name, :disposition => 'inline', :type => 'image/png', :filename => "#{@attachment.filename}.png") 
          end  
        end 
        

      end
  
      def self.included(base) # :nodoc: 
        base.send(:include, InstanceMethods)
      end
        
    end
    
    module AttachmentPatch   
      module ClassMethods
        def delete_all_thumbnails  
          Dir.glob(Attachment.storage_path + "/*.thumb.*").map {|f| File.delete(f)}
        end
        
      end
      
      module InstanceMethods    
        
        def is_thumbnailable?
          (self.is_pdf? && self.filesize < 600.kilobytes) || self.image?
        end
        
        def is_pdf?
          self.filename =~ /\.(pdf)$/i
        end
         
        def delete_thumbnails  
          Dir.glob(self.storage_path + "/#{self.digest}.thumb.*").map {|f| File.delete(f)}
        end

      end
  
      def self.included(base) # :nodoc: 
    
        base.extend(ClassMethods)
 
        # base.send(:include, InstanceMethods)
    
        # Same as typing in the class    
        base.send :include, InstanceMethods
        
        base.class_eval do 
          unloadable   
          after_destroy :delete_thumbnails 
          
        end  
      end  
      
    end     
    
    
  end
end  

Dispatcher.to_prepare do  

  unless Attachment.included_modules.include?(RedmineContacts::Patches::AttachmentPatch)
    Attachment.send(:include, RedmineContacts::Patches::AttachmentPatch)
  end

  unless AttachmentsController.included_modules.include?(RedmineContacts::Patches::AttachmentsControllerPatch)
    AttachmentsController.send(:include, RedmineContacts::Patches::AttachmentsControllerPatch)
  end

end