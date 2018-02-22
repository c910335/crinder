require "./spec_helper"

record Todo, name : String, priority : Int32, expires_at : Time?, created_at : Time?, updated_at : Time?

class TodoRenderer < Crinder::Base(Todo)
  field name : String, as: title
  field priority : Int, value: ->{ object.priority * 10 }
  field expires_at : String, as: deadline, unless: ->{ object.priority < 3 }
  field created_at : String, if: ->{ object.priority > 5 }
  field updated : Bool, value: updated?

  def self.updated?
    !object.updated_at.nil?
  end
end

class AnotherTodoRenderer < TodoRenderer
  field expires_at : String, unless: ->{ object.priority < 1 }
  field created_at : String, if: ->{ object.priority > 8 }
  field updated_at : String
  remove updated
end

class YetAnotherTodoRenderer < AnotherTodoRenderer
  remove updated_at
end

describe Crinder::Base do
  describe ".render" do
    it "converts object to json" do
      time = Time.new(2018, 1, 29, 15, 23, 15)
      t = Todo.new("www", 8, time + 20.hours, time, nil)

      TodoRenderer.render(t).should eq(%({"title":"www","priority":80,"deadline":"2018-01-30 11:23:15","created_at":"2018-01-29 15:23:15","updated":false}))
    end

    it "converts multiple objects to json" do
      time = Time.new(2018, 1, 29, 15, 23, 15)
      t = Todo.new("www", 8, time + 20.hours, time, nil)
      t2 = Todo.new("api", 10, time + 21.hours, time, nil)

      TodoRenderer.render([t, t2]).should eq(%([{"title":"www","priority":80,"deadline":"2018-01-30 11:23:15","created_at":"2018-01-29 15:23:15","updated":false},{"title":"api","priority":100,"deadline":"2018-01-30 12:23:15","created_at":"2018-01-29 15:23:15","updated":false}]))
    end

    context "with inheritance" do
      it "converts object to json" do
        time = Time.new(2018, 1, 29, 17, 21, 34)
        t = Todo.new("QAQ", 3, time + 20.hours, time, time + 10.hours)

        AnotherTodoRenderer.render(t).should eq(%({"title":"QAQ","priority":30,"expires_at":"2018-01-30 13:21:34","updated_at":"2018-01-30 03:21:34"}))
      end
    end

    context "with multilevel inheritance" do
      it "converts object to json" do
        time = Time.new(2018, 1, 29, 18, 42, 37)
        t = Todo.new("Wow", 9, time + 20.hours, time, time + 10.hours)

        YetAnotherTodoRenderer.render(t).should eq(%({"title":"Wow","priority":90,"expires_at":"2018-01-30 14:42:37","created_at":"2018-01-29 18:42:37"}))
      end
    end
  end
end
