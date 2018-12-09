require 'minigl'
include MiniGL

Cell = Struct.new(:back, :fore, :obj, :hide)

class FloatingPanel
  COLOR = 0x80ffffff

  attr_reader :x, :y, :w, :h, :children
  attr_accessor :visible

  def initialize(x, y, w, h, children, editor)
    @x = x
    @y = y
    @w = w
    @h = h
    @children = children
    @buttons = children.map.with_index do |c, i|
      Button.new(x: @x + c[:x], y: @y + c[:y], width: c[:img].width * 2, height: c[:img].height * 2, params: i) do |p|
        editor.cur_index = p
        @visible = false
      end
    end
    @visible = false
  end

  def update
    return unless @visible
    @buttons.each(&:update)
  end

  def draw
    return unless @visible
    G.window.draw_quad(@x, @y, COLOR,
                       @x + @w, @y, COLOR,
                       @x, @y + @h, COLOR,
                       @x + @w, @y + @h, COLOR, 1)
    @children.each do |c|
      c[:img].draw(@x + c[:x], @y + c[:y], 1, 2, 2)
    end
  end
end

class SBEditor < GameWindow
  NULL_COLOR = 0x11000000
  HIDE_COLOR = 0x33000099
  RAMP_COLOR = 0x66000000
  RAMP_UP_COLOR = 0x66990099
  SELECTION_COLOR = 0x66ffff00
  BLACK = 0xff000000
  WHITE = 0xffffffff

  attr_writer :cur_index

  def initialize
    @scr_w, @scr_h = `xrandr`.scan(/current (\d+) x (\d+)/).flatten.map(&:to_i)
    super @scr_w, @scr_h, true
    Res.retro_images = true

    @tiles_x = @tiles_y = 300
    @map = Map.new(32, 32, @tiles_x, @tiles_y, @scr_w, @scr_h)
    @objects = Array.new(@tiles_x) {
      Array.new(@tiles_y) {
        Cell.new
      }
    }

    @ramps = []
    @dir = '../super-bombinhas/data'
    @font1 = Res.font :minecraftia, 6
    @font2 = Res.font :minecraftia, 10
    @cur_index = -1

    bg_files = Dir["#{Res.prefix}#{Res.img_dir}bg/*"].sort
    @bgs = []
    bg_options = []
    bg_files.each do |f|
      num = f.split('/')[-1].chomp('.png')
      @bgs << Res.img("bg_#{num}")
      bg_options << num
    end
    @cur_bg = 0

    bgm_options = []
    Dir["#{@dir}/song/s*"].sort.each{ |f| bgm_options << f.split('/')[-1].chomp('.ogg') }
    @cur_bgm = 0

    exit_options = %w(/\\ > \\/ < -)

    ts_files = Dir["#{Res.prefix}#{Res.tileset_dir}*"].sort
    @tilesets = []
    ts_options = []
    ts_files.each do |f|
      num = f.split('/')[-1].chomp('.png')
      @tilesets << Res.tileset(num, 16, 16)
      ts_options << num
    end
    @cur_tileset = 0

    @cur_exit = 0

    el_files = Dir["#{Res.prefix}#{Res.img_dir}el/*"]
    @elements = []
    @enemies = []
    @objs = []
    el_files.each do |f|
      name = f.split('/')[-1].chomp('.png')
      img = Res.img("el_#{name}")
      @elements << img
      (name.end_with?('!') ? @enemies : @objs) << img
    end
    @bomb = Res.img(:Bomb)

    save_confirm = false

    @panels = [

      ################################## Geral ##################################
      Panel.new(0, 0, 500, 48, [
        Label.new(x: 10, y: 0, font: @font2, text: 'W', scale_x: 2, scale_y: 2, anchor: :left),
        (txt_w = TextField.new(x: 20, y: 0, img: :textField, font: @font2, text: '300', allowed_chars: '0123456789', margin_x: 2, margin_y: 3, scale_x: 2, scale_y: 2, anchor: :left) do |t|
          reset_map(t.to_i, @tiles_y)
        end),
        Label.new(x: 70, y: 0, font: @font2, text: 'H', scale_x: 2, scale_y: 2, anchor: :left),
        (txt_h = TextField.new(x: 86, y: 0, img: :textField, font: @font2, text: '300', allowed_chars: '0123456789', margin_x: 2, margin_y: 3, scale_x: 2, scale_y: 2, anchor: :left) do |t|
          reset_map(@tiles_x, t.to_i)
        end),
        Label.new(x: 136, y: 0, font: @font2, text: 'BG', scale_x: 2, scale_y: 2, anchor: :left),
        (ddl_bg = DropDownList.new(x: 160, y: 0, font: @font2, img: :ddl, opt_img: :ddlOpt, options: bg_options, text_margin: 4, scale_x: 2, scale_y: 2, anchor: :left) do |_, v|
          @cur_bg = bg_options.index(v)
        end),
        Label.new(x: 204, y: 0, font: @font2, text: 'BGM', scale_x: 2, scale_y: 2, anchor: :left),
        (ddl_bgm = DropDownList.new(x: 240, y: 0, font: @font2, img: :ddl, opt_img: :ddlOpt, options: bgm_options, text_margin: 4, scale_x: 2, scale_y: 2, anchor: :left) do |_, v|
          @cur_bgm = bgm_options.index(v)
        end),
        Label.new(x: 285, y: 0, font: @font2, text: 'Exit', scale_x: 2, scale_y: 2, anchor: :left),
        (ddl_exit = DropDownList.new(x: 325, y: 0, font: @font2, img: :ddl, opt_img: :ddlOpt, options: exit_options, text_margin: 4, scale_x: 2, scale_y: 2, anchor: :left) do |_, v|
          @cur_exit = exit_options.index(v)
        end),
        Label.new(x: 30, y: 0, font: @font2, text: 'Dark', scale_x: 2, scale_y: 2, anchor: :right),
        (chk_dark = ToggleButton.new(x: 10, y: 0, img: :chk, scale_x: 2, scale_y: 2, anchor: :right))
      ], :pnl, :tiled, true, 2, 2, :top),
      ###########################################################################

      ################################# Tileset #################################
      Panel.new(0, 0, 48, 300, [
        (ddl_ts = DropDownList.new(x: 0, y: 4, font: @font2, img: :ddl, opt_img: :ddlOpt, options: ts_options, text_margin: 4, scale_x: 2, scale_y: 2, anchor: :top) do |_, v|
          @cur_tileset = ts_options.index(v)
        end),
        Button.new(x: 0, y: 38, img: :btn1, font: @font1, text: 'WALL', scale_x: 2, scale_y: 2, anchor: :top) do
          @cur_element = :wall
        end,
        Button.new(x: 0, y: 38 + 44, img: :btn1, font: @font1, text: 'PASS', scale_x: 2, scale_y: 2, anchor: :top) do
          @cur_element = :pass
        end,
        Button.new(x: 0, y: 38 + 88, img: :btn1, font: @font1, text: 'HIDE', scale_x: 2, scale_y: 2, anchor: :top) do
          @cur_element = :hide
        end,
        (other_tile_btn = Button.new(x: 0, y: 38 + 132, img: :btn1, font: @font1, text: 'OTHER', scale_x: 2, scale_y: 2, anchor: :top) do
          @floating_panels[0].visible = !@floating_panels[0].visible
        end),
        (ramp_btn = Button.new(x: 0, y: 38 + 176, img: :btn1, font: @font1, text: 'RAMP', scale_x: 2, scale_y: 2, anchor: :top) do
          @floating_panels[1].visible = !@floating_panels[1].visible
        end),
      ], :pnl, :tiled, true, 2, 2, :left),
      ###########################################################################

      ################################# Arquivo #################################
      Panel.new(0, 0, 460, 48, [
        Label.new(x: 7, y: 0, font: @font2, text: 'World', scale_x: 2, scale_y: 2, anchor: :left),
        (txt_world = TextField.new(x: 57, y: 0, font: @font2, img: :textField, margin_x: 2, margin_y: 3, scale_x: 2, scale_y: 2, text: '1', anchor: :left)),
        Label.new(x: 107, y: 0, font: @font2, text: 'Stage', scale_x: 2, scale_y: 2, anchor: :left),
        (txt_stage = TextField.new(x: 157, y: 0, font: @font2, img: :textField, margin_x: 2, margin_y: 3, scale_x: 2, scale_y: 2, text: '1', anchor: :left)),
        Label.new(x: 207, y: 0, font: @font2, text: 'Section', scale_x: 2, scale_y: 2, anchor: :left),
        (txt_section = TextField.new(x: 277, y: 0, font: @font2, img: :textField, margin_x: 2, margin_y: 3, scale_x: 2, scale_y: 2, text: '1', anchor: :left)),
        Button.new(x: 48, y: 0, img: :btn1, font: @font1, text: 'LOAD', scale_x: 2, scale_y: 2, anchor: :right) do
          path = "#{@dir}/stage/#{txt_world.text}/#{txt_stage.text}-#{txt_section.text}"
          if File.exist? path
            f = File.open(path)
            all = f.readline.chomp.split('#'); f.close
            infos = all[0].split(','); bg_infos = all[1].split(','); elms = all[2].split(';')
            @tiles_x = infos[0].to_i; @tiles_y = infos[1].to_i
            @map = Map.new(32, 32, @tiles_x, @tiles_y, @scr_w, @scr_h)
            txt_w.text = infos[0]; txt_h.text = infos[1]
            @objects = Array.new(@tiles_x) {
              Array.new(@tiles_y) {
                Cell.new
              }
            }

            @cur_exit = infos[2].to_i
            ddl_exit.value = exit_options[@cur_exit]

            ddl_bg.value = bg_infos[0]
            @cur_bg = bg_options.index(ddl_bg.value)
            ddl_ts.value = infos[3]
            @cur_tileset = ts_options.index(ddl_ts.value)
            ddl_bgm.value = infos[4]
            @cur_bgm = bgm_options.index(ddl_bgm.value)

            @dark = infos.length > 5
            chk_dark.checked = @dark

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
          end
        end,
        Button.new(x: 4, y: 0, img: :btn1, font: @font1, text: 'SAVE', scale_x: 2, scale_y: 2, anchor: :right) do
          path = "#{@dir}/#{name.gsub('|', '/')}"
          will_save = if save_confirm
                        save_confirm = false
                        File.delete path
                        true
                      elsif File.exist? path
                        @msg = 'Salvar por cima?'
                        save_confirm = true
                        false
                      else
                        true
                      end
          if will_save
            code = "#{@tiles_x},#{@tiles_y},#{@cur_exit},#{ddl_ts.value},#{ddl_bgm.value}#{@dark ? ',.' : ''}##{ddl_bg.value}#"

            count = 1
            last_element = get_cell_string(0, 0)
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
        end,
      ], :pnl, :tiled, true, 2, 2, :bottom),
      ###########################################################################

      ################################ Elementos ################################
      Panel.new(0, 0, 48, 300, [
        Button.new(x: 0, y: 4, img: :btn1, font: @font1, text: 'BOMB', scale_x: 2, scale_y: 2, anchor: :top) do

        end,
        Label.new(x: 0, y: 48, font: @font1, text: 'Default', scale_x: 2, scale_y: 2, anchor: :top),
        ToggleButton.new(x: 0, y: 60, img: :chk, checked: true, scale_x: 2, scale_y: 2, anchor: :top),
        (btn_obj = Button.new(x: 0, y: 100, img: :btn1, font: @font1, text: 'OBJ.', scale_x: 2, scale_y: 2, anchor: :top) do
          @floating_panels[2].visible = !@floating_panels[2].visible
        end),
        (btn_enemy = Button.new(x: 0, y: 144, img: :btn1, font: @font1, text: 'ENEMY', scale_x: 2, scale_y: 2, anchor: :top) do
          @floating_panels[3].visible = !@floating_panels[3].visible
        end),
        TextField.new(x: 0, y: 188, img: :textField, font: @font2, margin_x: 2, margin_y: 3, scale_x: 2, scale_y: 2, anchor: :top)
      ], :pnl, :tiled, true, 2, 2, :right)
      ###########################################################################

    ]

    @floating_panels = [
      FloatingPanel.new(other_tile_btn.x + 40, other_tile_btn.y, 337, 172, @tilesets[@cur_tileset][50..-1].map.with_index{ |t, i| { img: t, x: 4 + (i % 10) * 33, y: 4 + (i / 10) * 33 } }, self),
      FloatingPanel.new(ramp_btn.x + 40, ramp_btn.y, 271, 40, (0..7).map { |i| { img: Res.img("ramp#{i}"), x: 4 + i * 33, y: 4 } }, self),
      FloatingPanel.new(btn_obj.x - 337, btn_obj.y, 337, 300, @objs.map.with_index{ |o, i| { img: o, x: 4 + (i % 10) * 33, y: 4 + (i / 10) * 33 } }, self),
      FloatingPanel.new(btn_enemy.x - 337, btn_enemy.y, 337, 300, @enemies.map.with_index{ |o, i| { img: o, x: 4 + (i % 10) * 33, y: 4 + (i / 10) * 33 } }, self),
    ]

    @dropdowns = [ddl_bg, ddl_bgm, ddl_exit, ddl_ts]
  end

  def needs_cursor?
    true
  end

  def update
    KB.update
    Mouse.update
    close if KB.key_pressed? Gosu::KbEscape

    @over_panel = [false, false, false, false]
    @dropdowns.each_with_index do |d, i|
      h = d.instance_eval('@open') ? d.instance_eval('@max_h') : d.h
      @over_panel[i < 3 ? 0 : 1] = true if Mouse.over?(d.x, d.y, d.w, h)
    end
    @floating_panels.each do |p|
      p.update
      @over_panel[1] = true if Mouse.over?(p.x, p.y, p.w, p.h)
    end
    @panels.each_with_index do |p, i|
      p.update
      @over_panel[i] = true if Mouse.over?(p.x, p.y, p.w, p.h)
    end

    speed = KB.key_down?(Gosu::KbLeftShift) || KB.key_down?(Gosu::KbRightShift) ? 10 : 20
    @map.move_camera 0, -speed if KB.key_down? Gosu::KbUp
    @map.move_camera speed, 0 if KB.key_down? Gosu::KbRight
    @map.move_camera 0, speed if KB.key_down? Gosu::KbDown
    @map.move_camera -speed, 0 if KB.key_down? Gosu::KbLeft

=begin
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
=end
  end

  def reset_map(tiles_x, tiles_y)
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
    @map = Map.new 32, 32, tiles_x, tiles_y, @scr_w, @scr_h
    @tiles_x = tiles_x; @tiles_y = tiles_y
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

  def get_cell_string(i, j)
    str = ''
    str += @objects[i][j].back if @objects[i][j].back
    str += @objects[i][j].fore if @objects[i][j].fore
    str += @objects[i][j].hide if @objects[i][j].hide
    str += @objects[i][j].obj if @objects[i][j].obj
    str
  end

  def draw
    clear 0xddddff

    @map.foreach do |i, j, x, y|
      draw_quad x + 1, y + 1, NULL_COLOR,
                x + 31, y + 1, NULL_COLOR,
                x + 1, y + 31, NULL_COLOR,
                x + 31, y + 31, NULL_COLOR, 0
      if @objects[i][j].back
        @tilesets[@cur_tileset][@objects[i][j].back[1..2].to_i].draw x, y, 0, 2, 2
        @font1.draw 'b', x + 20, y + 18, 1, 1, 1, BLACK
      end
      draw_object i, j, x, y
      if @objects[i][j].fore
        @tilesets[@cur_tileset][@objects[i][j].fore[1..2].to_i].draw x, y, 0, 2, 2
        @font1.draw 'f', x + 20, y + 8, 1, 1, 1, BLACK
      end
      draw_quad x, y, HIDE_COLOR,
                x + 32, y, HIDE_COLOR,
                x, y + 32, HIDE_COLOR,
                x + 32, y + 32, HIDE_COLOR, 0 if @objects[i][j].hide
    end
    @ramps.each do |r|
      p = r.split(':')[1].split(',')
      pos = @map.get_screen_pos(p[0].to_i, p[1].to_i)
      a = r[1] == "'" ? 2 : 1
      w = r[a].to_i * 32; h = r[a + 1].to_i * 32
      draw_ramp pos.x, pos.y, w, h, r[0] == 'l', a == 2
    end

    @panels.each_with_index do |p, i|
      p.draw(@over_panel[i] ? 255 : 153)
    end

    @floating_panels.each(&:draw)

    @font2.draw(@cur_index.to_s, 0, 0, 1, 2, 2, BLACK)

    unless @over_panel.any?
      p = @map.get_map_pos(Mouse.x, Mouse.y)
      @font2.draw "#{p.x}, #{p.y}", Mouse.x, Mouse.y - 15, 1, 2, 2, BLACK
    end
  end

  def draw_object(i, j, x, y)
    obj = @objects[i][j].obj
    if obj
      if obj[0] == 'w' || obj[0] == 'p'
        @tilesets[@cur_tileset][obj[1..2].to_i].draw x, y, 0, 2, 2
        @font1.draw obj[0], x + 20, y - 2, 1, 1, 1, BLACK
      elsif obj[0] == '!'
        @bomb.draw x, y, 0
        @font1.draw obj[1..-1], x, y, 0, 1, 1, BLACK
      else
        code = obj[1..-1].split(':')
        @elements[code[0].to_i].draw x, y, 0
        if code.size > 1
          code[1..-1].each_with_index do |c, i|
            @font1.draw c, x, y + i * 9, 0, 0.75, 0.75, BLACK
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
end

SBEditor.new.show
