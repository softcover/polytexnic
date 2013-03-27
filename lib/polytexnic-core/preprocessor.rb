# encoding=utf-8
module Polytexnic
  module Preprocessor

    def preprocess
      to_xml
    end

    def to_xml
      tralics = `which tralics`.strip
      file = Tempfile.new(['polytex', '.tex'])
      file.write preprocess_polytex
      file.close
      system("#{tralics} -nomathml #{file.path} > /dev/null")
      dirname = File.dirname(file.path)
      xml_filename = File.basename(file.path, '.tex') + '.xml'
      raw_xml = fix_nokogiri_bug(File.read(File.join(dirname, xml_filename)))
      xml = Nokogiri::XML(raw_xml).at_css('p').to_xml

      @xml = xml
    ensure
      file.unlink
    end

    def digest(string)
      Digest::SHA1.hexdigest(string)
    end

    def preprocess_polytex
      polytex = @polytex
      output = []
      lines = polytex.split("\n")
      while (line = lines.shift)
        if line.begin_verbatim?
          output << xmlelement(:verbatim) do
            verbatim_count = 1
            verbatim_text = []
            while (line = lines.shift)
              if line.begin_verbatim?
                verbatim_count += 1
              elsif line.end_verbatim?
                verbatim_count -= 1
                break if verbatim_count == 0
              end
              verbatim_text << line if verbatim_count > 0
            end
            raise 'Missing \end{verbatim}' if verbatim_count != 0
            content = verbatim_text.join("\n")
            key = self.digest(content)
            verbatim_cache[key] = content
            key
          end
        else
          output << line
        end
      end
      # puts output.join("\n")
      output.join("\n")
    end

    def xmlelement(name)
      output = "\\begin{xmlelement}{#{name}}"
      output << yield if block_given?
      output << "\\end{xmlelement}"
    end

    # Fixes a Nokogiri bug.
    # As of this writing, the latest version of Nokogiri (1.5.6) doesn't
    # handle the horizontal ellipsis character '&#133;' correctly in Ruby 2.0.
    # The kludgy solution is to replace it with '…' in the raw XML, 
    # which does work.
    def fix_nokogiri_bug(raw_xml)
      raw_xml.gsub('&#133;', '…')
    end

  end
end

class String
  def begin_verbatim?
    match(/^\s*\\begin{#{verbatim}}\s*$/)
  end

  def end_verbatim?
    match(/^\s*\\end{#{verbatim}}\s*$/)    
  end

  private

    def verbatim
      'verbatim'
    end
end