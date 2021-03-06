-- Copyright 2007-2019 Mitchell mitchell.att.foicica.com. See LICENSE.

_RELEASE = "Textadept 10.3"
_COPYRIGHT = 'Copyright © 2007-2019 Mitchell. See LICENSE.\n'..
             'http://foicica.com/textadept'

package.path = _HOME..'/core/?.lua;'..package.path

_SCINTILLA = require('iface')
events = require('events')
args = require('args')
_L = require('locale')
require('file_io')
require('lfs_ext')
require('ui')
keys = require('keys')

_M = {} -- language modules table
-- pdcurses compatibility.
if CURSES and WIN32 then
  function os.spawn(argv, ...)
    local current_dir = lfs.currentdir()
    local i = 1
    if type(select(i, ...)) == 'string' then
      lfs.chdir(select(i, ...)) -- cwd
      i = i + 1
    end
    if type(select(i, ...)) == 'table' then i = i + 1 end -- env (ignore)
    local p = io.popen(argv..' 2>&1')
    if select(i, ...) then select(i, ...)(p:read('a')) end -- stdout_cb
    local status = select(3, p:close())
    if select(i + 2, ...) then select(i + 2, ...)(status) end -- exit_cb
    lfs.chdir(current_dir)
    return p
  end
end

-- Replacement for original `buffer:text_range()`, which has a C struct for an
-- argument.
-- Documentation is in core/.buffer.luadoc.
local function text_range(buffer, start_pos, end_pos)
  local target_start, target_end = buffer.target_start, buffer.target_end
  if start_pos < 0 then start_pos = 0 end
  if end_pos > buffer.length then end_pos = buffer.length end
  buffer:set_target_range(start_pos, end_pos)
  local text = buffer.target_text
  buffer:set_target_range(target_start, target_end) -- reset
  return text
end
events.connect(events.BUFFER_NEW, function() buffer.text_range = text_range end)

--[[ This comment is for LuaDoc.
---
-- Extends Lua's _G table to provide extra functions and fields for Textadept.
-- @field _HOME (string)
--   The path to Textadept's home, or installation, directory.
-- @field _RELEASE (string)
--   The Textadept release version string.
-- @field _USERHOME (string)
--   The path to the user's *~/.textadept/* directory, where all preferences and
--   user-data is stored.
--   On Windows machines *~/* is the value of the "USERHOME" environment
--   variable (typically *C:\Users\username\\* or
--   *C:\Documents and Settings\username\\*). On Linux, BSD, and Mac OSX
--   machines *~/* is the value of "$HOME" (typically */home/username/* and
--   */Users/username/* respectively).
-- @field _CHARSET (string)
--   The filesystem's character encoding.
--   This is used when [working with files](#io).
-- @field WIN32 (bool)
--   Whether or not Textadept is running on Windows.
-- @field OSX (bool)
--   Whether or not Textadept is running on Mac OSX as a GUI application.
-- @field LINUX (bool)
--   Whether or not Textadept is running on Linux.
-- @field BSD (bool)
--   Whether or not Textadept is running on BSD.
-- @field CURSES (bool)
--   Whether or not Textadept is running in the terminal.
--   Curses feature incompatibilities are listed in the [Appendix][].
--
--   [Appendix]: manual.html#Curses.Compatibility
module('_G')]]

--[[ The tables below were defined in C.

---
-- Table of command line parameters passed to Textadept.
-- @class table
-- @see args
-- @name arg
local arg

---
-- Table of all open buffers in Textadept.
-- Numeric keys have buffer values and buffer keys have their associated numeric
-- keys.
-- @class table
-- @usage _BUFFERS[n]      --> buffer at index n
-- @usage _BUFFERS[buffer] --> index of buffer in _BUFFERS
-- @see _G.buffer
-- @name _BUFFERS
local _BUFFERS

---
-- Table of all views in Textadept.
-- Numeric keys have view values and view keys have their associated numeric
-- keys.
-- @class table
-- @usage _VIEWS[n]    --> view at index n
-- @usage _VIEWS[view] --> index of view in _VIEWS
-- @see _G.view
-- @name _VIEWS
local _VIEWS

---
-- The current [buffer](#buffer) in the [current view](#_G.view).
-- @class table
-- @name buffer
local buffer

---
-- The current [view](#view).
-- @class table
-- @name view
local view

-- The functions below are Lua C functions.

---
-- Emits a `QUIT` event, and unless any handler returns `false`, quits
-- Textadept.
-- @see events.QUIT
-- @class function
-- @name quit
local quit

---
-- Resets the Lua State by reloading all initialization scripts.
-- Language modules for opened files are NOT reloaded. Re-opening the files that
-- use them will reload those modules instead.
-- This function is useful for modifying user scripts (such as
-- *~/.textadept/init.lua* and *~/.textadept/modules/textadept/keys.lua*) on
-- the fly without having to restart Textadept. `arg` is set to `nil` when
-- reinitializing the Lua State. Any scripts that need to differentiate between
-- startup and reset can test `arg`.
-- @class function
-- @name reset
local reset

---
-- Calls function *f* with the given arguments after *interval* seconds.
-- If *f* returns `true`, calls *f* repeatedly every *interval* seconds as long
-- as *f* returns `true`. A `nil` or `false` return value stops repetition.
-- @param interval The interval in seconds to call *f* after.
-- @param f The function to call.
-- @param ... Additional arguments to pass to *f*.
-- @class function
-- @name timeout
local timeout
]]
