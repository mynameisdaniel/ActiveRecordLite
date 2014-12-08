require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    results = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
      #{self.table_name}
    SQL
    results[0].map { |column| column.intern}
  end

  def self.finalize!
    self.columns.each do |column|
      define_method "#{column}"  do 
        self.attributes[column]
      end
      define_method "#{column}=" do |arg|
        self.attributes[column] = arg
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      SQL
      parse_all(results)
  end

  def self.parse_all(results)
    all_objects = Array.new
    results.each { |instance| all_objects << self.new(instance) }
    all_objects
  end

  def self.find(id)
    # self.all.find { |obj| obj.id == id }
    query = <<-SQL
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      #{self.table_name}.id = ?
    LIMIT
      1    
    SQL
    results = DBConnection.execute(query, id)
    parse_all(results).first
  end

  def initialize(params = {})
    class_columns = self.class.columns
    params.each do |key, value|
      key = key.intern
      if class_columns.include?(key)
         self.send("#{key}=", value)
      else
         raise Exception, "unknown attribute '#{key}'"
      end
     end
  end

  def attributes
    if instance_variable_get("@attributes").nil?
      instance_variable_set("@attributes", Hash.new)
    else
      instance_variable_get("@attributes")
    end
  end

  def attribute_values
    self.class.columns.map { |key| self.send("#{key}") }
  end

  def insert
    col_names = self.class.columns.join(", ")
    q_count = self.class.columns.count  
    question_marks = (["?"] * q_count).join (", ")  
    query = <<-SQL
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL
    results = DBConnection.execute(query, *attribute_values)
    id = DBConnection.last_insert_row_id
    self.id = id
  end

  def update
    col_names = self.class.columns.map { |key| "#{key} = ?"}.join(", ")
    query = <<-SQL
    UPDATE
      #{self.class.table_name}
    SET
      #{col_names}
    WHERE
      id = ?
    SQL
    results = DBConnection.execute(query, *attribute_values, self.id)
  end

  def save
    self.insert if self.id.nil?
    self.update if self.id
  end

end
