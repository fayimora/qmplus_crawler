require 'mongo'

collection = Mongo::Connection.new("localhost", 27017).db("logic_survey")["survey_results"]

result = ""
i = 1
collection.find.each do |doc|
  result += "<tr>\n"
  # result += "<td class=\"student\">#{doc['student']}</td>\n"
  # result += "<td class=\"student\">#{i}</td>\n"
  result += "<td >#{doc['responses'][0]}</td>\n\n"
  result += "<td>#{doc['responses'][1]}</td>\n\n"
  result += "<td>#{doc['responses'][2]}</td>\n\n"
  result += "<td>#{doc['responses'][3]}</td>\n\n"
  result += "</tr>"
  i += 1
end

File.open("table.html", "w") do |file|
  file.puts result
end

