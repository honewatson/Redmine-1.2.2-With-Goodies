# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.dirname(__FILE__) + '/../test_helper'  

class DeleteTagTest < ActionController::IntegrationTest
  fixtures :contacts, :tags, :taggings
  
  test "Should opens settings" do
    log_user("admin", "admin")
    
    get "/settings/plugin/contacts"
    assert_response :success
  end
  
  test "Contacts with deleted tags should opens" do
    log_user("admin", "admin")

    get "contacts"
    assert_response :success
    
    get "settings/plugin/contacts"
    # assert_select 'div#tab-content-tags table td a', "main"

    assert_response :success
    get "/contacts_tags/destroy/2"
    assert_redirected_to "/settings/plugin/contacts"
    assert !Tag.find(2)

    get "contacts/1"
    assert_response :success
  end  
end
