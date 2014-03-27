module Factories
  class << self
    Dir.entries("#{File.dirname(__FILE__)}/payload").each do |file_name|
      next if file_name == '.' or file_name == '..'
      name, ext = file_name.split(".", 2)

      define_method("#{name}_payload") do
        JSON.parse(IO.read("#{File.dirname(__FILE__)}/payload/#{name}.json")).with_indifferent_access
      end
    end
  end
end
