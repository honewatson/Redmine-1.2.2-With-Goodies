module NotesHelper   
  
  def add_note_ajax(note, note_source, show_info = false)
    render :update do |page|   
      page[:add_note_form].reset
      page.insert_html :top, "notes", :partial => 'notes/note_item', :object => note, :locals => {:show_info => show_info, :note_source => note_source}
      page["note_#{@note.id}"].visual_effect :highlight 
    end
  end 
  
  def render_contacts_notes(note, project, options={})
    content = ''
    editable = User.current.logged? && (User.current.allowed_to?(:edit_contact_notes, project) || (note.author == User.current && User.current.allowed_to?(:edit_own_contact_notes, project)))
    links = []
    if !note.description.blank?
      links << link_to_in_place_notes_editor(image_tag('edit.png'), "note-#{note.id}", 
                                             { :controller => 'notes', :action => 'edit', :id => note },
                                                :title => l(:button_edit)) if editable
    end
    content << content_tag('div', links.join(' '), :class => 'contextual') unless links.empty?
    content << textilizable(note, :description)
    css_classes = "wiki"
    css_classes << " editable" if editable
    content_tag('div', content, :id => "note-#{note.id}", :class => css_classes)
  end
  
  def link_to_in_place_notes_editor(text, field_id, url, options={})
    onclick = "new Ajax.Request('#{url_for(url)}', {asynchronous:true, evalScripts:true, method:'get'}); return false;"
    link_to text, '#', options.merge(:onclick => onclick)
  end
  
  def add_note_url(note_source, project=nil)
     {:controller => 'notes', :action => 'add_note', :source_id => note_source, :source_type => note_source.class.name, :project_id => project}
  end  
  
  def thumbnails(obj, options={})     
    return false if !obj || !obj.respond_to?(:attachments)
    
    options[:size] = options[:size].to_s || "100" 
    size = options[:size]
    options[:size] = options[:size] + "x" + options[:size]  
    # options[:max_width] = size
    # options[:max_heght] = size
    max_file_size = options[:max_file_size] || 300.kilobytes    
    options[:class] = "thumbnail"
    
    s = ""
    obj.attachments.each do |att_file|  
      attachment_url = url_for :only_path => false, :controller => 'attachments', :action => 'download', :id => att_file, :filename => att_file.filename
      thumbnail_url = url_for(:only_path => false, 
                              :controller => 'attachments', 
                              :action => 'thumbnail', 
                              :id => att_file, 
                              :size => size)             
      image_url = Object.const_defined?(:Magick) ? thumbnail_url : attachment_url
      s << link_to(image_tag(image_url, options), attachment_url) if (att_file.is_thumbnailable? && (att_file.filesize < max_file_size || Object.const_defined?(:Magick)))
    end       
    s
  end 
  
  def auto_thumbnails(obj) 
    s = ""     
    max_file_size = Setting.plugin_contacts[:max_thumbnail_file_size].to_i.kilobytes if !Setting.plugin_contacts[:max_thumbnail_file_size].blank?
    s << thumbnails(obj, {:size => 100, :max_file_size => max_file_size}) if Setting.plugin_contacts[:auto_thumbnails] 
    content_tag(:p, s, :class => "thumbnails") if !s.blank?
  end    
  
  def note_content(note)    
    s = ""    
    if note.content.length > Note.cut_length
      s << textilizable(truncate(note.content, {:length => Note.cut_length, :omission => "... \"#{l(:label_note_read_more)}\":#{url_for(:controller => 'notes', :action => 'show', :project_id => @project, :note_id => note)}" })) 
    else  
		  s << textilizable(note, :content)
		end  
		s
  end
  
end
