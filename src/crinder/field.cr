module Crinder::Field
  # Defines a field.
  #
  # This also creates an alias `{{name}}` for `object.{{name}}`, which can be used in `value`, `if` or `unless`.
  #
  # ### Example
  #
  # See [README](../index.html) or `Crinder::Base`.
  #
  # ### Usage
  #
  # `field` requries a name or a type declaration and a series of named arguments.
  #
  # ```
  # field name : type, **named_arguments
  # ```
  #
  # - **name**: (required) the field name to be rendered
  # - **as**: the name to be replaced in the rendered json
  # - **type**: the type for auto casting. For example, if it is `String`, `#to_s` of the field will be called for rendering. This is JSON Type but not Crystal Type, so it must be one of [JSON::Any::Type](https://crystal-lang.org/api/latest/JSON/Any/Type.html), and it should be `Int` instead of `Int64` or `Int32` if this field is integer, and so does `Float`. If it is `Nil` or not provided, no casting method will be performed.
  # - **value**: a lambda, a class method or a constant to replace the value. By default, it is an auto generated class method `name` which casting the field to `type`. If `value` is provided, `type` becomes useless because `value` replaces the auto generated class method. However, it is still recommended to declare `type` for understandability. Don't use `value` and `as` together because it makes `name` meaningless.
  # - **with**: a renderer for this field. This field will be filtered by `value` before passing to it. It is not necessary to be a subclass of `Crinder::Base`, but it must have the class method `render(object : T | Array(T), json : JSON::Builder)` where `T` is the original type of this field.
  # - **options**: options passing to the `with` renderer.
  # - **if**: a lambda, a class method or a constant to determine whether to show this field.
  # - **unless**: opposite of `if`. If both `if` and `unless` are provided, this field is only showed when `if` is *truthy* and `unless` is *falsey*.
  macro field(decl, **nargs)
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
      if type.is_a? Path || type.is_a? Generic
        type = type.resolve
        nilable = nilable || type == Nil
      end
      name = name.id
      FIELDS[name] = nargs || {} of Nil => Nil
      FIELDS[name][:type] = type
      FIELDS[name][:nilable] = nilable
    %}
    __field({{name}})
  end

  # :nodoc:
  macro __field(name)
    {% name = name.id %}
    {% if FIELDS[name] %}

      def self.{{name}}
        object.{{name}}
      end

      {% if FIELDS[name][:value].is_a? NilLiteral %}
        {% FIELDS[name][:value] = ("__casted_" + name.stringify).id %}
        {% type = FIELDS[name][:type] %}

        def self.__casted_{{name}}
          {% if FIELDS[name][:nilable] %}
            return nil if object.{{name}}.nil?
            %not_nil = object.{{name}}.not_nil!
          {% else %}
            %not_nil = object.{{name}}
          {% end %}
          {% if type <= Array %}
            %not_nil.to_a
          {% elsif type <= Bool %}
            !!%not_nil
          {% elsif type <= Float %}
            %not_nil.to_f64
          {% elsif type <= Hash %}
            %not_nil.to_h
          {% elsif type <= String %}
            %not_nil.to_s
          {% elsif type <= Int %}
            %not_nil.to_i64
          {% else %}
            %not_nil
          {% end %}
        end
      {% end %}
    {% end %}
  end

  # Undefines a field.
  macro remove(name)
    {% name = name.id %}
    {% FIELDS[name] = nil %}

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
      options = FIELDS[name.id]
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
    {% value = FIELDS[name.id][:value] %}
    {% if value.is_a? ProcLiteral %}
      {{value}}.call
    {% else %}
      {{value}}
    {% end %}
  end
end
