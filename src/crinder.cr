require "json"
require "./crinder/*"

# `Crinder::Base` is the base renderer of type `T`.
#
# To define your own renderer, you need to inherit `Crinder::Base` with specific type and declare the fields with `field`.
#
# For example, this is a renderer of [Time](https://crystal-lang.org/api/0.24.2/Time.html).
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
  @@object : T?

  # the getter of the object to be rendered, which can be used in `value`, `if` or `unless`
  def self.object
    @@object.not_nil!
  end

  # :nodoc:
  SETTINGS = {} of Nil => Nil

  # :nodoc:
  macro __inherited
    {% SETTINGS[@type.id] = {} of Nil => Nil %}
    {% for key, value in SETTINGS[@type.superclass.id] %}
      {% SETTINGS[@type.id][key] = value %}
    {% end %}

    macro inherited
      __inherited
    end

    macro finished
      __process
    end
  end

  macro inherited
    {% SETTINGS[@type.id] = {} of Nil => Nil %}

    macro inherited
      __inherited
    end

    macro finished
      __process
    end
  end

  # Defines a field.
  #
  # This also creates an alias `{{name}}` for `object.{{name}}`, which can be used in `value`, `if` or `unless`.
  #
  # ### Example
  #
  # See [README](../index.html) or [Overview](#top).
  #
  # ### Usage
  #
  # `field` requries a name or a type declaration and a series of named arguments as options.
  #
  # ```
  # field name : type, **options
  # ```
  #
  # - **name**: (required) the field name to be rendered
  # - **as**: the name to be replaced in the rendered json
  # - **type**: the type for auto casting. For example, if it is `String`, `#to_s` of the field will be called for rendering. This is JSON Type but not Crystal Type, so it must be one of [JSON::Type](https://crystal-lang.org/api/0.24.2/JSON/Type.html), and it should be `Int` instead of `Int64` or `Int32` if this field is integer, and so does `Float`. If it is `Nil` or not provided, no casting method will be performed.
  # - **value**: a lambda, a class method or a constant to replace the value. By default, it is an auto generated class method `name` which casting the field to `type`. If `value` is provided, `type` becomes useless because `value` replaces the auto generated class method. However, it is still recommended to declare `type` for understandability. Don't use `value` and `as` together because it makes `name` meaningless.
  # - **with**: a renderer for this field. This field will be filtered by `value` before passing to it. It is not necessary to be a subclass of `Crinder::Base`, but it must have the class method `render(object : T, json : JSON::Builder)` where `T` is the original type of this field.
  # - **if**: a lambda, a class method or a constant to determine whether to show this field.
  # - **unless**: opposite of `if`. If both `if` and `unless` are provided, this field is only showed when `if` is *truthy* and `unless` is *falsey*.
  macro field(decl, **options)
    {%
      name = decl
      type = Object
      nilable = false
      if decl.is_a? TypeDeclaration
        name = decl.var
        type = decl.type
      end
      if type.is_a? Union
        nilable = type.types.any?(&.resolve.nilable?)
        type = type.types.reject(&.resolve.nilable?)[0]
      end
      if type.is_a? Path
        type = type.resolve
        nilable = nilable || type == Nil
      end
      name = name.id
      SETTINGS[@type.id][name] = options || {} of Nil => Nil
      SETTINGS[@type.id][name][:type] = type
      value = options[:value]
    %}

    def self.{{name}}
      object.{{name}}
    end

    {% if value.is_a? NilLiteral %}
      {% SETTINGS[@type.id][name][:value] = ("__casted_" + name.stringify).id %}

      def self.__casted_{{name}}
        {% if nilable %}
          return nil if object.{{name}}.nil?
        {% end %}
        {% if type <= Array %}
          object.{{name}}.to_a
        {% elsif type <= Bool %}
          !!object.{{name}}
        {% elsif type <= Float %}
          object.{{name}}.to_f64
        {% elsif type <= Hash %}
          object.{{name}}.to_h
        {% elsif type <= String %}
          object.{{name}}.to_s
        {% elsif type <= Int %}
          object.{{name}}.to_i64
        {% else %}
          object.{{name}}
        {% end %}
      end
    {% end %}
  end

  # Undefines a field.
  macro remove(name)
    {% name = name.id %}
    {% SETTINGS[@type.id][name] = {:unless => true} %}

    def self.{{name}}
      nil
    end

    def self.__casted_{{name}}
      nil
    end
  end

  # :nodoc:
  macro __if_show(name)
    {%
      options = SETTINGS[@type.id][name.id]
      show_unless = options[:unless]
      show_if = options[:if]
      show_if = true if show_if.is_a? NilLiteral
    %}

    %show = {% if show_unless.is_a? ProcLiteral %}
              !{{show_unless}}.call
            {% else %}
              !{{show_unless}}
            {% end %}
    %show &&= {% if show_if.is_a? ProcLiteral %}
                {{show_if}}.call
              {% else %}
                {{show_if}}
              {% end %}

    if %show
      {{yield}}
    end
  end

  # :nodoc:
  macro __value_of(name)
    {% value = SETTINGS[@type.id][name.id][:value] %}
    {% if value.is_a? ProcLiteral %}
      {{value}}.call
    {% else %}
      {{value}}
    {% end %}
  end

  # :nodoc:
  macro __process
    def self.render(objects : Array(T)) : String
      JSON.build do |json|
        json.array do
          objects.each do |object|
            render(object, json)
          end
        end
      end
    end

    def self.render(object : T) : String
      JSON.build do |json|
        render(object, json)
      end
    end

    def self.render(object : T, json : JSON::Builder)
      {% if T >= Nil %}
        if object.nil?
          return json.null
        end
      {% end %}
      @@object = object
      json.object do
        {% for name, options in SETTINGS[@type.id] %}
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
      end
    end
  end
end
