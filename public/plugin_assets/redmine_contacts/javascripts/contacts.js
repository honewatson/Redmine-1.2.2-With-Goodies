var phoneFieldCount = 1;
function addPhoneField() {
	if (phoneFieldCount >= 5) return false
	phoneFieldCount++;

	var l = document.createElement("label");
	l.appendChild(document.createTextNode(""));

	var d = document.createElement("input");
	d.name = "contact[phones][]";
	d.type = "text";
	d.size = "30";

	p = document.getElementById("phones_fields");

	k = p.insertBefore(document.createElement("p"));  
	k.appendChild(l);
	k.appendChild(d);

}         


var noteFileFieldCount = 1;

function addNoteFileField() {
	if (noteFileFieldCount >= 10) return false
	noteFileFieldCount++;
	var f = document.createElement("input");
	f.type = "file";
	f.name = "note_attachments[" + noteFileFieldCount + "][file]";
	f.size = 30;
	var d = document.createElement("input");
	d.type = "text";
	d.name = "note_attachments[" + noteFileFieldCount + "][description]";
	d.size = 60;

	p = document.getElementById("note_attachments_fields");
	p.appendChild(document.createElement("br"));
	p.appendChild(f);
	p.appendChild(d);
}

function removeField(link) {
	Effect.Fade($(link).up(),{duration:0.5}); 
	$(link).previous().value = '';
}

function addField(link, content) {
	$(link).up().insert({
		before: content
	})    
}

var Redmine = Redmine || {};

Redmine.TagsInput = Class.create({
  initialize: function(element) {
    this.element  = $(element);
    this.input    = new Element('input', { 'type': 'text', 'autocomplete': 'off', 'size': 20 });
    this.button   = new Element('span', { 'class': 'tag-add icon icon-add' });
    this.tags     = new Hash();
    
    Event.observe(this.button, 'click', this.readTags.bind(this));
    Event.observe(this.input, 'keypress', this.onKeyPress.bindAsEventListener(this));

    this.element.insert({ 'after': this.input });
    this.input.insert({ 'after': this.button });
    this.addTagsList(this.element.value);
  },

  readTags: function() {
    this.addTagsList(this.input.value);
    this.input.value = '';
  },

  onKeyPress: function(event) {
    if (Event.KEY_RETURN == event.keyCode) {
      this.readTags(event);
      Event.stop(event);
    }
  },

  addTag: function(tag) {
    if (tag.blank() || this.tags.get(tag)) return;

    var button = new Element('span', { 'class': 'tag-delete icon icon-del' });
    var label  = new Element('span', { 'class': 'tag-label' }).insert(tag).insert(button);

    this.tags.set(tag, 1);
    this.element.value = this.getTagsList();
    this.element.insert({ 'before': label });

    Event.observe(button, 'click', function(){
      this.tags.unset(tag);
      this.element.value = this.getTagsList();
      label.remove();
    }.bind(this));
  },

  addTagsList: function(tags_list) {
    var tags = tags_list.split(',');
    for (var i = 0; i < tags.length; i++) {
      this.addTag(tags[i].strip());
    }
  },

  getTagsList: function() {
    return this.tags.keys().join(',');
  },

  autocomplete: function(container, url) {
    new Ajax.Autocompleter(this.input, container, url, {
      'minChars': 1,
      'frequency': 0.5,
      'paramName': 'q',
      'updateElement': function(el) {
        this.input.value = el.getAttribute('name');
        this.readTags();
      }.bind(this)
    });
  }
});

function observeContactTagsField(url) {
  new Redmine.TagsInput('contact_tag_list').autocomplete('contact_tag_candidates', url);
}       

function observeTagsField(url, tag_list, tag_candidates) {
  new Redmine.TagsInput(tag_list).autocomplete(tag_candidates, url);
}

// 
//     CheckContactsAndDeals
// 

function checkAllContacts(field)
{
	for (i = 0; i < field.length; i++) {
		field[i].checked = true; 
		Element.up(field[i], 'tr').addClassName('context-menu-selection');
	}   
}  

function uncheckAllContacts(field)
{
	for (i = 0; i < field.length; i++) {
		field[i].checked = false; 
		Element.up(field[i], 'tr').removeClassName('context-menu-selection');      
	}
}


function toggleContact(event, element)
{
	if (event.shiftKey==1)
	{
		if (element.checked) {
			checkAllContacts($$('.contacts.index td.checkbox input'));
		}
		else 
		{
			uncheckAllContacts($$('.contacts.index td.checkbox input'));
		}
	}
	else
	{
		Element.up(element, 'tr').toggleClassName('context-menu-selection');
	}
}  




/**
 * basic color picker
 * <label for="picker-1">
 *  <input class="colorpicker" value="#ccffcc" />
 * </label>
 *
 * $$('.colorpicker').each(function(el){var p = new ColorPicker(el)});
 */
var ColorPicker = Class.create({
    colors: [],
    element: null,

    initialize: function(element, trigger) {
        this.colourArray = new Array();
        this.element = $(element);

        this.buildTable();

        this.element.observe('click', this.togglePicker.bindAsEventListener(this));
        this.element.setStyle({backgroundColor: this.element.value});
    },

    buildTable: function(){
        this.initColors();
        var table = new Element('table');

        for( var i = 0, len = this.colors.length; i < len; i++ ){
            var color = this.colors[i];

            if( i % 8 == 0 ){
                row = new Element('tr');
                table.insert( row );
            }

            row.insert( '<td style="'
						 					 + 'border: 1px solid #D7D7D7;'
                       + 'background-color:#' 
                       + color
                       + ';text-indent:-10em;overflow:hidden;width:1em;height:1em;'
                       +'"><a class="colorpicker-color" style="display:block;text-indent:-10em;overflow:hidden;" href="#'
                       + color + '">'
                       + color
                       + '</a></td>' );
        }

        table.setStyle('top:0;width:15em;border: 1px solid #D7D7D7;');

        var holder = new Element( 'div', {style:'position:relative;'})
        this.element.up().insert(holder.insert(table.hide()));

        table.select('a').invoke('observe', 'click', this.onClick.bindAsEventListener(this));
    },

    onClick: function( evt ){
        var color = '#' + evt.element().href.split('#').pop();
        this.element.value = color;
        this.element.setStyle({backgroundColor: color});
        evt.findElement('table').hide();
        evt.stop();
    },

    togglePicker: function( evt ){
        evt.element().up().down('table').show();

    },

    initColors: function() {
        var colourMap = new Array('00', '33', '66', '99', 'AA', 'CC', 'EE', 'FF');
        for(i = 0; i < colourMap.length; i++) {
            this.colors.push(colourMap[i] + colourMap[i] + colourMap[i]);
        }

        // Blue
        for(i = 1; i < colourMap.length; i++) {
            if(i != 0 && i != 4 && i != 6) {
                this.colors.push(colourMap[0] + colourMap[0] + colourMap[i]);
            }
        }
        for(i = 1; i < colourMap.length; i++) {
            if(i != 2 && i != 4 && i != 6 && i != 7) {
                this.colors.push(colourMap[i] + colourMap[i] + colourMap[7]);
            }
        }

        // Green
        for(i = 1; i < colourMap.length; i++) {
            if(i != 0 && i != 4 && i != 6) {
                this.colors.push(colourMap[0] + colourMap[i] + colourMap[0]);
            }
        }
        for(i = 1; i < colourMap.length; i++) {
            if(i != 2 && i != 4 && i != 6 && i != 7) {
                this.colors.push(colourMap[i] + colourMap[7] + colourMap[i]);
            }
        }

        // Red
        for(i = 1; i < colourMap.length; i++) {
            if(i != 0 && i != 4 && i != 6) {
                this.colors.push(colourMap[i] + colourMap[0] + colourMap[0]);
            }
        }
        for(i = 1; i < colourMap.length; i++) {
            if(i != 2 && i != 4 && i != 6 && i != 7) {
                this.colors.push(colourMap[7] + colourMap[i] + colourMap[i]);
            }
        }

        // Yellow
        for(i = 1; i < colourMap.length; i++) {
            if(i != 0 && i != 4 && i != 6) {
                this.colors.push(colourMap[i] + colourMap[i] + colourMap[0]);
            }
        }
        for(i = 1; i < colourMap.length; i++) {
            if(i != 2 && i != 4 && i != 6 && i != 7) {
                this.colors.push(colourMap[7] + colourMap[7] + colourMap[i]);
            }
        }

        // Cyan
        for(i = 1; i < colourMap.length; i++) {
            if(i != 0 && i != 4 && i != 6) {
                this.colors.push(colourMap[0] + colourMap[i] + colourMap[i]);
            }
        }
        for(i = 1; i < colourMap.length; i++) {
            if(i != 2 && i != 4 && i != 6 && i != 7) {
                this.colors.push(colourMap[i] + colourMap[7] + colourMap[7]);
            }
        }

        // Magenta
        for(i = 1; i < colourMap.length; i++) {
            if(i != 0 && i != 4 && i != 6) {
                this.colors.push(colourMap[i] + colourMap[0] + colourMap[i]);
            }
        }
        for(i = 1; i < colourMap.length; i++) {
            if(i != 2 && i != 4 && i != 6 && i != 7) {
                this.colors.push(colourMap[7] + colourMap[i] + colourMap[i]);
            }
        }
    }
});