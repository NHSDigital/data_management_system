class PopulateLawfulBases < ActiveRecord::Migration[5.2]
  include MigrationHelper

  class LawfulBasis < ApplicationRecord
    attribute :value, :string
  end

  def change
    add_lookup LawfulBasis, '6.1a', value: 'Art. 6.1(a) the data subject has given consent to the processing of his or her personal data for one or more specific purposes.'
    add_lookup LawfulBasis, '6.1b', value: 'Art. 6.1(b) processing is necessary for the performance of a contract to which the data subject is party or in order to take steps at the request of the data subject prior to entering into a contract'
    add_lookup LawfulBasis, '6.1c', value: 'Art. 6.1(c) processing is necessary for compliance with a legal obligation to which the controller is subject'
    add_lookup LawfulBasis, '6.1d', value: 'Art. 6.1(d) processing is necessary in order to protect the vital interests of the data subject or of another natural person'
    add_lookup LawfulBasis, '6.1e', value: 'Art. 6.1(e) processing is necessary for the performance of a task carried out in the public interest or in the exercise of official authority vested in the controller'
    add_lookup LawfulBasis, '6.1f', value: 'Art. 6.1(f) processing is necessary for the purposes of the legitimate interests pursued by the controller or by a third party'
    add_lookup LawfulBasis, '9.2a', value: 'Art. 9.2(a) The data subject has given explicit consent.'
    add_lookup LawfulBasis, '9.2b', value: 'Art. 9.2(b) The processing is necessary in the context of employment law, or laws relating to social security and social protection.'
    add_lookup LawfulBasis, '9.2c', value: 'Art. 9.2(c) The processing is necessary to protect vital interests of the data subject (or another person) here the data subject is ncapable of giving consent.'
    add_lookup LawfulBasis, '9.2d', value: 'Art. 9.2(d) The processing is carried out in the course of the legitimate activities of a charity or not-for-profit body, with respect to its own members, former members, or persons with whom it has regular contact in connection with its purposes'
    add_lookup LawfulBasis, '9.2e', value: 'Art. 9.2(e) The processing relates to personal data which have been manifestly made public by the data subject.'
    add_lookup LawfulBasis, '9.2f', value: 'Art. 9.2(f) The processing is necessary for the establishment, exercise or defence of legal claims, or for courts acting in their judicial capacity.'
    add_lookup LawfulBasis, '9.2h', value: 'Art. 9.2(h) The processing is required for the purpose of medical treatment undertaken by health professionals, including assessing the working capacity of employees and the management of health or social care systems and services.'
    add_lookup LawfulBasis, '9.2i', value: 'Art. 9.2(i) The processing is necessary for reasons of public interest in the area of public health (e.g., ensuring the safety of medicinal products).'
    add_lookup LawfulBasis, '9.2j', value: 'Art. 9.2(j) The processing is necessary for archiving purposes in the public interest, for historical, scientific, research or statistical purposes, subject to appropriate safeguards.'
  end
end
