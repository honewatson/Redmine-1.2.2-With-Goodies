# Wiki Extensions plugin for Redmine
# Copyright (C) 2011  Haruyuki Iida
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
class WikiExtensionsMenu < ActiveRecord::Base
  unloadable
  belongs_to :project
  validates_presence_of :project_id
  validates_presence_of :menu_no
  validates_uniqueness_of :menu_no, :scope => :project_id
  #validates_uniqueness_of :page_name, :scope => :project_id
  #validates_uniqueness_of :title, :scope => :project_id

  def self.find_or_create(pj_id, no)
    menu = WikiExtensionsMenu.find(:first,
      :conditions => ['project_id = ? and menu_no = ?', pj_id, no])
    unless menu
      menu = WikiExtensionsMenu.new
      menu.project_id = pj_id
      menu.menu_no = no
      menu.enabled = false
      menu.save!
    end
    return menu
  end

  def self.enabled?(pj_id, no)
    begin
      menu = find_or_create(pj_id, no)
      return false if menu.page_name.blank?
      menu.enabled
    rescue
      return false
    end
  end

  def self.title(pj_id, no)
    begin
      menu = find_or_create(pj_id, no)
      return menu.title unless menu.title.blank?
      return menu.page_name unless menu.page_name.blank?
      return nil
    rescue
      return nil
    end
  end

  def validate
    return true unless enabled
    #errors.add("title", "is empty") unless attribute_present?("title")
    #errors.add("page_name", "is empty") unless attribute_present?("page_name")

  end
end
