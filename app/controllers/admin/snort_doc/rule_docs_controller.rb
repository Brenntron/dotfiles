class Admin::SnortDoc::RuleDocsController < ApplicationController
  layout 'admin/snort_doc/root'

  # GET /admin/snort_doc/RuleDocs
  # Page with form to set snort_doc_status on the rules records
  # Form calls api
  def index
    @rules = Rule.where.not(snort_doc_status: Rule::SNORT_DOC_STATUS_BEEN_PUB)
                 .where(edit_status: [Rule::EDIT_STATUS_EDIT, Rule::EDIT_STATUS_SYNCHED])
                 .order(:gid, :sid)
  end
end
