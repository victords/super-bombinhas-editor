require 'minigl'
include MiniGL

class SBEditor < GameWindow
  def initialize
    super 1366, 768
  end

  def needs_cursor?
    true
  end

  def update
    KB.update
    close if KB.key_pressed? Gosu::KbEscape
  end

  def draw
    clear 0xabcdef
  end
end

SBEditor.new.show