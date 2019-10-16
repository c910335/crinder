require "json"
require "./crinder/*"

# `Crinder::Base` is the base renderer of type `T`.
#
# To define your own renderer, you need to inherit `Crinder::Base` with specific type and declare the fields with `Crinder::Field.field`.
#
# For example, this is a renderer of [Time](https://crystal-lang.org/api/latest/Time.html).
#
# ```
# class TimeRenderer < Crinder::Base(Time)
#   field year : Int
#   field month : Int
#   field day : Int
#   field hour : Int
#   field minute : Int
#   field second : Int
# end
# ```
#
# Then `.render` will be auto generated.
#
# ```
# time = Time.new(2018, 3, 15, 16, 21, 1)
# TimeRenderer.render(time) # => "{\"year\":2018,\"month\":3,\"day\":15,\"hour\":16,\"minute\":21,\"second\":1}"
# ```
class Crinder::Base(T)
  include Field
  include Option

  @@object : T?

  # the getter of the object to be rendered, which can be used in `value`, `if` or `unless`
  def self.object
    @@object.not_nil!
  end

  # :nodoc:
  macro __inherited
    FIELDS = {} of Nil => Nil
    OPTIONS = {} of Nil => Nil

    \{% for name, options in {{@type.superclass}}::FIELDS %}
      \{% FIELDS[name] = options %}
      __field(\{{name}})
    \{% end %}

    \{% for name, options in {{@type.superclass}}::OPTIONS %}
      \{% OPTIONS[name] = options %}
    \{% end %}

    macro finished
      __process
    end
  end

  macro inherited
    FIELDS = {} of Nil => Nil
    OPTIONS = {} of Nil => Nil

    macro inherited
      __inherited
    end

    macro finished
      __process
    end
  end

  # :nodoc:
  macro __process
    def self.render(object : T | Array(T), **options) : String
      JSON.build do |json|
        render(object, json, **options)
      end
    end

    def self.render(objects : Array(T), json : JSON::Builder, **options)
      json.array do
        objects.each do |object|
          render(object, json, **options)
        end
      end
    end

    def self.render(
      object : T,
      json : JSON::Builder\
      {% if !OPTIONS.empty? %}\
        , *\
        {% for name, options in OPTIONS %}\
          , {{name}}\
          {% if !options[:type].is_a? NilLiteral %} \
            : {{options[:type]}}\
          {% end %}\
          {% if !options[:default].is_a? NilLiteral %} \
            = {{options[:default]}}\
          {% end %}\
        {% end %}
      {% end %}
    )
      {% if T >= Nil %}
        if object.nil?
          return json.null
        end
      {% end %}
      @@object = object
      json.object do
        {% for name, options in FIELDS %}
          {% if options %}
            __if_show({{name}}) do
              %field = "{{(options[:as] || name).id}}"
              {% if render_with = options[:with] %}
                json.field %field do
                  {{render_with}}.render(__value_of({{name}}), json)
                end
              {% else %}
                json.field %field, __value_of({{name}})
              {% end %}
            end
          {% end %}
        {% end %}
      end
    end
  end
end
