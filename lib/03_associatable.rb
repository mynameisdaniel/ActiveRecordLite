require_relative '02_searchable'
require 'active_support/inflector'


# Phase IIIa
class AssocOptions
  
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.to_s.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  
  def initialize(name, options = {})
    @foreign_key = name.foreign_key.to_sym
    @class_name = name.singularize.camelize
    @primary_key = :id
    
    options.each do |attribute, value|
      self.send("#{attribute}=", value)
    end
  end
end

class HasManyOptions < AssocOptions
  
  def initialize(name, self_class_name, options = {})
    @foreign_key = self_class_name.foreign_key.to_sym
    @class_name = name.singularize.camelize
    @primary_key = :id
    
    options.each do |attribute, value|
      self.send("#{attribute}=", value)
    end
  end
end

module Associatable
  # Phase IIIb
  #going to be a class method, extend this module
  
  def belongs_to(name, options = {})
    # p "name is #{name}"
    # p "options are #{options}"

    
    define_method "#{name}" do
      options = BelongsToOptions.new("#{name}", options)
      # p "I am here"
      # p options.class_name
      # p options.foreign_key
      # p options.primary_key
      
      
      query = <<-SQL
      SELECT
        #{options.model_class.table_name}.*
      FROM
        #{self.class.table_name}
      JOIN
        #{options.model_class.table_name}
      ON
        #{options.model_class.table_name}.#{options.primary_key} = #{self.class.table_name}.#{options.foreign_key}
      WHERE
        #{self.class.table_name}.#{options.foreign_key} = #{self.class.table_name}.#{options.foreign_key}
      SQL
      results = DBConnection.execute(query)
      options.model_class.parse_all(results).first
    end
  end


  def has_many(name, options = {})
    p "name is #{name}"
    p "options are #{options}"

    
    define_method "#{name}" do
      options = HasManyOptions.new("#{name}", self.class.to_s, options)
      p "I am here"
      p options.class_name
      p options.foreign_key
      p options.primary_key
      
      
      query = <<-SQL
      SELECT
        Cats.*
      FROM
        Humans
      JOIN
        Cats
      ON
        Humans.id = Cats.owner_id
      WHERE
        Cats.owner_id = self.id
      SQL
      results = DBConnection.execute(query)
      options.model_class.parse_all(results)
    end
  end
  
end

class SQLObject
  extend Associatable
end
