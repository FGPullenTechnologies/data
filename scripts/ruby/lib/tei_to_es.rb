require "nokogiri"

# TODO would this whole thing be better as a class instead of a module?
# originally planning on mixing in generic module with project specific classes
# but this seems like it's actually working okay, but maybe it could be better???

module TeiToEs
  def self.json
    @json
  end

  def self.json= j
    @json = j
  end

  # getter for json response object
  def self.create_json xml, params={}
    @json = self.assemble_json xml, params
  end

  # getter and setter to modify xpaths object
  def self.xpaths
    @xpaths
  end

  def self.xpaths= x
    @xpaths = x
  end

  # These are the default xpaths that are used for projects
  #  if you require a different xpath, please override the xpath in
  #  the specific project's TeiToEs file or create a new method
  #  in that file which returns a different value
  @xpaths = {
    "title_main" => "/TEI/teiHeader/fileDesc/titleStmt/title[@type='main'][1]",
    "title_alt" => "/TEI/teiHeader/fileDesc/titleStmt/title[1]",
    "creators" => [
      "/TEI/teiHeader/fileDesc/titleStmt/author",
      "//persName[@type = 'author']"
    ],
    "publisher" => "/TEI/teiHeader/fileDesc/sourceDesc/bibl[1]/publisher[1]",
    "contributors" => "/TEI/teiHeader/revisionDesc/change/name",
    "date" => "/TEI/teiHeader/fileDesc/sourceDesc/bibl/date/@when",
    "formats" => [
      "/TEI/text/body/div1[@type='letter']",
      "/TEI/teiHeader/fileDesc/sourceDesc/bibl/title"
    ],
    "source" => "/TEI/teiHeader/fileDesc/sourceDesc/bibl[1]/title[@level='j']",
    "rightsholder" => "/TEI/teiHeader/fileDesc/sourceDesc/msDesc/msIdentifier/repository",
    "investigators" => "/TEI/teiHeader/fileDesc/titleStmt/principal",
    "recipients" => "/TEI/teiHeader/profileDesc/particDesc/person[@role='recipient']/persName",
    "category" => "/TEI/teiHeader/profileDesc/textClass/keywords[@n='category'][1]/term",
    "subcategory" => "/TEI/teiHeader/profileDesc/textClass/keywords[@n='subcategory'][1]/term",
    "topic" => "/TEI/teiHeader/profileDesc/textClass/keywords[@n='topic']/term",
    "keywords" => "/TEI/teiHeader/profileDesc/textClass/keywords[@n='keywords']/term",
    "people" => "/TEI/teiHeader/profileDesc/textClass/keywords[@n='people']/term",
    "places" => "/TEI/teiHeader/profileDesc/textClass/keywords[@n='places']/term",
    "works" => "/TEI/teiHeader/profileDesc/textClass/keywords[@n='works']/term",
    "text" => "//text",
  }

  # TODO a lot of stuff comes in from the specific params objects
  # but those will be very different for the new api schema
  # so I'm just waiting on that for now

  def self.assemble_json xml_file, params
    @xml = File.open(xml_file) { |f| Nokogiri::XML f }
    # TODO is this a good idea?
    @xml.remove_namespaces!
    @json = {}
    @json["_id"] = id
    @json["title"] = title
    @json["title_sort"] = title_sort
    @json["date"] = date
    return @json
  end

  ##########
  # FIELDS #
  ##########

  def self.id
    "filename"
  end

  def self.date
    @xml.xpath(@xpaths["date"]).text
  end

  def self.title
    title = @xml.xpath(@xpaths["title_main"]).text
    if !title
      title = @xml.xpath(@xpaths["title_alt"]).text
    end
    return title
  end

  def self.title_sort
    normalize_name @json["title"]
  end

  ###########
  # HELPERS #
  ###########

  # TODO should these go somewhere else or just stay in this file?
  def self.normalize_name abnormal
    # put in lower case
    # remove starting a, an, or the
    abnormal.downcase!
    abnormal.gsub!(/^the |^a |^an /, "")
    return abnormal
  end

  def self.squeeze string
    string.strip.gsub(/\s+/, " ")
  end
end