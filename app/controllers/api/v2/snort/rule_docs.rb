require 'snort_doc_publisher'

class API::V2::Snort::RuleDocs < Grape::API
  include API::V2::Defaults
  # include API::BugzillaLogin

  default_format :json
  format :json

  resource 'snort/rule_docs' do

    desc 'Provides system documentation'
    content_type :txt, 'text/plain'
    format :txt
    get "doc", root: 'snort/rule_docs' do
      std_api_v2 do
        API::V2::Snort::RuleDocs.documentation_string
      end
    end

    desc 'Get the snort rule doc JSON which results from the rule update YAML'
    params do
      requires :rule_update, type: File, desc: 'API to post a rule update file from the group publishing snort rules.'
      optional :do_download, type: Boolean, default: 'true', desc: 'True to download updates from NIST NVD'
      optional :update_cves, type: Boolean, default: 'true', desc: 'True to update cves'
      optional :set_published, type: Boolean, default: 'true', desc: 'True to mark rules as has been published'
    end
    get "", root: :rule_docs do
      std_api_v2 do
        file_contents = permitted_params['rule_update'].tempfile.read
        SnortDocPublisher.publish_snort_doc_from_yaml(file_contents,
                                                      do_download: permitted_params['do_download'],
                                                      update_cves: permitted_params['update_cves'],
                                                      set_published: permitted_params['set_published'],
                                                      do_upload: false)
      end
    end

    desc 'Get the snort rule doc JSON which results from the rule update YAML'
    params do
      requires :rule_update, type: File, desc: 'API to post a rule update file from the group publishing snort rules.'
      optional :do_download, type: Boolean, default: 'true', desc: 'True to download updates from NIST NVD'
      optional :update_cves, type: Boolean, default: 'true', desc: 'True to update cves'
      optional :set_published, type: Boolean, default: 'true', desc: 'True to mark rules as has been published'
    end
    content_type :txt, 'application/json'
    format :txt
    get "pretty", root: :rule_docs do
      std_api_v2 do
        file_contents = permitted_params['rule_update'].tempfile.read
        output_struct =
            SnortDocPublisher.publish_snort_doc_from_yaml(file_contents,
                                                          do_download: permitted_params['do_download'],
                                                          update_cves: permitted_params['update_cves'],
                                                          set_published: permitted_params['set_published'],
                                                          do_upload: false)
        JSON.pretty_generate(output_struct)
      end
    end

    params do
      requires :rule_update, type: File, desc: 'API to post a rule update file from the group publishing snort rules.'
      optional :do_download, type: Boolean, default: 'true', desc: 'True to download updates from NIST NVD'
      optional :set_published, type: Boolean, default: 'true', desc: 'True to mark rules as has been published'
    end
    post "", root: :rule_docs do
      std_api_v2 do
        file_contents = permitted_params['rule_update'].tempfile.read
        Thread.new do
          permitted_params['rule_update'].tempfile.close

          output_struct =
              SnortDocPublisher.publish_snort_doc_from_yaml(file_contents,
                                                            do_download: permitted_params['do_download'],
                                                            update_cves: permitted_params['update_cves'],
                                                            set_published: permitted_params['set_published'])
          File.open('tmp/output.json', 'w') do |file|
            file.write(output_struct.to_json)
          end
        end
        'publish scheduled. tmp/output.json for details'
      end
    end

  end


  def self.documentation_string
    %Q~= Snort Rule Doc System API =

== Description ==
This system updates snort.org with rule doc generated from analyst console.

The intention is that when the snort rules are published, this API will be called, and kick off
the process to upload rule docs to snort.org.

When the process is kicked off, first any needed files from the NIST NVD are downloaded.
Then the CVE data is updated in analyst-console for any cve references on rules.

Then the rule update file, taken as input, is read, and all rules indicated as updated in that file
are used to build the documentation set.  The documentation is formatted in JSON and uploaded to snort.org.


== API ==
=== Doc ===

    curl --header "Api-Key: AaZz09+/" https://analyst-console.vrt.sourcefile.com/api/v2/snort/rule_docs/doc

Returns this documentation.

=== Test ===

    curl -X GET --form "rule_update=@Rule_Update.yml" --form "do_download=false" --form "set_published=false" --header "Api-Key: AaZz09+/" https://analyst-console.vrt.sourcefile.com/api/v2/snort/rule_docs/pretty

Supply the rule update file, Rule_Update.yml, using the API Key 'AaZz09+/'.

The '-X GET' switch uses GET instead of POST,
which will respond with the JSON and not upload it to snort.org.
This functionality is provided to manually upload to snort.org.
Also, the /pretty part of the URI formats the JSON in readable format,
which is a feature not provided by the POST API.
Using these two switches makes the call safe for testing.

The do_download=false in the form disables the download from the NIST NVD.
Do not abuse NIST by making repeated downloads for testing.

The set_published=false in the form disables the process
which sets a been-published flag in the analyst-console database.
You should not let the API set records to been-published unless you are publishing to snort.org.

See Production section for remaining details.

=== Production ===

    curl --form "rule_update=@Rule_Update.yml" --header "Api-Key: AaZz09+/" https://analyst-console.vrt.sourcefile.com/api/v2/snort/rule_docs

The rule update file is provided in the form.
An API Key is provided in the header.


~
  end

end
