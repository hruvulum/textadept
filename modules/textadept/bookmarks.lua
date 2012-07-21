-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Bookmarks for the textadept module.
-- @field MARK_BOOKMARK_COLOR (number)
--   The color used for a bookmarked line in `0xBBGGRR` format.
module('_M.textadept.bookmarks')]]

M.MARK_BOOKMARK_COLOR = not NCURSES and 0xB3661A or 0xFF0000

local MARK_BOOKMARK = _SCINTILLA.next_marker_number()

---
-- Adds a bookmark to the current line.
-- @name add
function M.add()
  local buffer = buffer
  local line = buffer:line_from_position(buffer.current_pos)
  buffer:marker_add(line, MARK_BOOKMARK)
end

---
-- Clears the bookmark at the current line.
-- @name remove
function M.remove()
  local buffer = buffer
  local line = buffer:line_from_position(buffer.current_pos)
  buffer:marker_delete(line, MARK_BOOKMARK)
end

---
-- Toggles a bookmark on the current line.
-- @name toggle
function M.toggle()
  local buffer = buffer
  local line = buffer:line_from_position(buffer.current_pos)
  local markers = buffer:marker_get(line) -- bit mask
  local bit = 2^MARK_BOOKMARK
  if markers % (bit + bit) < bit then M.add() else M.remove() end
end

---
-- Clears all bookmarks in the current buffer.
-- @name clear
function M.clear()
  buffer:marker_delete_all(MARK_BOOKMARK)
end

---
-- Goes to the next bookmark in the current buffer.
-- @name goto_next
function M.goto_next()
  local buffer = buffer
  local current_line = buffer:line_from_position(buffer.current_pos)
  local line = buffer:marker_next(current_line + 1, 2^MARK_BOOKMARK)
  if line == -1 then line = buffer:marker_next(0, 2^MARK_BOOKMARK) end
  if line >= 0 then _M.textadept.editing.goto_line(line + 1) end
end

---
-- Goes to the previous bookmark in the current buffer.
-- @name goto_prev
function M.goto_prev()
  local buffer = buffer
  local current_line = buffer:line_from_position(buffer.current_pos)
  local line = buffer:marker_previous(current_line - 1, 2^MARK_BOOKMARK)
  if line == -1 then
    line = buffer:marker_previous(buffer.line_count, 2^MARK_BOOKMARK)
  end
  if line >= 0 then _M.textadept.editing.goto_line(line + 1) end
end

---
-- Goes to selected bookmark from a filtered list.
-- @name goto_bookmark
function M.goto_bookmark()
  local buffer = buffer
  local markers, line = {}, buffer:marker_next(0, 2^MARK_BOOKMARK)
  if line == -1 then return end
  repeat
    local text = buffer:get_line(line):sub(1, -2) -- chop \n
    markers[#markers + 1] = tostring(line + 1)..': '..text
    line = buffer:marker_next(line + 1, 2^MARK_BOOKMARK)
  until line < 0
  local line = gui.filteredlist(_L['Select Bookmark'], _L['Bookmark'], markers)
  if line then _M.textadept.editing.goto_line(line:match('^%d+')) end
end

local NCURSES_MARK = _SCINTILLA.constants.SC_MARK_CHARACTER + string.byte(' ')
-- Sets view properties for bookmark markers.
local function set_bookmark_properties()
  if NCURSES then buffer:marker_define(MARK_BOOKMARK, NCURSES_MARK) end
  buffer.marker_back[MARK_BOOKMARK] = M.MARK_BOOKMARK_COLOR
end
if buffer then set_bookmark_properties() end
events.connect(events.VIEW_NEW, set_bookmark_properties)

return M
