require "isodoc"

module IsoDoc
  module Csd
    # A {Converter} implementation that generates CSD output, and a document
    # schema encapsulation of the document for validation
    class Convert < IsoDoc::Convert
      def html_doc_path(file)
        File.join(File.dirname(__FILE__), File.join("html", file))
      end

      def initialize(options)
        super
        @htmlstylesheet = generate_css(html_doc_path("htmlstyle.scss"), true, default_fonts(options))
        @standardstylesheet = generate_css(html_doc_path("csd.scss"), true, default_fonts(options))
        @htmlcoverpage = html_doc_path("html_csd_titlepage.html")
        @htmlintropage = html_doc_path("html_csd_intro.html")
        @scripts = html_doc_path("scripts.html")
        set_metadata(:status, "XXX")
      end

      def default_fonts(options)
        b = options[:bodyfont] ||
          (options[:script] == "Hans" ? '"SimSun",serif' :
           '"Overpass",sans-serif')
        h = options[:headerfont] ||
          (options[:script] == "Hans" ? '"SimHei",sans-serif' :
           '"Overpass",sans-serif')
        m = options[:monospacefont] || '"Space Mono",monospace'
        "$bodyfont: #{b};\n$headerfont: #{h};\n$monospacefont: #{m};\n"
      end

      def init_metadata
        super
      end

      def title(isoxml, _out)
        main = isoxml&.at(ns("//title[@language='en']"))&.text
        set_metadata(:doctitle, main)
      end

      def subtitle(_isoxml, _out)
        nil
      end

      def author(isoxml, _out)
        set_metadata(:tc, "XXXX")
        tc = isoxml.at(ns("//editorialgroup/technical-committee"))
        set_metadata(:tc, tc.text) if tc
      end


      def docid(isoxml, _out)
        docnumber = isoxml.at(ns("//bibdata/docidentifier"))
        docstatus = isoxml.at(ns("//bibdata/status"))
        dn = docnumber&.text
        if docstatus
          set_metadata(:status, status_print(docstatus.text))
          abbr = status_abbr(docstatus.text)
          dn = "#{dn}(#{abbr})" unless abbr.empty?
        end
        set_metadata(:docnumber, dn)
      end

      def status_print(status)
        status.split(/-/).map{ |w| w.capitalize }.join(" ")
      end

      def status_abbr(status)
        case status
        when "working-draft" then "wd"
        when "committee-draft" then "cd"
        when "draft-standard" then "d"
        else
          ""
        end
      end

      def annex_name(annex, name, div)
        div.h1 **{ class: "Annex" } do |t|
          t << "#{get_anchors[annex['id']][:label]} "
          t << "<b>#{name.text}</b>"
        end
      end

      def annex_name_lbl(clause, num)
        obl = l10n("(#{@inform_annex_lbl})")
        obl = l10n("(#{@norm_annex_lbl})") if clause["obligation"] == "normative"
        l10n("<b>#{@annex_lbl} #{num}</b> #{obl}")
      end

      def pre_parse(node, out)
        out.pre node.text # content.gsub(/</, "&lt;").gsub(/>/, "&gt;")
      end

      def term_defs_boilerplate(div, source, term)
        if source.empty? && term.nil?
          div << @no_terms_boilerplate
        else
          div << term_defs_boilerplate_cont(source, term)
        end
      end

      def i18n_init(lang, script)
        super
        @annex_lbl = "Appendix"
      end

      def error_parse(node, out)
        # catch elements not defined in ISO
        case node.name
        when "pre" 
          pre_parse(node, out)
        when "keyword"
          out.span node.text, **{ class: "keyword" }
        else
          super
        end
      end

      def html_head()
        <<~HEAD.freeze
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>

    <!--TOC script import-->
    <script type="text/javascript"  src="https://cdn.rawgit.com/jgallen23/toc/0.3.2/dist/toc.min.js"></script>

    <!--Google fonts-->
    <link href="https://fonts.googleapis.com/css?family=Open+Sans:300,300i,400,400i,600,600i|Space+Mono:400,700" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css?family=Overpass:300,300i,600,900" rel="stylesheet">
    <!--Font awesome import for the link icon-->
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.0.8/css/solid.css" integrity="sha384-v2Tw72dyUXeU3y4aM2Y0tBJQkGfplr39mxZqlTBDUZAb9BGoC40+rdFCG0m10lXk" crossorigin="anonymous">
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.0.8/css/fontawesome.css" integrity="sha384-q3jl8XQu1OpdLgGFvNRnPdj5VIlCvgsDQTQB6owSOHWlAurxul7f+JpUOVdAiJ5P" crossorigin="anonymous">
        HEAD
      end

      def make_body(xml, docxml)
        body_attr = { lang: "EN-US", link: "blue", vlink: "#954F72", "xml:lang": "EN-US", class: "container" }
        xml.body **body_attr do |body|
          make_body1(body, docxml)
          make_body2(body, docxml)
          make_body3(body, docxml)
        end
      end

      def html_toc(docxml)
        docxml
      end
    end
  end
end

