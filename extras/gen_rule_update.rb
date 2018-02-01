#!rails runner
# Generates input YAML file for Rule Doc update to snort API call.
#
# The output of this script imitates the output YAML file of the Snort Rule publishing process.
# That output can be used as an input to the API call which generates the JSON needed to upload to snort.org.
# See app/controllers/api/v2/snort/rule_docs.rb for more details.
#
# Writes YAML to stdout.
# Modify this script for the specific rules you want to generate YAML for.


deleted_category = RuleCategory.where(category: 'DELETED').first


result_hash = {'modules' => {'diff' => {}}, 'rules' => {'diff' => {}}}


Rule.where('sid >= 100').where('sid < 250').each do |rule|
  next if rule.rule_category_id.nil?
  on_off =
      case
        when deleted_category.id == rule.rule_category_id
          'deleted'
        when rule.on?
          'on'
        else
          'off'
      end
  case rule.gid
    when 1
      result_hash['rules']['diff'][rule.sid] = {rule.rev => on_off}
    when 3
      result_hash['modules']['diff'][rule.sid] = {rule.rev => on_off}
  end
end


puts result_hash.to_yaml

