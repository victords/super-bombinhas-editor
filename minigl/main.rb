require 'minigl'
include MiniGL

Cell = Struct.new(:back, :fore, :obj, :hide)

class SBEditor < GameWindow
  EDITOR_WIDTH = 1024
  EDITOR_HEIGHT = 576

  def initialize
    super 1366, 768

    @tiles_x = @tiles_y = 300
    @map = Map.new(32, 32, @tiles_x, @tiles_y, EDITOR_WIDTH, EDITOR_HEIGHT)
    @objects = []
    (0..@tiles_x).each do |i|
      @objects[i] = []
      (0..@tiles_y).each do |j|
        @objects[i][j] = Cell.new
      end
    end
    @margin = Vector.new 200, 0

    @tile_types = %w(Wall Passable Back Fore Hide)
    @tile_type = 0
    @exit_types = %w(Acima Direita Abaixo Esquerda Nenhuma)
    @exit_type = 1
    @editable_area = Rectangle.new(200, 0, EDITOR_WIDTH, EDITOR_HEIGHT)
    @element_area = Rectangle.new(26, 435, 64, 64)
    @ramp_area = Rectangle.new(118, 435, 64, 64)
    @tile_areas = []
    (0..63).each { |i| @tile_areas[i] = Rectangle.new(4 + (i % 8) * 24, 200 + (i / 8) * 24, 24, 24) }

    @ramps = []
    @switch_codes = [7, 8, 9, 12, 13, 20, 24, 26, 27]
    @grid = true
    @dir = '/home/victor/aleva/super-bombinhas/data/stage'
    @msg1 = ''
    @msg2 = ''

    @font = Res.font :BankGothicMedium, 16
    @hide_tile = Res.img :el_ForeWall

    @bgs = []
    @cur_bg = 0
    @added_bgs = []
    Dir["#{Res.prefix}#{Res.img_dir}bg/*"].each { |f| @bgs << Res.img("bg_#{f.split('/')[-1]}", false, false, '') }

    @elements = []
    @cur_element = 1
    @element_index = 0
    Dir["#{Res.prefix}#{Res.img_dir}el/*"].each { |f| @elements << Res.img("el_#{f.split('/')[-1].chomp('.png')}") }

    @tilesets = []
    @cur_tileset = 0
    Dir["#{Res.prefix}#{Res.img_dir}ts/*"].each { |f| @tilesets << Res.img("ts_#{f.split('/')[-1].chomp('.png')}") }
    Res.tileset_dir = 'img/ts'
    @tiles = Res.tileset '1'

    @components = [
      TextField.new(4, 25, @font, :textField, nil, nil, 1, 2),  # name
      TextField.new(4, 65, @font, :textField, nil, nil, 1, 2),  # tiles x
      TextField.new(4, 105, @font, :textField, nil, nil, 1, 2), # tiles y
      TextField.new(4, 536, @font, :textField, nil, nil, 1, 2), # params
      TextField.new(4, 554, @font, :textField, nil, nil, 1, 2), # ramp
      Button.new(4, 125, @font, 'Gerar Mapa', :button),
      Button.new(4, 392, @font, 'Próximo', :button) {
        @cur_tileset += 1
        @cur_tileset = 0 if @cur_tileset == @tilesets.size
      },
      Button.new(4, 172, @font, 'Próximo', :button) {
        @tile_type += 1
        @tile_type = 0 if @tile_type == @tile_types.size
      },
      Button.new(4, 500, @font, 'Próximo', :button) {
        @element_index += 1
        @element_index = 0 if @element_index == @elements.size
        @cur_element = 65 + @element_index
      },
      Button.new(4, 518, @font, 'Anterior', :button) {
        @element_index -= 1
        @element_index = @elements.size - 1 if @element_index < 0
        @cur_element = 65 + @element_index
      },
      Button.new(4, 588, @font, 'Próximo', :button) {
        @exit_type += 1
        @exit_type = 0 if @exit_type == @exit_types.size
      },
      Button.new(204, 680, @font, 'Próximo', :button) {
        @cur_bg += 1
        @cur_bg = 0 if @cur_bg == @bgs.size
      },
      Button.new(204, 700, @font, 'Adicionar', :button), # bg
      Button.new(404, 700, @font, 'Remover', :button),   # bg
      Button.new(4, 645, @font, 'Salvar', :button),
      Button.new(604, 700, @font, 'Abrir', :button),
      Button.new(604, 581, @font, 'Limpar', :button),
      Button.new(604, 611, @font, 'Grid on/off', :button) { @grid = !@grid }
    ]
  end

  def needs_cursor?
    true
  end

  def update
    KB.update
    Mouse.update
    close if KB.key_pressed? Gosu::KbEscape

    if Mouse.button_down? :left
      if Mouse.button_pressed? :left
        if Mouse.over? @editable_area
          if @cur_element < 0 # ramp
            map_pos = @map.get_map_pos(Mouse.x - @margin.x, Mouse.y)
            @ramps << "#{@components[4].text}:#{map_pos.x},#{map_pos.y}"
          end
        else
          (0..63).each do |i|
            if Mouse.over? @tile_areas[i]
              @cur_element = i + 1
              break
            end
          end
          if Mouse.over? @element_area
            @cur_element = 65 + @element_index
          elsif Mouse.over? @ramp_area
            @cur_element = -1
          end
        end
      end
      if Mouse.over? @editable_area and @cur_element > 0
        map_pos = @map.get_map_pos(Mouse.x - @margin.x, Mouse.y)
        if Mouse.double_click? :left
          if @cur_element <= 64 and (@tile_type == 2 or @tile_type == 4)
            code = "b#{'%02d' % (@cur_element - 1)}"
            check_fill(map_pos.x, map_pos.y, code)
          end
        elsif @cur_element <= 64
          if @tile_type == 0 or @tile_type == 1
            @objects[map_pos.x][map_pos.y].obj = (@tile_type == 0 ? 'w' : 'p') + ('%02d' % (@cur_element - 1))
          elsif @tile_type == 2
            @objects[map_pos.x][map_pos.y].back = '%02d' % (@cur_element - 1)
          elsif @tile_type == 3
            @objects[map_pos.x][map_pos.y].fore = '%02d' % (@cur_element - 1)
          else
            @objects[map_pos.x][map_pos.y].hide = 'h00'
          end
        elsif @cur_element == 65 # bomba
          if @components[3].text != ''
            @objects[map_pos.x][map_pos.y].obj = "!#{@components[3].text}"
          end
        else
          symbol = @switch_codes.include?(@cur_element - 65) ? '$' : '@'
          text = "#{symbol}#{currentElement - 65}"
          text += ":#{@components[3].text}" if @components[3].text != ''
          @objects[map_pos.x][map_pos.y].obj = text
        end
      end
    elsif Mouse.button_down? :right
      if Mouse.over? @editable_area
        map_pos = @map.get_map_pos(Mouse.x - @margin.x, Mouse.y)
        @ramps.each do |ramp|
          coords = ramp.split(':')[1].split(',')
          x = coords[0].to_i; y = coords[1].to_i
          w = ramp[1].to_i * 32; h = ramp[2].to_i * 32
          pos = @map.get_screen_pos(x, y) + @margin
          @ramps.delete ramp if Mouse.over? pos.x, pos.y, w, h
        end
        @objects[map_pos.x][map_pos.y] = Cell.new
      end
    end

    if Mouse.over? @editable_area
      speed = KB.key_down?(Gosu::KbLeftShift) || KB.key_down?(Gosu::KbRightShift) ? 20 : 10
      @map.move_camera 0, -speed if KB.key_down? Gosu::KbUp
      @map.move_camera speed, 0 if KB.key_down? Gosu::KbRight
      @map.move_camera 0, speed if KB.key_down? Gosu::KbDown
      @map.move_camera -speed, 0 if KB.key_down? Gosu::KbLeft
    end

    @components.each { |c| c.update }
  end

  def check_fill(x, y, code)

  end

  def draw
    clear 0xffffff
    @map.foreach do |i, j, x, y|
      x += @margin.x
      draw_quad x + 1, y + 1, 0x11000000,
                x + 31, y + 1, 0x11000000,
                x + 1, y + 31, 0x11000000,
                x + 31, y + 31, 0x11000000, 0 if @grid
      @tiles[@objects[i][j].back.to_i].draw x, y if @objects[i][j].back
      draw_object i, j, x, y
      @tiles[@objects[i][j].fore.to_i].draw x, y if @objects[i][j].fore
    end
    draw_quad 0, 0, 0xffffffff,
              200, 0, 0xffffffff,
              0, 600, 0xffffffff,
              200, 600, 0xffffffff, 0
    draw_quad 200, 576, 0xffffffff,
              800, 576, 0xffffffff,
              200, 726, 0xffffffff,
              800, 726, 0xffffffff, 0
    @components.each { |c| c.draw }
    @tilesets[@cur_tileset].draw 4, 200, 0, 0.75, 0.75
    @bgs[@cur_bg].draw 204, 580, 0, 192.0 / @bgs[@cur_bg].width, 100.0 / @bgs[@cur_bg].height

    @font.draw 'Nome:', 5, 5, 0, 1, 1, 0xff000000
    @font.draw 'Tiles em X:', 5, 45, 0, 1, 1, 0xff000000
    @font.draw 'Tiles em Y:', 5, 85, 0, 1, 1, 0xff000000
    @font.draw @msg1, 100, 610, 0, 1, 1, 0xff000000
    @font.draw @msg2, 700, 656, 0, 1, 1, 0xff000000
    @font.draw_rel @tile_types[@tile_type], 100, 150, 0, 0.5, 0, 1, 1, 0xff000000
    @font.draw "Saída: #{@exit_types[@exit_type]}", 4, 568, 0, 1, 1, 0xff000000
  end

  def draw_object(i, j, x, y)
    obj = @objects[i][j].obj
    if obj
      if obj[0] == 'w' || obj[0] == 'p'
        @tiles[obj[1..2].to_i].draw x, y, 0
      elsif obj[0] == '!'
        @elements[0].draw x, y, 0
        @font.draw obj[1..-1], x, y, 0, 1, 1, 0xff000000
      else
        code = obj[1..-1].split(':')
        @elements[code[0].to_i].draw x, y, 0
        if code.size > 1
          code[1..-1].each_with_index do |c, i|
            @font.draw c, x, y + i * 12
          end
        end
      end
    end
  end
end

SBEditor.new.show