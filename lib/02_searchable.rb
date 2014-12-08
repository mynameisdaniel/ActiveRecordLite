require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.keys.map do |key| "#{key} = ?" end
    where_line = where_line.join(" AND ")
    
    values = params.values
    query = <<-SQL
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      #{where_line} 
    SQL
    results = DBConnection.execute(query, *values)
    parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
