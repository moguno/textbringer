require "simplecov"
require "test/unit"

SimpleCov.start

if ENV["UPLOAD_TO_CODECOV"]
  require "codecov"
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require "textbringer"

module Textbringer

  null_controller = Object.new
  def null_controller.method_missing(mid, *args)
    nil
  end
  Controller.current = null_controller

  class FakeCursesWindow
    attr_reader :cury, :curx, :contents

    def initialize(lines, columns, y, x)
      @lines = lines
      @columns = columns
      @y = y
      @x = x
      @curx = 0
      @cury = 0
      @contents = @lines.times.map { String.new }
    end

    def move(y, x)
      @y = y
      @x = x
    end

    def resize(lines, columns)
      @lines = lines
      @columns = columns
    end

    def maxy
      @lines
    end

    def maxx
      @columns
    end

    def erase
      @contents.each do |line|
        line.clear
      end
    end

    def setpos(y, x)
      @cury = y
      @curx = x
    end

    def addstr(s)
      @contents[@cury].concat(s)
      @curx = Textbringer::Buffer.display_width(@contents[@cury])
      if @curx > @columns
        raise RangeError, "Out of window: #{@curx} > #{@columns}"
      end
    end

    def method_missing(mid, *args)
    end
  end

  class Window
    @fake_lines = 24
    @fake_columns = 80

    class << self
      undef lines
      def lines
        @fake_lines
      end

      def lines=(lines)
        @fake_lines = lines
      end

      undef columns
      def columns
        @fake_columns
      end

      def columns=(columns)
        @fake_columns = columns
      end

      def update
      end

      def setup
        @@windows.clear
        window =
          Textbringer::Window.new(Window.lines - 1, Window.columns, 0, 0)
        window.buffer = Buffer.new_buffer("*scratch*")
        @@windows.push(window)
        Window.current = window
        @@echo_area = Textbringer::EchoArea.new(1, Window.columns,
                                                Window.lines - 1, 0)
        Buffer.minibuffer.keymap = MINIBUFFER_LOCAL_MAP
        @@echo_area.buffer = Buffer.minibuffer
        @@windows.push(@@echo_area)
      end
    end

    private

    undef initialize_window
    def initialize_window(num_lines, num_columns, y, x)
      @window = FakeCursesWindow.new(num_lines - 1, num_columns, y, x)
      @mode_line = FakeCursesWindow.new(1, num_columns, y + num_lines - 1, x)
    end
  end

  class EchoArea
    private

    undef initialize_window
    def initialize_window(num_lines, num_columns, y, x)
      @window = FakeCursesWindow.new(num_lines, num_columns, y, x)
    end
  end

  class TestCase < Test::Unit::TestCase
    def setup
      Buffer.kill_em_all
      KILL_RING.clear
      Window.setup
    end
  end
end
