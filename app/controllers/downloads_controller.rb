class DownloadsController < ApplicationController
  def data_access_agreement
    send_file("#{Rails.root}/public/downloads/data_access_agreement.docx",
              filename: 'data_access_agreement.docx')
  end

  def ons_declaration_of_use
    send_file("#{Rails.root}/public/downloads/ons_declaration_of_use.docx",
              filename: 'ons_declaration_of_use.docx')
  end

  def ons_short_declaration_list
    send_file("#{Rails.root}/public/downloads/ons_short_declaration_list.docx",
              filename: 'ons_short_declaration_list.docx')
  end

  def terms_and_conditions_doc
    send_file("#{Rails.root}/public/downloads/MBIS_Ts&Cs09018.docx",
              filename: 'MBIS_Ts&Cs09018.docx')
  end

  def project_end_users_template_csv
    send_file("#{Rails.root}/public/downloads/project_end_users_template.csv",
              filename: 'project_end_users_template.csv')
  end
end
