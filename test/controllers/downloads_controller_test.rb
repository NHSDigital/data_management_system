require 'test_helper'

class DownloadsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:standard_user_one_team)
    sign_in(@user)
  end

  test 'should be able to download a data access agreement doc' do
    get data_access_agreement_path
    assert_response :success
    assert_attachment 'data_access_agreement.docx'
  end

  test 'should be able to download an ONS declaration of use doc' do
    get ons_declaration_of_use_path
    assert_response :success
    assert_attachment 'ons_declaration_of_use.docx'
  end

  test 'should be able to download an ONS short declaraion list doc' do
    get ons_short_declaration_list_path
    assert_response :success
    assert_attachment 'ons_short_declaration_list.docx'
  end

  test 'should be able to download terms and conditions doc' do
    get terms_and_conditions_doc_path
    assert_response :success
    assert_attachment 'MBIS_Ts%26Cs09018.docx'
  end

  test 'should be able to download project end users template' do
    get project_end_users_template_csv_path
    assert_response :success
    assert_attachment 'project_end_users_template.csv'
  end

  private

  def assert_attachment(filename)
    assert_match(/attachment; filename="#{filename}"/, response.header['Content-Disposition'])
  end
end
