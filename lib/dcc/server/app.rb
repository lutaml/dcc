# frozen_string_literal: true

begin
  require "sinatra/base"
  SINATRA_AVAILABLE = true
rescue ::LoadError
  SINATRA_AVAILABLE = false
end

module Dcc
  module Server
    class App < ::Sinatra::Base
      set :public_folder, File.expand_path("server", __dir__)

      get "/" do
        content_type :html
        File.read(File.expand_path("app.html", __dir__))
      end

      get "/demo.xml" do
        content_type :xml
        File.read(File.expand_path("demo_cert.xml", __dir__))
      end

      post "/validate" do
        ensure_loaded!
        xml = request.body.read
        content_type :json

        cert_data = extract_cert_data(xml)
        validation = run_validation(xml)

        { cert: cert_data, validation: validation }.to_json
      rescue => e
        content_type :json
        status 500
        { error: e.message }.to_json
      end

      private

      def ensure_loaded!
        return if @loaded

        ::Dcc.load_all!
        @loaded = true
      end

      def extract_cert_data(xml)
        hash = ::Dcc::Convert::Json.xml_to_hash(xml)
        admin = hash["administrativeData"] || {}
        core = admin["coreData"] || {}
        items = admin["items"] || {}
        item = items["item"].is_a?(::Array) ? items["item"].first : items["item"]
        item ||= {}
        lab = admin["calibrationLaboratory"] || {}
        lab_contact = lab["contact"] || {}

        {
          schemaVersion: hash["schemaVersion"],
          uniqueId: core["uniqueIdentifier"],
          country: core["countryCodeISO3166_1"],
          itemName: text(item["name"]),
          labName: text(lab_contact["name"]),
          coreData: build_core_data(core),
          lab: {
            name: text(lab_contact["name"]),
            email: lab_contact["eMail"],
            address: build_address(lab_contact["location"]),
          },
          signers: build_signers(admin["respPersons"]),
          measurements: build_measurements(hash["measurementResults"]),
        }
      end

      def text(node)
        return "" unless node
        c = node.is_a?(::Hash) ? node["content"] : node
        return "" unless c

        case c
        when ::String then c
        when ::Array
          entry = c.find { |e| e.is_a?(::Hash) }
          entry ? (entry["_text"] || "") : ""
        when ::Hash then c["_text"] || ""
        else ""
        end
      end

      def build_core_data(core)
        fields = []
        if core["uniqueIdentifier"]
          fields << { label: "Unique ID", value: core["uniqueIdentifier"] }
        end
        if core["beginPerformanceDate"]
          fields << { label: "Begin Date", value: core["beginPerformanceDate"] }
        end
        if core["endPerformanceDate"]
          fields << { label: "End Date", value: core["endPerformanceDate"] }
        end
        langs = core["usedLangCodeISO639_1"]
        langs_str = case langs
                    when ::Array then langs.join(", ")
                    when ::String then langs
                    else ""
                    end
        fields << { label: "Languages", value: langs_str } unless langs_str.empty?
        fields
      end

      def build_address(loc)
        return "" unless loc
        parts = []
        parts << "#{loc['street']} #{loc['streetNo']}" if loc["street"]
        parts << "#{loc['postCode']} #{loc['city']}" if loc["postCode"]
        parts << loc["countryCode"] if loc["countryCode"]
        parts.join(", ")
      end

      def build_signers(resp_persons)
        return [] unless resp_persons
        rp = resp_persons["respPerson"]
        list = rp.is_a?(::Array) ? rp : [rp]
        list.map do |p|
          person = p["person"] || {}
          {
            name: text(person["name"]),
            email: person["eMail"],
            main: p["mainSigner"] == "true",
          }
        end
      end

      def build_measurements(mr_hash)
        return [] unless mr_hash
        mr = mr_hash["measurementResult"]
        list = mr.is_a?(::Array) ? mr : [mr]
        list.map do |m|
          results = []
          if m["results"]
            r = m["results"]["result"]
            r_list = r.is_a?(::Array) ? r : [r]
            r_list.each do |res|
              results << {
                name: text(res["name"]),
                values: extract_quantity_values(res["data"]),
              }
            end
          end
          {
            name: text(m["name"]),
            results: results,
          }
        end
      end

      def extract_quantity_values(data)
        return [] unless data
        values = []
        d = data.is_a?(::Array) ? data.first : data
        return values unless d.is_a?(::Hash)

        qty = d["quantity"]
        q_list = qty.is_a?(::Array) ? qty : [qty]
        q_list.each do |q|
          next unless q.is_a?(::Hash)

          real = q["real"]
          next unless real

          values << {
            value: real["value"],
            unit: real["unit"],
            uncertainty: extract_uncertainty(real),
          }
        end
        values
      end

      def extract_uncertainty(real)
        mu = real["expandedMU"] || real["expandedUnc"]
        return nil unless mu

        mu["valueExpandedMU"] || mu["uncertainty"]
      end

      def run_validation(xml)
        xsd_result = ::Dcc::Validate::Xsd.call(xml)
        issues = xsd_result.issues || []
        {
          ok: issues.none? { |i| i.severity == :error },
          errors: issues.select { |i| i.severity == :error }.map { |i|
            { line: i.line, message: i.message }
          },
          warnings: issues.select { |i| i.severity == :warning }.map { |i|
            { line: i.line, message: i.message }
          },
        }
      rescue => e
        {
          ok: false,
          errors: [{ line: nil, message: e.message }],
          warnings: [],
        }
      end
    end
  end
end
