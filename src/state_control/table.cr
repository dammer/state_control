class Table
  SINGLE_LINE_STYLE = {
    bottom_left:      "└",
    bottom_right:     "┘",
    bottom_vertical:  "┴",
    horizontal:       "─",
    intersection:     "┼",
    left_horizontal:  "├",
    right_horizontal: "┤",
    top_left:         "┌",
    top_right:        "┐",
    top_vertical:     "┬",
    vertical:         "│",
  }

  enum AdjustWidth
    Personal
    Maximal
  end

  @headers : Array(String)
  @rows : Array(Array(String))
  @adjust_width : AdjustWidth = :maximal
  @template = SINGLE_LINE_STYLE

  private getter column_maximal_width : Int32 { adjust_width_maximal }
  private getter columns_width : Array(Int32) { adjust_width_personal }

  def initialize(@headers, @margin = 1)
    @row_size = @headers.size
    @rows = Array(Array(String)).new
  end

  def add_row(row)
    @rows << row
  end

  def render(io = STDOUT, **options)
    if aw = options[:adjust_width]?
      self.adjust_width_by(AdjustWidth.parse(aw.to_s))
    end
    io.puts generate_table
  end

  private def generate_table
    String.build do |io|
      io << top
      io << render_values(@headers)
      @rows.each do |row|
        io << middle
        io << render_values(row)
      end
      io << bottom
    end
  end

  private def top
    separator(:top_left, :horizontal, :top_vertical, :top_right)
  end

  private def middle
    separator(:left_horizontal, :horizontal, :intersection, :right_horizontal)
  end

  private def bottom
    separator(:bottom_left, :horizontal, :bottom_vertical, :bottom_right)
  end

  private def separator(l, h, i, r)
    String.build do |io|
      io << @template[l]
      @row_size.times.map { |idx| @template[h] * column_width(idx) }.join(io, @template[i])
      io << @template[r]
      io << "\n"
    end
  end

  private def render_values(values : Enumerable, l = :vertical, m = :vertical, r = :vertical)
    String.build do |io|
      io << @template[l]
      values.map_with_index { |val, idx| val.center(column_width(idx)) }.join(io, @template[m])
      io << @template[r]
      io << "\n"
    end
  end

  private def column_width(idx)
    @adjust_width.personal? ? columns_width[idx] : column_maximal_width
  end

  private def adjust_width_personal
    [@headers, *@rows].transpose.map { |col| col.max_of(&.size) + @margin * 2 }
  end

  private def adjust_width_maximal
    [@headers, *@rows].flatten.max_of(&.size) + @margin * 2
  end

  private def adjust_width_by(value : AdjustWidth)
    return value if @adjust_width == value
    clear_cached_widths
    @adjust_width = value
  end

  private def clear_cached_widths
    @columns_width = nil
    @column_maximal_width = nil
  end
end
