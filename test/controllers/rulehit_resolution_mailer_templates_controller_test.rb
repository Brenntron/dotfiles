require 'test_helper'

class RulehitResolutionMailerTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @rulehit_resolution_mailer_template = rulehit_resolution_mailer_templates(:one)
  end

  test "should get index" do
    get rulehit_resolution_mailer_templates_url
    assert_response :success
  end

  test "should get new" do
    get new_rulehit_resolution_mailer_template_url
    assert_response :success
  end

  test "should create rulehit_resolution_mailer_template" do
    assert_difference('RulehitResolutionMailerTemplate.count') do
      post rulehit_resolution_mailer_templates_url, params: { rulehit_resolution_mailer_template: { body: @rulehit_resolution_mailer_template.body, cc: @rulehit_resolution_mailer_template.cc, mnemonic: @rulehit_resolution_mailer_template.mnemonic, subject: @rulehit_resolution_mailer_template.subject, to: @rulehit_resolution_mailer_template.to } }
    end

    assert_redirected_to rulehit_resolution_mailer_template_url(RulehitResolutionMailerTemplate.last)
  end

  test "should show rulehit_resolution_mailer_template" do
    get rulehit_resolution_mailer_template_url(@rulehit_resolution_mailer_template)
    assert_response :success
  end

  test "should get edit" do
    get edit_rulehit_resolution_mailer_template_url(@rulehit_resolution_mailer_template)
    assert_response :success
  end

  test "should update rulehit_resolution_mailer_template" do
    patch rulehit_resolution_mailer_template_url(@rulehit_resolution_mailer_template), params: { rulehit_resolution_mailer_template: { body: @rulehit_resolution_mailer_template.body, cc: @rulehit_resolution_mailer_template.cc, mnemonic: @rulehit_resolution_mailer_template.mnemonic, subject: @rulehit_resolution_mailer_template.subject, to: @rulehit_resolution_mailer_template.to } }
    assert_redirected_to rulehit_resolution_mailer_template_url(@rulehit_resolution_mailer_template)
  end

  test "should destroy rulehit_resolution_mailer_template" do
    assert_difference('RulehitResolutionMailerTemplate.count', -1) do
      delete rulehit_resolution_mailer_template_url(@rulehit_resolution_mailer_template)
    end

    assert_redirected_to rulehit_resolution_mailer_templates_url
  end
end
