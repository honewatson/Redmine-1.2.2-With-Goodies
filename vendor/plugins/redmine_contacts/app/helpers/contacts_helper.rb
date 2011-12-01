module ContactsHelper
  
  def contacts_filters_for_select(selected)    
    selected ||= "" 
    options_for_select([[contacts_filter_name('0'), ActiveRecord::Base.connection.quoted_false.gsub(/'/, '')], 
                        [contacts_filter_name('1'), ActiveRecord::Base.connection.quoted_true.gsub(/'/, '')], 
                        [contacts_filter_name(''), ''], 
                        ['--------'], 
                        [l(:button_cancel), '-1']], :selected => selected, :disabled => "--------")
  end   
  
  def contacts_filter_name(value)
    case value
    when '0'
       l(:label_all_people)
    when '1'
       l(:label_all_companies)
    else
       l(:label_all_people_and_companies)
    end 
  end

  def skype_to(skype_name, name = nil)
    return link_to skype_name, 'skype:' + skype_name + '?call' unless skype_name.blank?
  end
  
  def link_to_remote_list_update(text, url_params)
    link_to_remote(text,
      {:url => url_params, :method => :get, :update => 'contact_list', :complete => 'window.scrollTo(0,0)'},
      {:href => url_for(:params => url_params)}
    )
  end
  
  
  def contacts_paginator(paginator, page_options)     
    page_param = page_options.delete(:page_param) || :page
    per_page_links = page_options.delete(:per_page_links)
    url_param = params.dup
    # don't reuse query params if filters are present
    url_param.merge!(:fields => nil, :values => nil, :operators => nil) if url_param.delete(:set_filter)

    html = ''
    if paginator.current.previous
      html << link_to_remote_list_update('&#171; ' + l(:label_previous), url_param.merge(page_param => paginator.current.previous)) + ' '
    end

    html << (pagination_links_each(paginator, page_options) do |n|
      link_to_remote_list_update(n.to_s, url_param.merge(page_param => n))
    end || '')
    
    if paginator.current.next
      html << ' ' + link_to_remote_list_update((l(:label_next) + ' &#187;'), url_param.merge(page_param => paginator.current.next))
    end      
    
    html
    
  end
  
  def contact_url(contact)      
    return {:controller => 'contacts', :action => 'show', :project_id => @project, :id => contact.id }
  end  
  

  def note_source_url(note_source)
    contact_url(note_source)
    # return {:controller => note_source.class.name.pluralize.downcase, :action => 'show', :project_id => @project, :id => note_source.id }
  end
       
  def link_to_source(note_source) 
    return link_to note_source.name, note_source_url(note_source)
  end

  def avatar_to(obj, options = { })  
    options[:size] = "64" unless options[:size]  
    size = options[:size]
    options[:size] = options[:size] + "x" + options[:size] 
    options[:class] = "gravatar" 
    
    avatar = obj.avatar unless Rails::env == "development"
    
    if avatar && FileTest.exists?(avatar.diskfile) && avatar.is_thumbnailable? then  # and obj.visible?  
      avatar_url = url_for :only_path => false, :controller => 'attachments', :action => 'download', :id => avatar, :filename => avatar.filename
      thumbnail_url = url_for(:only_path => false, 
                              :controller => 'attachments', 
                              :action => 'thumbnail', 
                              :id => avatar, 
                              :size => size)             
                          
      image_url = Object.const_defined?(:Magick) ? thumbnail_url : avatar_url
                          
      if options[:full_size] then
        image = link_to image_tag(image_url, options), avatar_url
      else 
        image = image_tag(image_url, options)
      end 
    end
    
   
    plugins_images = case obj  
      when Contact then obj.is_company ? "company.png" : "person.png"
    end 
    plugins_images = image_path(plugins_images, :plugin => :redmine_contacts)
     
    if !image && Setting.plugin_contacts[:use_gravatar] && obj.class == Contact
      options[:default] = "#{request.protocol}#{request.host_with_port}" + plugins_images   
      options.merge!({:ssl => (defined?(request) && request.ssl?)})
      image = gravatar(obj.emails.first.downcase, options) rescue nil 
    end 
    
    image ||= image_tag(plugins_images, options)

  end
  
  def link_to_add_phone(name)             
    fields = '<p>' + label_tag(l(:field_contact_phone)) + 
      text_field_tag( "contact[phones][]", '', :size => 30 ) + 
      link_to_function(l(:label_remove), "removeField(this)") + '</p>'
    link_to_function(name, h("addField(this, '#{escape_javascript(fields)}' )"))
  end    
  
  def link_to_task_complete(url, bucket)
    onclick = "this.disable();"
    onclick << %Q/$("#{dom_id(pending, :name)}").style.textDecoration="line-through";/
    onclick << remote_function(:url => url, :method => :put, :with => "{ bucket: '#{bucket}' }")
  end   
  
  def render_contact_projects_hierarchy(projects)  
    s = ''
    project_tree(projects) do |project, level| 
      s << "<ul>"
      name_prefix = (level > 0 ? ('&nbsp;' * 2 * level + '&#187; ') : '')
        url = {:controller => 'contacts_projects',
               :action => 'delete',
               :disconnect_project_id => project.id,
               :project_id => @project.id,
               :contact_id => @contact.id}
      
      s << "<li>" + name_prefix + link_to_project(project)
      s += ' ' + link_to_remote(image_tag('delete.png'),
                                {:url => url},
                                :href => url_for(url),
                                :style => "vertical-align: middle",
                                :class => "delete") if (projects.size > 1 && authorize_for(:contacts, :edit) )       
      s << "</li>"                          

      s << "</ul>"
    end
    s
  end  
  
  def contact_to_vcard(contact)  
    return false if !Gem.available?('vpim') 

    require 'vpim/vcard'

    card = Vpim::Vcard::Maker.make2 do |maker|

      maker.add_name do |name|
        name.prefix = ''
        name.given = contact.first_name
        name.family = contact.last_name
        name.additional = contact.middle_name
      end

      maker.add_addr do |addr|
        addr.preferred = true
        addr.street = contact.address.gsub("\r\n"," ").gsub("\n"," ") 
      end
      
      maker.title = contact.job_title
      maker.org = contact.company   
      maker.birthday = contact.birthday.to_date unless contact.birthday.blank?
      maker.add_note(contact.background.gsub("\r\n"," ").gsub("\n", ' '))
       
      maker.add_url(contact.website)

      contact.phones.each { |phone| maker.add_tel(phone) }
      contact.emails.each { |email| maker.add_email(email) }
    end   
    avatar = contact.attachments.find_by_description('avatar')  
    card = card.encode.sub("END:VCARD", "PHOTO;BASE64:" + "\n " + [File.open(avatar.diskfile).read].pack('m').to_s.gsub(/[ \n]/, '').scan(/.{1,76}/).join("\n ") + "\nEND:VCARD") if avatar && avatar.readable?
    
    card.to_s 	
    
  end  
  
  def observe_fields(fields, options)
    #prepare a value of the :with parameter
    with = ""
    for field in fields
      with += "'"
      with += "&" if field != fields.first
      with += field + "='+escape($('#{field}').value)"
      with += " + " if field != fields.last
    end

    #generate a call of the observer_field helper for each field
    ret = "";
    for field in fields
      ret += observe_field(field,
      options.merge( { :with => with }))
    end
    ret
  end    

  
end
