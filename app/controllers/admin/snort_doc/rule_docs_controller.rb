class Admin::SnortDoc::RuleDocsController < ApplicationController
  load_and_authorize_resource class: 'Admin'

  layout 'admin/snort_doc/root'

  # GET /admin/snort_doc/RuleDocs
  # Page with form to set snort_doc_status on the rules records
  # Form calls api
  def index
    @rules = Rule.where.not(snort_doc_status: Rule::SNORT_DOC_STATUS_BEEN_PUB)
                 .where(edit_status: [Rule::EDIT_STATUS_EDIT, Rule::EDIT_STATUS_SYNCHED])
                 .order(:gid, :sid)
  end

  def upload

  end

  def doc_output
    output_file = File.file?("tmp/output.json") ? File.read("tmp/output.json") : "No output file exists"
    respond_to do |format|
      format.html {render :plain => "#{output_file}"}
      format.json { head json: JSON.pretty_generate(output_file)}
    end

  end

  def send_yaml
    file_contents = yaml_file.tempfile.read
    SnortDocPublisher.publish_snort_doc_from_yaml(file_contents,
                                                  do_download: send_yaml_params['do_download'],
                                                  update_cves: send_yaml_params['update_cves'],
                                                  set_published: send_yaml_params['set_published'],
                                                  do_upload: send_yaml_params['do_upload']) do |the_json, the_errors, the_result |
      @json = JSON.pretty_generate(the_json).to_s
      parsed_output = JSON.parse(the_result) unless the_result.empty?
      respond_to do |format|
        format.html {
          if the_errors.nil?
            if parsed_output
              flash[:notice]= "The following rule docs were successfully uploaded."
              @result = parsed_output['rule_docs'].join(", ")
            else
              flash[:notice]= "The script was successful but no rules were uploaded."
            end
          else
            flash[:error]= "Rule documents were NOT uploaded because of ->  #{the_errors}"
            @errors = the_errors
          end

          render 'admin/snort_doc/rule_docs/upload'
        }
        format.json { head json: JSON.pretty_generate(the_json)}
      end
    end
  end


  def yaml_file
    params.require('rule_update').require(:yaml_file)
  end

  private

  def send_yaml_params
    params.permit(:do_download, :update_cves, :set_published, :do_upload)
  end
end
