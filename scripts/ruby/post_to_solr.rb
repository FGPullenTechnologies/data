#! /usr/local/rvm/rubies/ruby-2.1.3/bin/ruby

#################
# Post to Solr  #
#################

require 'logger'                       # logging functionality
require_relative 'lib/helpers.rb'      # helper functions
require_relative 'lib/parser.rb'       # parses script flags
require_relative 'lib/transformer.rb'  # transforms tei/csv to solr/html
require_relative 'lib/solr_poster.rb'  # posts a string (file) to solr

# variables
this_dir = File.dirname(__FILE__)  # directory containing this script
errors = {}                        # keeper of everything that has gone wrong
errors[:failed_files] = []         # array of strings with file names that did not post
errors[:solr_errors] = []          # array of errors from solr to display at the end

options = post_to_solr_params
project = options[:project]
verbose_flag = options[:verbose] == true  # set verbose flag
env = options[:environment]

config = read_configs(this_dir, project, verbose_flag)
dir = config[:main]["repo_directory"]
log = Logger.new("#{dir}/logs/post_to_solr.log", config[:main]["log_old_number"], config[:main]["log_size"])
log.info("Starting script at #{Time.now}")
log.info("Script running with following options: #{options}")
# clear out anything in the tmp directory before doing anything else
clear_tmp_directory(dir, verbose_flag)

# create a new solr instance that will be used by the transformer
url = "#{config[:main][env]["solr_path"]}#{config[:proj]["solr_core"]}/update"
solr = SolrPoster.new(url, options[:commit])
# make a new transformer and run it (pass it an instance of solr)
transformer = Transformer.new(dir, project, config[:main]["xsl_scripts"], solr, options[:transform_only], options[:solr_or_html], verbose_flag)
transform_errors = transformer.transform(options[:format], options[:regex], options[:update_time])

# write the saxon errors to a log
if transform_errors.empty?
  log.info("Transformed all specified files for #{project} successfully")
else
  log.error("Failed to transform following files for #{project}: #{transform_errors.join("\n ")}")
end

# write the solr errors to a log
solr_errors = transformer.solr_errors.compact
solr_failed = transformer.solr_failed_files
if solr_errors.empty? && solr_failed.empty?
  log.info("Posted all specified files for #{project} successfully")
else
  log.error("Failed to post the following files for #{project}: #{solr_failed.join("\n ")}")
end

# commit your changes to solr unless if otherwise specified
if options[:commit]
  commit_res = solr.commit_solr
  if !commit_res.nil? && !commit_res.body.nil? && commit_res.code != "200"
    errors[:solr_errors] << commit_res.body
    log.error("Failed to commit changes to solr: #{errors[:solr_errors]}")
  end
end

clear_tmp_directory(dir, verbose_flag)

log.info("Script finished running at #{Time.now}")
log.close

