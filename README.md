# Crinder

[![Crystal CI](https://github.com/c910335/crinder/actions/workflows/crystal.yml/badge.svg)](https://github.com/c910335/crinder/actions/workflows/crystal.yml)
[![GitHub releases](https://img.shields.io/github/release/c910335/crinder.svg)](https://github.com/c910335/crinder/releases)
[![GitHub license](https://img.shields.io/github/license/c910335/crinder.svg)](https://github.com/c910335/crinder/blob/master/LICENSE)

Class based json renderer in Crystal

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  crinder:
    github: c910335/crinder
```

## Usage

### Basic

```crystal
require "crinder"

record Todo, name : String, priority : Int32, expires_at : Time?, created_at : Time?, updated_at : Time?

class TodoRenderer < Crinder::Base(Todo)
  field name : String, as: title
  field priority : Int, value: ->{ priority * 10 }
  field expires_at : String, as: deadline, unless: ->{ priority < 3 }
  field created_at : String, if: ->{ created_at? }
  field updated : Bool, value: updated?

  option created_at? : Bool = false

  def self.updated?
    !object.updated_at.nil?
  end
end

time = Time.utc(2018, 3, 14, 19, 55, 7)
todo = Todo.new("qaq", 8, time + 20.hours, time, nil)

TodoRenderer.render(todo, created_at?: true) # => "{\"title\":\"qaq\",\"priority\":80,\"deadline\":\"2018-03-15 15:55:07 UTC\",\"created_at\":\"2018-03-14 19:55:07 UTC\",\"updated\":false}"
```

### Inheritance

```crystal
class AnotherTodoRenderer < TodoRenderer
  field expires_at : String, unless: ->{ priority < 1 }
  field updated_at : String
  remove updated
end

todo = Todo.new("wow", 6, time + 20.hours, time, time + 10.hours)

AnotherTodoRenderer.render(todo) # => "{\"title\":\"wow\",\"priority\":60,\"expires_at\":\"2018-03-15 15:55:07 UTC\",\"updated_at\":\"2018-03-15 05:55:07 UTC\"}"
```

### Array

```crystal
todos = [Todo.new("www", 8, time + 20.hours, time, nil), Todo.new("api", 10, time + 21.hours, time, nil)]

TodoRenderer.render(todos) # => "[{\"title\":\"www\",\"priority\":80,\"deadline\":\"2018-03-15 15:55:07 UTC\",\"updated\":false},{\"title\":\"api\",\"priority\":100,\"deadline\":\"2018-03-15 16:55:07 UTC\",\"updated\":false}]"
```

### Nested

```crystal
class TimeRenderer < Crinder::Base(Time?)
  field year : Int
  field month : Int
  field day : Int
  field hour : Int
  field minute : Int
  field second : Int
end

class NestedTodoRenderer < TodoRenderer
  remove expires_at
  remove updated
  field created_at, with: TimeRenderer
end

todo = Todo.new("wtf", 3, time + 20.hours, time, nil)

NestedTodoRenderer.render(todo) # => "{\"title\":\"wtf\",\"priority\":30,\"created_at\":{\"year\":2018,\"month\":3,\"day\":14,\"hour\":19,\"minute\":55,\"second\":7}}"
```

### Nilable

```crystal
class NilableTodoRenderer < TodoRenderer
  field expires_at : String?
  field created_at : String?
  field updated_at : String?
  remove updated
end

todo = Todo.new("IDK", 10, nil, nil, nil)

NilableTodoRenderer.render(todo) # => "{\"title\":\"IDK\",\"priority\":100,\"expires_at\":null,\"created_at\":null,\"updated_at\":null}"
```

## Contributing

1. Fork it ( https://github.com/c910335/crinder/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [c910335](https://github.com/c910335) Tatsiujin Chin - creator, maintainer
