module Crinder::Option
  # Defines an option that becomes a named argument of `.render`.
  #
  # ```
  # option name : type = default
  # ```
  #
  # - **name**: (required) the local variable name for the option that can be used in `value`, `if` or `unless`.
  # - **type**: the type of the option.
  # - **default**: the default value of the option.
  macro option(decl)
    {%
      if decl.is_a? TypeDeclaration
        name = decl.var.id
        type = decl.type
        value = decl.value
        OPTIONS[name] = {} of Nil => Nil
        OPTIONS[name][:type] = type
        if !value.is_a? Nop
          OPTIONS[name][:default] = value
        end
      elsif decl.is_a? Assign
        name = decl.target.id
        value = decl.value
        OPTIONS[name] = {} of Nil => Nil
        OPTIONS[name][:default] = value
      else
        OPTIONS[decl.id] = {} of Nil => Nil
      end
    %}
  end
end
