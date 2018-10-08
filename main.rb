require 'minigl'
include MiniGL

Cell = Struct.new(:back, :fore, :obj, :hide)

class SBEditor < GameWindow
  EDITOR_WIDTH = 1024
  EDITOR_HEIGHT = 576
  TOTAL_TILES = 100
  NULL_COLOR = 0x11000000
  HIDE_COLOR = 0x33000099
  RAMP_COLOR = 0x66000000
  RAMP_UP_COLOR = 0x66990099
  SELECTION_COLOR = 0x66ffff00
  BLACK = 0xff000000
  WHITE = 0xffffffff

  def initialize
    super 1240, 720, false

    @tiles_x = @tiles_y = 300
    @map = Map.new(32, 32, @tiles_x, @tiles_y, EDITOR_WIDTH, EDITOR_HEIGHT)
    @objects = Array.new(@tiles_x) {
      Array.new(@tiles_y) {
        Cell.new
      }
    }
    @margin = Vector.new 200, 0

    @tile_types = %w(Wall Passable Back Fore Hide)
    @tile_type = 0
    @exit_types = %w(Acima Direita Abaixo Esquerda Nenhuma)
    @exit_type = 1
    @editable_area = Rectangle.new(200, 0, EDITOR_WIDTH, EDITOR_HEIGHT)
    @element_area = Rectangle.new(26, 435, 64, 64)
    @ramp_area = Rectangle.new(118, 435, 64, 64)
    @tile_areas = []
    (0..99).each { |i| @tile_areas[i] = Rectangle.new((i % 10) * 20, 192 + (i / 10) * 20, 20, 20) }

    @ramps = []
    @switch_codes = []
    @grid = true
    @dark = false
    @dir = '/home/victor/Projects/super-bombinhas/data/stage'
    @msg = ''

    @font = Res.font :BankGothicMedium, 16

    @bgs = []
    @cur_bg = 0
    @added_bgs = []
    Dir["#{Res.prefix}#{Res.img_dir}bg/*"].sort.each { |f| @bgs << Res.img("bg_#{f.split('/')[-1]}", false, false, '') }

    @elements = []
    @cur_element = 1
    @element_index = 0
    switch_names = %w(Life Key Door GunPowder Crack SaveBombie Attack1 Attack2 Attack3 Ball BallReceptor ForceField Board Hammer Spring Herb Monep JillisStone MountainBombie WindMachine)
    i = 1
    Dir["#{Res.prefix}#{Res.img_dir}el/*"].sort.each do |f|
      el = f.split('/')[-1].chomp('.png')
      if el == 'Bomb'
        @elements.unshift Res.img("el_#{el}")
      else
        @elements << Res.img("el_#{el}")
        @switch_codes << i if switch_names.index(el)
        i += 1
      end
    end

    @tilesets = []
    @cur_tileset = 0
    Dir["#{Res.prefix}#{Res.img_dir}ts/*"].sort.each { |f| @tilesets << Res.img("ts_#{f.split('/')[-1].chomp('.png')}") }
    Res.tileset_dir = 'img/ts'
    @tiles = Res.tileset '1', 16, 16

    @components = [
      TextField.new(4, 25, @font, :textField, nil, nil, 1, 1, 10),   # name
      TextField.new(4, 65, @font, :textField, nil, nil, 1, 1, 3),    # tiles x
      TextField.new(4, 105, @font, :textField, nil, nil, 1, 1, 3),   # tiles y
      TextField.new(4, 536, @font, :textField, nil, nil, 1, 1, 50) { @cur_element = TOTAL_TILES + @element_index + 1 }, # params
      TextField.new(4, 554, @font, :textField, nil, nil, 1, 1, 4) { @cur_element = -1 }, # ramp
      TextField.new(604, 700, @font, :textField, nil, nil, 1, 1, 2), # bgm
      Button.new(4, 125, @font, 'Gerar Mapa', :button) {
        tiles_x = @components[1].text.to_i; tiles_y = @components[2].text.to_i
        if tiles_x < @tiles_x
          @objects = @objects[0...tiles_x]
        elsif tiles_x > @tiles_x
          min_y = tiles_y < @tiles_y ? tiles_y : @tiles_y
          (@tiles_x...tiles_x).each do |i|
            @objects[i] = []
            (0...min_y).each { |j| @objects[i][j] = Cell.new }
          end
        end
        if tiles_y < @tiles_y
          @objects.map! { |o| o[0...tiles_y] }
        elsif tiles_y > @tiles_y
          @objects.each do |o|
            (@tiles_y...tiles_y).each { |j| o[j] = Cell.new }
          end
        end
        @map = Map.new 32, 32, tiles_x, tiles_y, EDITOR_WIDTH, EDITOR_HEIGHT
        @tiles_x = tiles_x; @tiles_y = tiles_y
      },
      Button.new(4, 392, @font, 'Próximo', :button) {
        @cur_tileset += 1
        @cur_tileset = 0 if @cur_tileset == @tilesets.size
        @tiles = Res.tileset (@cur_tileset + 1).to_s, 16, 16
        @cur_element = 1 if @cur_element < 0 or @cur_element > TOTAL_TILES
      },
      Button.new(4, 172, @font, 'Próximo', :button) {
        @tile_type += 1
        @tile_type = 0 if @tile_type == @tile_types.size
        @cur_element = 1 if @cur_element < 0 or @cur_element > TOTAL_TILES
      },
      Button.new(4, 500, @font, 'Próximo', :button) {
        @element_index += 1
        @element_index = 0 if @element_index == @elements.size
        @cur_element = TOTAL_TILES + @element_index + 1
        @components[3].text = ''
      },
      Button.new(4, 518, @font, 'Anterior', :button) {
        @element_index -= 1
        @element_index = @elements.size - 1 if @element_index < 0
        @cur_element = TOTAL_TILES + @element_index + 1
        @components[3].text = ''
      },
      Button.new(4, 588, @font, 'Próximo', :button) {
        @exit_type += 1
        @exit_type = 0 if @exit_type == @exit_types.size
      },
      Button.new(204, 680, @font, 'Próximo', :button) {
        @cur_bg += 1
        @cur_bg = 0 if @cur_bg == @bgs.size
      },
      Button.new(204, 700, @font, 'Adicionar', :button) {
        @added_bgs << "#{@cur_bg + 1}" if @added_bgs.size < 5
      },
      Button.new(404, 700, @font, 'Remover', :button) {
        @added_bgs.pop
      },
      Button.new(4, 645, @font, 'Salvar', :button) {
        name = @components[0].text
        if name.empty?
          @msg = 'Dê um nome à fase!'
        elsif @added_bgs.empty?
          @msg = 'Escolha um BG!'
        elsif @components[5].text.empty?
          @msg = 'Escolha a BGM!'
        else
          path = "#{@dir}/#{name.gsub('|', '/')}"
          if @save_confirm
            @save_confirm = false
            File.delete path
            save_file path
          elsif File.exist? path
            @msg = 'Salvar por cima?'
            @save_confirm = true
          else
            save_file path
          end
        end
      },
      Button.new(4, 675, @font, 'Abrir', :button) {
        name = @components[0].text
        if name.empty?
          @msg = 'Digite o nome!'
        else
          path = "#{@dir}/#{name.gsub('|', '/')}"
          if File.exist? path
            open_file path
          else
            @msg = 'O arquivo não existe!'
          end
        end
      },
      Button.new(604, 581, @font, 'Limpar', :button) {
        @components[0..5].each { |c| c.text = ''; c.unfocus }
        @cur_bg = 0; @cur_tileset = 0; @cur_element = 1
        @objects = Array.new(@tiles_x) {
          Array.new(@tiles_y) {
            Cell.new
          }
        }
        @added_bgs.clear
        @ramps.clear
      },
      Button.new(604, 611, @font, 'Grid/Codes on/off', :button) { @grid = !@grid },
      dark_btn = Button.new(604, 641, @font, 'Normal', :button) { @dark = !@dark; dark_btn.text = @dark ? 'Dark' : 'Normal' }
    ]
  end

  def needs_cursor?
    true
  end

  def update
    KB.update
    Mouse.update
    close if KB.key_pressed? Gosu::KbEscape

    ctrl = (KB.key_down? Gosu::KbLeftControl or KB.key_down? Gosu::KbRightControl)
    if Mouse.button_down? :left
      if Mouse.button_pressed? :left
        if Mouse.over? @editable_area
          if @cur_element < 0 # ramp
            map_pos = @map.get_map_pos(Mouse.x - @margin.x, Mouse.y)
            @ramps << "#{@components[4].text}:#{map_pos.x},#{map_pos.y}"
          elsif ctrl
            map_pos = @map.get_map_pos(Mouse.x - @margin.x, Mouse.y)
            @components[3].text += "|#{map_pos.x},#{map_pos.y}"
          end
        else
          (0..(TOTAL_TILES - 1)).each do |i|
            if Mouse.over? @tile_areas[i]
              @cur_element = i + 1
              break
            end
          end
          if Mouse.over? @element_area
            @cur_element = TOTAL_TILES + @element_index + 1
          elsif Mouse.over? @ramp_area
            @cur_element = -1
          end
        end
      end
      if Mouse.over? @editable_area and @cur_element > 0 and not ctrl
        map_pos = @map.get_map_pos(Mouse.x - @margin.x, Mouse.y)
        if Mouse.double_click? :left
          if @cur_element <= TOTAL_TILES and (@tile_type == 2 or @tile_type == 4)
            code = "b#{'%02d' % (@cur_element - 1)}"
            check_fill(map_pos.x, map_pos.y, code)
          end
        elsif @cur_element <= TOTAL_TILES
          if @tile_type == 0 or @tile_type == 1
            @objects[map_pos.x][map_pos.y].obj = (@tile_type == 0 ? 'w' : 'p') + ('%02d' % (@cur_element - 1))
          elsif @tile_type == 2
            @objects[map_pos.x][map_pos.y].back = 'b%02d' % (@cur_element - 1)
          elsif @tile_type == 3
            @objects[map_pos.x][map_pos.y].fore = 'f%02d' % (@cur_element - 1)
          else
            @objects[map_pos.x][map_pos.y].hide = 'h00'
          end
        elsif @cur_element == TOTAL_TILES + 1 # bomba
          if @components[3].text != ''
            @objects[map_pos.x][map_pos.y].obj = "!#{@components[3].text}"
          end
        else
          symbol = @switch_codes.include?(@cur_element - TOTAL_TILES - 1) ? '$' : '@'
          text = "#{symbol}#{@element_index}"
          text += ":#{@components[3].text.gsub('|', ':')}" if @components[3].text != ''
          @objects[map_pos.x][map_pos.y].obj = text
        end
      end
    elsif Mouse.button_down? :right
      if Mouse.over? @editable_area
        map_pos = @map.get_map_pos(Mouse.x - @margin.x, Mouse.y)
        @ramps.each do |ramp|
          coords = ramp.split(':')[1].split(',')
          x = coords[0].to_i; y = coords[1].to_i
          a = ramp[1] == "'" ? 2 : 1
          w = ramp[a].to_i * 32; h = ramp[a + 1].to_i * 32
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

  def check_fill(i, j, code)
    if @tile_type == 2; @objects[i][j].back = code
    else; @objects[i][j].hide = 'h00'; end
    check_fill i - 1, j, code if i > 0 and cell_empty?(i - 1, j, @tile_type == 4)
    check_fill i + 1, j, code if i < @tiles_x - 1 and cell_empty?(i + 1, j, @tile_type == 4)
    check_fill i, j - 1, code if j > 0 and cell_empty?(i, j - 1, @tile_type == 4)
    check_fill i, j + 1, code if j < @tiles_y - 1 and cell_empty?(i, j + 1, @tile_type == 4)
  end

  def cell_empty?(i, j, hide)
    (hide || @objects[i][j].back.nil?) &&
             @objects[i][j].fore.nil? &&
             @objects[i][j].obj.nil? &&
             @objects[i][j].hide.nil?
  end

  def save_file(path)
    code = "#{@tiles_x},#{@tiles_y},#{@exit_type},#{@cur_tileset + 1},#{@components[5].text}#{@dark ? ',.' : ''}#"
    last_element = get_cell_string(0, 0)
    @added_bgs.each { |bg| code += "#{bg}," }
    code = code.chop + '#'
    count = 1
    (0...@tiles_y).each do |j|
      (0...@tiles_x).each do |i|
        next if i == 0 && j == 0
        element = get_cell_string i, j
        if element == last_element &&
           (last_element == '' ||
            ((last_element[0] == 'w' ||
              last_element[0] == 'p' ||
              last_element[0] == 'b' ||
              last_element[0] == 'f' ||
              last_element[0] == 'h') && last_element.size == 3))
          count += 1
        else
          if last_element == ''
            code += "_#{count}"
          else
            code += last_element + (count > 1 ? "*#{count}" : '')
          end
          code += ';'
          last_element = element
          count = 1
        end
      end
    end
    if last_element == ''
      code = code.chop + '#'
    else
      code += last_element + (count > 1 ? "*#{count}" : '') + '#'
    end
    @ramps.each { |r| code += "#{r};" }
    code.chop! unless @ramps.empty?

    File.open(path, 'w') { |f| f.write code }
    @msg = 'Arquivo salvo'
  end

  def get_cell_string(i, j)
    str = ''
    str += @objects[i][j].back if @objects[i][j].back
    str += @objects[i][j].fore if @objects[i][j].fore
    str += @objects[i][j].hide if @objects[i][j].hide
    str += @objects[i][j].obj if @objects[i][j].obj
    str
  end

  def open_file(path)
    f = File.open(path)
    all = f.readline.chomp.split('#'); f.close
    infos = all[0].split(','); bg_infos = all[1].split(','); elms = all[2].split(';')
    @tiles_x = infos[0].to_i; @tiles_y = infos[1].to_i; @exit_type = infos[2].to_i
    @map = Map.new(32, 32, @tiles_x, @tiles_y, EDITOR_WIDTH, EDITOR_HEIGHT)
    @components[1].text = infos[0]; @components[2].text = infos[1]
    @objects = Array.new(@tiles_x) {
      Array.new(@tiles_y) {
        Cell.new
      }
    }
    @added_bgs.clear
    bg_infos.each { |bg| @added_bgs << bg }
    @cur_bg = 0
    @cur_tileset = infos[3].to_i - 1
    @tiles = Res.tileset (@cur_tileset + 1).to_s, 16, 16
    @components[5].text = infos[4]
    @components[0..5].each { |c| c.unfocus }
    @dark = infos.length > 5
    @components[19].text = @dark ? 'Dark' : 'Normal'
    i = 0; j = 0
    elms.each do |e|
      if e[0] == '_'
        i += e[1..-1].to_i
        if i >= @map.size.x
          j += i / @map.size.x
          i %= @map.size.x
        end
      elsif e.size > 3 && e[3] == '*'
        amount = e[4..-1].to_i
        tile = e[0..2]
        amount.times do
          if e[0] == 'b'; @objects[i][j].back = tile
          elsif e[0] == 'f'; @objects[i][j].fore = tile
          elsif e[0] == 'h'; @objects[i][j].hide = tile
          else; @objects[i][j].obj = tile; end
          i += 1
          begin i = 0; j += 1 end if i == @tiles_x
        end
      else
        ind = 0
        while ind < e.size
          if e[ind] == 'b'; @objects[i][j].back = e.slice(ind, 3)
          elsif e[ind] == 'f'; @objects[i][j].fore = e.slice(ind, 3)
          elsif e[ind] == 'h'; @objects[i][j].hide = e.slice(ind, 3)
          elsif e[ind] == 'p' || e[ind] == 'w'
            @objects[i][j].obj = e.slice(ind, 3)
          else
            @objects[i][j].obj = e[ind..-1]
            ind += 1000
          end
          ind += 3
        end
        i += 1
        begin i = 0; j += 1 end if i == @tiles_x
      end
    end
    @ramps.clear
    @ramps = all[3].split(';') if all[3]

    @msg = 'Arquivo aberto'
  end

  def draw
    clear 0xffffff
    @map.foreach do |i, j, x, y|
      x += @margin.x
      draw_quad x + 1, y + 1, NULL_COLOR,
                x + 31, y + 1, NULL_COLOR,
                x + 1, y + 31, NULL_COLOR,
                x + 31, y + 31, NULL_COLOR, 0 if @grid
      if @objects[i][j].back
        @tiles[@objects[i][j].back[1..2].to_i].draw x, y, 0, 2, 2
        @font.draw 'b', x + 20, y + 18, 1, 1, 1, BLACK if @grid
      end
      draw_object i, j, x, y
      if @objects[i][j].fore
        @tiles[@objects[i][j].fore[1..2].to_i].draw x, y, 0, 2, 2
        @font.draw 'f', x + 20, y + 8, 1, 1, 1, BLACK if @grid
      end
      draw_quad x, y, HIDE_COLOR,
                x + 32, y, HIDE_COLOR,
                x, y + 32, HIDE_COLOR,
                x + 32, y + 32, HIDE_COLOR, 0 if @objects[i][j].hide
    end
    @ramps.each do |r|
      p = r.split(':')[1].split(',')
      pos = @map.get_screen_pos(p[0].to_i, p[1].to_i) + @margin
      a = r[1] == "'" ? 2 : 1
      w = r[a].to_i * 32; h = r[a + 1].to_i * 32
      draw_ramp pos.x, pos.y, w, h, r[0] == 'l', a == 2
    end

    draw_quad 0, 0, WHITE,
              200, 0, WHITE,
              0, 600, WHITE,
              200, 600, WHITE, 0
    draw_quad 200, 576, WHITE,
              1224, 576, WHITE,
              200, 720, WHITE,
              1224, 720, WHITE, 0
    @components.each { |c| c.draw }

    if Mouse.over? @editable_area
      p = @map.get_map_pos(Mouse.x - @margin.x, Mouse.y)
      @font.draw "#{p.x}, #{p.y}", Mouse.x, Mouse.y - 15, 1, 1, 1, BLACK
    end

    @bgs[@cur_bg].draw 204, 580, 0, 192.0 / @bgs[@cur_bg].width, 100.0 / @bgs[@cur_bg].height
    @added_bgs.each_with_index do |b, i|
      @font.draw b, 404, 580 + i * 20, 0, 1, 1, BLACK
    end
    @elements[@element_index].draw 26 + (64 - @elements[@element_index].width) / 2,
                                   435 + (64 - @elements[@element_index].height) / 2, 0
    @tilesets[@cur_tileset].draw 0, 192, 0, 1.25, 1.25
    draw_ramp @ramp_area.x, @ramp_area.y, @ramp_area.w, @ramp_area.h, true, false

    if @cur_element < 0
      draw_selection @ramp_area.x, @ramp_area.y, @ramp_area.w, @ramp_area.h
    elsif @cur_element <= TOTAL_TILES
      draw_selection ((@cur_element - 1) % 10) * 20, 192 + ((@cur_element - 1) / 10) * 20, 20, 20
    else
      draw_selection @element_area.x, @element_area.y, @element_area.w, @element_area.h
    end

    @font.draw 'Nome:', 5, 5, 0, 1, 1, BLACK
    @font.draw 'Tiles em X:', 5, 45, 0, 1, 1, BLACK
    @font.draw 'Tiles em Y:', 5, 85, 0, 1, 1, BLACK
    @font.draw_rel @msg, 100, 610, 0, 0.5, 0, 1, 1, BLACK
    @font.draw_rel @tile_types[@tile_type], 100, 150, 0, 0.5, 0, 1, 1, BLACK
    @font.draw "Saída: #{@exit_types[@exit_type]}", 4, 570, 0, 1, 1, BLACK
    @font.draw 'BGM:', 604, 680, 0, 1, 1, BLACK
  end

  def draw_object(i, j, x, y)
    obj = @objects[i][j].obj
    if obj
      if obj[0] == 'w' || obj[0] == 'p'
        @tiles[obj[1..2].to_i].draw x, y, 0, 2, 2
        @font.draw obj[0], x + 20, y - 2, 1, 1, 1, BLACK if @grid
      elsif obj[0] == '!'
        @elements[0].draw x, y, 0
        @font.draw obj[1..-1], x, y, 0, 1, 1, BLACK if @grid
      else
        code = obj[1..-1].split(':')
        @elements[code[0].to_i].draw x, y, 0
        if @grid && code.size > 1
          code[1..-1].each_with_index do |c, i|
            @font.draw c, x, y + i * 9, 0, 0.75, 0.75, BLACK
          end
        end
      end
    end
  end

  def draw_ramp(x, y, w, h, left, up)
    draw_triangle x + (left ? w : 0), y, up ? RAMP_UP_COLOR : RAMP_COLOR,
                  x, y + h, up ? RAMP_UP_COLOR : RAMP_COLOR,
                  x + w, y + h, up ? RAMP_UP_COLOR : RAMP_COLOR, 0
  end

  def draw_selection(x, y, w, h)
    draw_quad x, y, SELECTION_COLOR,
              x + w, y, SELECTION_COLOR,
              x, y + h, SELECTION_COLOR,
              x + w, y + h, SELECTION_COLOR, 0
  end
end

SBEditor.new.show
