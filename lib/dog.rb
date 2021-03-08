require 'pry'

class Dog

    # ATTRIBUTES = {
    #     :id => "INTEGER PRIMARY KEY",
    #     :name => "TEXT",
    #     :breed => "TEXT"
    # } 
    #The section above would allow us to only have to add in each new
    # attribute once and would update all methods within our Class
    # this would be use if we are creating our own data as opposed to an 
    # outside source which is what the following attributes.each method is
    # doing below. 

    attr_accessor :id, :name, :breed

    # the following method dynamically adds getters and setters to the initialize method
    def initialize(id=nil, attributes)
        @id = id
        attributes.each {|key, value| 
          self.class.attr_accessor(key)
          self.send(("#{key}="), value)}
    end

    # .table_name changes the class name to downcase string and pluralizes it
    # allowing us to pass in the table name using abstraction
    def self.table_name
        "#{self.to_s.downcase}s"
    end

    def self.find_by_id(id)
        sql = <<-SQL
            SELECT * FROM #{self.table_name}
            WHERE id = ?
        SQL

        rows = DB[:conn].execute(sql, id)
        self.reify_from_row(rows.first)
    end

    # .reify_from_row takes the nested array and returns a normal array object
    # When using ATTRIBUTES:
    # add under .tap 
    # ATTRIBUTES.keys.each.with_index {|attribute_name, index| dog.send(#{attribute_name}=", row[index]")}
    def self.reify_from_row(row)
        self.new.tap do |dog|
            dog.id = row[0]
            dog.name = row[1]
            dog.breed = row[2]
        end
    end

    def self.create_table
        sql = <<-SQL
        CREATE TABLE IF NOT EXISTS #{self.table_name} (
            id INTEGER PRIMARY KEY,
            name TEXT,
            breed TEXT
        )
        SQL
        DB[:conn].execute(sql)
    end

    def self.drop_table
        sql = <<-SQL
            DROP TABLE #{self.table_name}
            SQL
            DB[:conn].execute(sql)
    end

    # #save method uses .table_name but becuase #save is an instance method
    # we need to specify self.class.table_name becuase 'self' inside of
    # save is referring to the instance as opposed to the Class
    #https://youtu.be/hts7TjpPw-8?t=1458 for save method using persisted?
    def save
        if  self.id
            self.update
          else
            self.insert
            self
        end
    end 


    def self.create(attributes)
        sql = <<-SQL
                INSERT INTO #{self.table_name} (name, breed) VALUES (?,?) 
            SQL
        new_dog = DB[:conn].execute(sql, attributes[:name], attributes[:breed])
        new_dog
    end
    # ATTRIBUTE names for INSERT: https://youtu.be/hts7TjpPw-8?t=2245
    #   def self.attribute_names_for_insert
    #       ATTRIBUTES.keys[1..-1].join(",") => "name, breed"
    #   end
    #   def self.question_marks_for_insert
    #       (ATTRIBUTES.keys.size-1).times.collect{"?"}.join(",")
    #   end
    # Line in SQL --> INSERT INTO #{self.class.table_name} (#{self.class.attribute_names_for_insert}) VALUES (#{self.question_marks_for_insert})
    def insert 
        sql = <<-SQL
                INSERT INTO #{self.class.table_name} (name, breed) VALUES (?,?) 
            SQL
            DB[:conn].execute(sql, self.name, self.breed)
            @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
    end

    def update
        sql = <<-SQL
            UPDATE #{self.table_name} SET name = ?, breed = ? WHERE id = ?
            SQL

        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end 
    
end
# binding.pry
# 0