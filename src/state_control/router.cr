require "./table.cr"

class StateControl(T)
  module Router(T)
    private def route_enable(**options)
      each_recognized_route(**options) do |src, dest|
        add_route(src, dest) unless restricted?(src, dest)
      end
    end

    private def route_disable(**options)
      each_recognized_route(**options) do |src, dest|
        delete_route(src, dest)
      end
    end

    private def each_recognized_route(**options)
      options.each do |k, v|
        translate(k).cartesian_product(translate(v))
          .each { |src, dest| yield src, dest }
      end
    end

    protected def possible_from(src)
      @@routes.select(&.first.==(src)).map(&.last)
    end

    private def add_route(src, dest)
      @@routes.add?({src, dest})
    end

    private def delete_route(src, dest)
      @@routes.delete({src, dest})
    end

    private def restricted?(src, dest)
      src == dest
    end

    private def translate(key)
      translate([key])
    end

    private def translate(keys : Enumerable)
      keys.uniq
        .flat_map { |key| translate_one(key) }
        .uniq!
    end

    private def translate_one(key)
      key == :any ? T.values : T.parse(key.to_s)
    end

    protected def route?(src, dest)
      @@routes.includes?({src, dest})
    end

    def inspect_routes(io = STDOUT)
      table = Table.new(T.names.unshift("->"))
      T.each do |name|
        row = [name.to_s]
        T.each { |col| row << (route?(name, col) ? "X" : "") }
        table.add_row(row)
      end
      io << "\n"
      table.render(io)
    end
  end
end
