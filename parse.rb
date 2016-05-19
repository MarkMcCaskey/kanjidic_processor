require 'nokogiri'

# To be displayed in the info box
def format_paragraph(misc, rmgroup)
  reading_type     = Array["Pinyin", "Korean", "Onyomi", "Kunyomi"]
  xml_reading_type = Array["pinyin","korean_h","ja_on","ja_kun"]
  output_html      = "<li>" # better HTML formatting will be needed
  
  output_html << "Stroke count: " + misc.at_xpath('stroke_count').content + "<br>"
  
  # Nicely format and handle potential non-existence and duplicates
  # of readings in pinyin, hangul, Japanese onyomi and kunyomi
  for index in 0 ... reading_type.size
    readings = rmgroup.xpath("reading")
    if readings != nil
      reading_output = Array[]
      for reading in readings
        # this could probably be done earlier to avoid rechecking
        if reading.attributes["r_type"].value == xml_reading_type[index]
          reading_output.push( reading.content )
        end
      end
      
      # writing done here to avoid writing blank entries
      if reading_output.size > 0
        output_html << reading_type[index] + ": " + reading_output.join(", ") + "<br>"
      end
    end
  end

  # Nicely format and handle potential non-existence and duplicates
  # of meanings in English
  meanings = rmgroup.xpath("meaning")
  if meanings != nil
    meanings_output = Array[]
    for meaning in meanings
      if meaning.attributes["m_lang"].nil? # ignore French, Spanish, and Portugese for now
        meanings_output.push(meaning.content)
      end
    end
    
    # writing done here to avoid having "Meanings: " and no meanings
    if meanings_output.size > 0
      output_html << "Meanings: " + meanings_output.join(", ")
    end
  end
  
  
  output_html << "</li>"
  return output_html
end

def format_output(character_xml)
  if character_xml.nil?
    return ""
  end
  
  fields  = Array["title", "paragraph", "source"]
  results = Array[] # contains the values

  output_string   = "\t{"
  start_new_entry = "\n\t\t\""

  # values for title, paragraph, and source
  results.push("\"" + character_xml.at_xpath('literal').content + "\",")
  misc    = character_xml.at_xpath('misc')
  rmgroup = character_xml.at_xpath('//rmgroup')#at_xpath('reading_meaning').at_xpath('rmgroup')
  results.push("\"" + format_paragraph(misc, rmgroup) + "\",")
  results.push("\"kanji_strokeorder\"")

  # put it all together
  index = 0
  for name in fields
    output_string << start_new_entry + name + "\":" + results[index]
    index += 1
  end

  output_string << "\n\t}"
  return output_string
end

def main()
  if not File.exist?("download/kanjidic2.xml")
    abort("file download/kanjidic2.xml could not be found")
  end

  xml_doc  = File.open("download/kanjidic2.xml") { |f| Nokogiri::XML(f) }
  out_file = File.open('output.txt', 'w')
  out_file.puts "[\n"
  
  output = Array[]
  # write JSON output for each character
  xml_doc.xpath('//character').each do |character|
    output.push(format_output(character))
  end
  
  out_file.puts output.join(",\n")
  
  out_file.puts"]"
  out_file.close

end

main()
