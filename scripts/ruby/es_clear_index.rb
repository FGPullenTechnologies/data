require "json"
require "rest-client"
require_relative "lib/requirer.rb"

def confirm_basic(options, url)
  # verify that the user is really sure about the index they're about to wipe
  puts "Are you sure that you want to remove entries from"
  puts " #{options["es_type"]}'s #{options['environment']} environment?"
  puts "url: #{url}"
  puts "y/N"
  answer = STDIN.gets.chomp
  # boolean
  return !!(answer =~ /[yY]/)
end

def main
  this_dir = File.dirname(__FILE__)

  # run the parameters through the option parser
  params = Parser.clear_index_params
  options = Options.new(params, "#{this_dir}/../../config", "#{this_dir}/../../collections/#{params['collection']}/config").all
  if params["collection"] == "all"
    clear_all(options)
  else
    clear_index(options)
  end
end

def build_data(options)
  if options["regex"]
    field = options["field"] || "identifier"
    return {
      "query" => {
        "regexp" => { field => options["regex"] }
      }
    }
  else
    return {
      "query" => { "match_all" => {} }
    }
  end
end

def clear_all(options)
  puts "Please verify that you want to clear EVERY ENTRY from the ENTIRE INDEX"
  puts "Type: 'Yes I'm sure'"
  confirm = STDIN.gets.chomp
  if confirm == "Yes I'm sure"
    url = "#{options["es_path"]}/#{options["es_index"]}/_delete_by_query?pretty"
    post url, { "query" => { "match_all" => {} } }
  else
    puts "You typed '#{confirm}'. This is incorrect, exiting program"
    exit
  end
end

def clear_index(options)
  url = "#{options["es_path"]}/#{options["es_index"]}/#{options["es_type"]}/_delete_by_query?pretty"
  confirmation = confirm_basic(options, url)

  if confirmation
    data = build_data(options)
    post(url, data)
  else
    puts "come back anytime!"
    exit
  end
end

def post(url, data={})
  begin
    puts "clearing from #{url}: #{data.to_json}"
    res = RestClient.post(url, data.to_json, {:content_type => :json})
    puts res.body
  rescue => e
    puts "error posting to ES: #{e.response}"
  end
end

main
