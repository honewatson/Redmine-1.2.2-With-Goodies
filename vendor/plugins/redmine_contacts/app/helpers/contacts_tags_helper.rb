module ContactsTagsHelper   

  def color_picker(name, color="#aaa")
    #build the hexes
    hexes = []
    (0..15).step(3) do |one|
      (0..15).step(3) do |two|
        (0..15).step(3) do |three|
          hexes << "#" + one.to_s(16) + two.to_s(16) + three.to_s(16)
        end
      end
    end
    arr = []     
    on_change_function = "onChange=\"this.style.backgroundColor=this.options[this.selectedIndex].style.backgroundColor;\""
    10.times { arr << "&nbsp;" }
    returning html = '' do
      html << "<select name=#{name}[color] id=#{name}_color #{on_change_function} style=\"background-color:#{color};\">"
      html << hexes.collect {|c| "<option value='#{c.from(1).to_i(16)}' 
                                          style='background-color: #{c} 
                                          #{'selected="select"' if c == color }'>
                                          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                                          #{c}
                                          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                                  </option>" }.join("\n")
        html << "</select>"
      end
    end

  end