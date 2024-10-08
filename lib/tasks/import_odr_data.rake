namespace :odr do
  task import_spreadsheet: %i[clean_existing_organisations update_organisations
                              create_new_organisations import_teams
                              import_applications import_amendments import_dpias import_releases]

  # Live seems to be in odd state for some orgs
  task clean_existing_organisations: :environment do
    genomics = Organisation.find_by(name: "'Genomics England '")
    genomics.update(name: 'Genomics England') unless genomics.nil?
    # dodgy characters on live
    ormond = Organisation.where("name like ?", 'Great Ormond Street Hospital%')
    ormond_name = 'Great Ormond Street Hospital for Children NHS Foundation Trust'
    ormond.update(name: ormond_name) unless ormond.nil?

    kcl_name = "King's College Hospital NHS Foundation Trust"
    kcl = Organisation.where("name ilike ?", "King's College Hospital%").first
    kcl.update(name: kcl_name) unless kcl.nil?

    merck_name = 'Merck & Co. inc'
    merck = Organisation.find_by(name: 'Merck Serono Ltd')
    merck.update(name: merck_name) unless merck.nil?

    bristol_name = 'North Bristol NHS Trust'
    bristol = Organisation.where("name like ?", 'North Bristol%').first
    bristol.update(name: bristol_name) unless bristol.nil?

    spire_name = 'Spire Healthcare system'
    spire = Organisation.where("name like ?", 'Spire Healthcare%').first
    spire.update(name: spire_name) unless spire.nil?
  end

  task update_organisations: :environment do
    update_orgs = OdrDataImporter::Base.new(ENV['application_fname'], 'Orgs - name update', ENV['test_mode'])
    update_orgs.update_organisation_names
  end

  task create_new_organisations: :environment do
    import_orgs =
      OdrDataImporter::Base.new(ENV['application_fname'], 'Orgs - New', ENV['test_mode'])
    import_orgs.import_organisations
  end

  task import_applications: :environment do
    import_applications = 
      OdrDataImporter::Base.new(ENV['application_fname'], 'Applications', ENV['test_mode'])
    import_applications.import_applications
  end

  task import_amendments: :environment do
    importer = OdrDataImporter::Base.new(ENV['amendments_fname'], nil, ENV['test_mode'])
    importer.import_amendments
  end

  task import_dpias: :environment do
    importer = OdrDataImporter::Base.new(ENV['dpias_fname'], nil, ENV['test_mode'])
    importer.import_application_sub_class(:create_dpia)
  end

  task import_contracts: :environment do
    importer = OdrDataImporter::Base.new(ENV['contracts_fname'], nil, ENV['test_mode'])
    importer.import_application_sub_class(:create_contract)
  end
  
  task import_releases: :environment do
    importer = OdrDataImporter::Base.new(ENV['releases_fname'], nil, ENV['test_mode'])
    importer.import_application_sub_class(:create_release)
  end

  # temp task to recreate live orgs in local env
  task existing_org_names: :environment do
    live_org_names.each { |n| Organisation.create!(name: n, organisation_type: Lookups::OrganisationType.first) }
    print "#{Organisation.count} organisations\n"
  end

  def live_org_names
    [
      "AES Group (CRUK)",
      "AT Medics",
      "Adelphi Group",
      "Advanced Accelerator Applications",
      "Airedale NHS Foundation Trust",
      "Alder Hey Children's NHS Foundation Trust",
      "Amaris Consulting",
      "American International University-Bangladesh",
      "Amgen Ltd",
      "Analytica Laser",
      "Anglia Ruskin University",
      "Anova Enterprises, LLC",
      "Aptusclinical",
      "Association of Surgeons in Training",
      "AstraZeneca UK Ltd",
      "Barnsley Council",
      "Barnsley Hospital NHS Foundation Trust",
      "Barts Health NHS Trust",
      "Basildon and Thurrock University Hospitals NHS Foundation Trust",
      "Baxter Healthcare Ltd",
      "Benazir Bhutto Shaheed University",
      "Birkbeck College",
      "Birmingham Women's and Children's NHS Foundation Trust",
      "Birmingham and Solihull Clinical Commissioning Group (formerly Birmingham CrossCity",
    "CCG)",
      "Blackpool Clinical Commissioning Group",
      "Blackpool Teaching Hospital",
      "Boehringer Ingelheim",
      "Bone Cancer Research Trust",
      "Boston Strategic Partners Inc.",
      "Bowel Cancer Screening Southern Programme Hub",
      "Bradford Districts CCG",
      "Brain Tumour Research",
      "Breast Cancer Now",
      "Breast Test Wales",
      "BresMed",
      "Brighton and Sussex Medical School (BSMS)",
      "Bristol-Myers Squibb Company",
      "British Skull Base Society",
      "Bromley Clinical Commissioning Group",
      "Brunel University London",
      "Buckinghamshire CCG (formerly Aylesbury Vale and Chiltern CCGs)",
      "Cambridge University Hospitals NHS Foundation Trust",
      "Cambridgeshire And Peterborough CCG",
      "Cambridgeshire County Council",
      "Cancer Commons",
      "Cancer Research UK",
      "CancerCare North Lancashire and South Cumbria",
      "Care Quality Commission (CQC)",
      "Castle Point & Rochford Clinical Commissioning Group",
      "Celltrion",
      "|-",
    "Central London CCG,",
    "West London CCG, Hammersmith & Fulham CCG,",
    "Hounslow CCG and Ealing CCG",
      "Centre for Workforce Intelligence",
      "CervicalCheck, National Screening Committee",
      "Check4Cancer Ltd.",
      "Children's Cancer and Leukaemia Group",
      "Chorley and South Ribble Clinical Commissioning Group",
      "Cignpost Group Ltd",
      "City, University of London",
      "Clatterbridge Cancer Centre",
      "Clinical Practice Research Datalink (CPRD)",
      "Clyz Labs Limited",
      "Coastal West Sussex Clinical Commissioning Group",
      "Cognizant Technology Solutions UK Ltd",
      "Columbia University",
      "Costello medical",
      "County Durham and Darlington NHS Foundation Trust",
      "Covance",
      "Creativ-Ceutical",
      "Croydon Council",
      "Cumbria County Council",
      "Cwm Taf Morgannwg University Health Board",
      "Cystic Fibrosis Trust",
      "Cytel Inc. Geneva Branch",
      "Dendrite Clinical Systems Ltd",
      "Department of Health and Social Care",
      "Derbyshire County Council",
      "Durham University",
      "ENT",
      "EUROPAC",
      "EVIDERA PPD",
      "East Kent Hospitals University NHS Foundation Trust",
      "East Midlands Academic Health Science Network",
      "East Riding of Yorkshire CCG",
      "East Suffolk and North Essex NHS Foundation Trust (formerly Colchester Hospital",
    "University NHS Foundation Trust and The Ipswich Hospital NHS Trust)",
      "East and North Hertfordhsire NHS Trust",
      "Edge Health",
      "Eli Lilly and Company",
      "Erasmus University Medical Center",
      "Ernst & Young Global Limited (EY)",
      "Eurocare Secretariat",
      "Evaluate Ltd",
      "Evidera",
      "Ferring Pharmaceuticals",
      "Fondazione IRCCS Istituto Nazionale dei Tumori",
      "Fraunhofer Mevis Inst",
      "GIST Cancer UK",
      "Gateshead Health NHS Foundation Trust",
      "Genetic Health Service NZ",
      "'Genomics England '",
      "German Cancer Research Center",
      "GlaxoSmithKline plc",
      "Gloucestershire Hospitals NHS Foundation Trust",
      "Great Ormond Street Hospital for Children NHS Foundation Trust",
      "Greater Manchester Combined Authority",
      "Guy's and St Thomas' NHS Foundation Trust",
      "HCA Healthcare UK",
      "Halton Borough Council",
      "Hampshire Hospitals NHS Foundation Trust",
      "Hannover Re UK Life Branch",
      "Harbin Institute of Technology",
      "Harvey Walsh",
      "Health and Social Care Trusts Northern Ireland (HSCNI)",
      "Health iQ Limited",
      "Healthcare Quality Improvement Partnership (HQIP)",
      "Heriot-Watt University",
      "Homeless Link",
      "Hull University Teaching Hospitals NHS Trust",
      "Hull York Medical School",
      "Hull and East Yorkshire Hospitals NHS Trust",
      "Huron Consulting Group",
      "ICON plc",
      "IQVIA (formerly IMS Health and Quintiles)",
      "Imperial College Health Partners",
      "Imperial College Healthcare NHS Trust",
      "Imperial College London",
      "Indian Institute of Management (IMM) Indore",
      "Information Services Division (ISD) Scotland",
      "Innov4Sight Health and Biomedical Systems Private Limited",
      "Institut Hospital del Mar d'Investigacions Mèdiques (IMIM)",
      "Integraal Kankercentrum Nederland (IKNL)",
      "International Agency for Research on Cancer (IARC)",
      "Intuitive Surgical Inc.",
      "Ipsos MORI",
      "Ipswich & East Suffolk CCG & West Suffolk CCG",
      "Irwin Mitchell Solicitors",
      "Istituto Nazionale dei Tumori",
      "Janssen-Cilag Limited",
      "Jersey Health and Social Services",
      "Jo's Cervical Cancer Trust",
      "Kantar Health",
      "Karolinska Institutet",
      "Kettering General NHS Foundation Trust",
      "Kidney Cancer UK",
      "King Edwards School",
      "King's College Hospital NHS Foundation Trust",
      "King's College London",
      "L.E.K Consulting",
      "Lancaster University",
      "Laser Products Europe Ltd",
      "Leeds Beckett University",
      "Leeds Teaching Hospitals NHS Trust",
      "Leiden University",
      "Leiden University Medical Center",
      "Lexington Communications",
      "Lincolnshire County Council",
      "Liverpool Clinical Commissioning Group",
      "Lockside Medical Centre",
      "London Borough of Bexley",
      "London Borough of Havering",
      "London Cancer Alliance",
      "London North West University Healthcare NHS Trust",
      "London School of Hygiene & Tropical Medicine",
      "London South Bank University",
      "Luton and Dunstable University Hospital NHS Foundation Trust",
      "Maastricht University Medical Center",
      "Maidstone and Tunbridge Wells NHS Trust",
      "Manchester Cancer Research Centre Biobank",
      "Manchester Clinical Commissioning Group",
      "Manchester Metropolitan University",
      "Manchester University NHS Foundation Trust",
      "Mapi-Pharma Ltd",
      "Market Access Solutions (MKTXS)",
      "McKinsey & Company",
      "Medical Research Council",
      "Medicines and Healthcare products Regulatory Agency",
      "Merck Serono Ltd",
      "MesobanK",
      "Mesothelioma UK",
      "Metropolitian Police",
      "Mid Essex Hospitals NHS Trust",
      "Milton Keynes Clinical Commissioning Group",
      "Ministry of Justice",
      "Monitor Deloitte",
      "Moorfields Eye Hospital NHS Foundation Trust",
      "Myeloma UK",
      "N/A",
      "NHS Arden and Greater East Midlands",
      "NHS Basildon and Brentford CCG",
      "NHS Business Services Authority (NHSBSA)",
      "NHS Derby and Derbyshire CCG (formerly Erewash, Hardwick, North Derbyshire and Southern",
    "Derbyshire CCGs)",
      "NHS Digital (formerly Health and Social Care Information Centre HSCIC)",
      "NHS Dorset Clinical Commissioning Group",
      "NHS England",
      "NHS Erewash Clinical Commissioning Group",
      "NHS Improvement",
      "NHS North Derbyshire CCG",
      "NHS Nottingham City CCG",
      "NHS Solutions for Public Health",
      "NHS Southern Derbyshire Clinical Commissioning Group",
      "NHS Wales",
      "National Cancer Research Institute",
      "National Cervical Cancer Coalition (NCCC)",
      "National Institute for Health Research (NIHR)",
      "National Institute for Health Research Collaboration",
      "National Institute for Health and Care Excellence (NICE)",
      "National Institutes of Health (NIH)",
      "National Perinatal Information Center",
      "National Social Marketing Centre Cic",
      "Nettleham Medical Practice",
      "New York University Abu Dhabi",
      "Newcastle University",
      "Newcastle upon Tyne Hospitals NHS Foundation Trust",
      "Norfolk & Norwich University Hospital NHS Trust",
      "North Bristol NHS Trust",
      "North Tees and Hartlepool Hospitals NHS Foundation Trust",
      "North West London Hospitals NHS Trust",
      "Northamptonshire County Council",
      "Nottingham University Hospitals NHS Trust",
      "Nottinghamshire Healthcare NHS Foundation Trust",
      "Office for National Statistics",
      "Oldham CCG",
      "Our Lady of Lourdes Hospital",
      "Outcomes Based Healthcare (OBH)",
      "Ovarian Cancer Action",
      "Owlstone Medical",
      "Oxford Academic Health Science Network",
      "Oxford PharmaGenesis Ltd",
      "Oxford University Hospitals NHS Foundation Trust",
      "P95",
      "PHMR Limited",
      "Parexel International",
      "Pear Bio",
      "Pfizer Inc",
      "Pharmathen",
      "Piedmont Cancer Registry",
      "Portsmouth Hospitals NHS Trust",
      "Prostate Cancer UK",
      "Public Health England",
      "Quality Health Ltd",
      "Queen Elizabeth Hospital King's Lynn NHS Foundation Trust",
      "Queen Mary University of London",
      "Queens University Belfast",
      "Queensland Health",
      "RAND Europe",
      "RM Partners",
      "Rare Cancers Research Foundation",
      "Roche",
      "Rochester Advisory Ltd",
      "Rotherham Metropolian Borough Council",
      "Royal Borough of Greenwich",
      "Royal College of Physicians",
      "Royal College of Radiologists",
      "Royal College of Surgeons",
      "Royal College of Surgeons in Ireland",
      "Royal Devon and Exeter NHS Foundation Trust",
      "Royal Free London NHS Foundation Trust",
      "Royal Liverpool and Broadgreen University Hospitals NHS Trust",
      "Royal Orthopaedic Hospital NHS Foundation Trust",
      "Royal Surrey County Hospital NHS Foundation Trust",
      "Royal Wolverhampton NHS Trust",
      "SVMPharma",
      "Salford Royal NHS Foundation Trust",
      "Sandwell and West Birmingham Hospitals NHS Trust",
      "Sanofi",
      "Sefton Council",
      "Shahid Beheshti University",
      "Sheffield Teaching Hospitals NHS Foundation Trust",
      "Shrewsbury and Telford Hospital NHS Trust",
      "Somerset, Wiltshire, Avon & Gloucestershire (SWAG) Cancer Services",
      "South London and Maudsley NHS Foundation Trust",
      "South Tees Hospitals NHS Foundation Trust",
      "Southampton City Council",
      "Spintech Imaging",
      "Spire Healthcare",
      "St George's University Hospitals NHS Foundation Trust",
      "Stratified Medicine 2 (CRUK)",
      "Stroke Association",
      "Sunderland LA",
      "Surrey and Sussex Healthcare NHS Trust",
      "Swansea University",
      "Tameside Metropolitan Borough Council",
      "Taunton and Somerset NHS Foundation Trust",
      "Teenage Cancer Trust",
      "Teesside University",
      "The Association of Surgeons in Training",
      "The Behavioural Insights Team",
      "The Brain Tumour Charity",
      "The CLINICAL TRIAL Company Group",
      "The Christie NHS Foundation Trust",
      "The Clinic",
      "The Facial Surgery Research Foundation",
      "The Farr Institute of Health Informatics Research",
      "The Graduate Institute of International and Development Studies",
      "The Health Improvement Network",
      "The Institute of Cancer Research",
      "The Office of Health Economics",
      "The Royal Brompton and Harefield NHS Foundation Trust",
      "The Royal College of Obstetricians and Gynaecologists",
      "The Royal Marsden NHS Foundation Trust",
      "The University of Queensland School of Medicine",
      "Torbay and South Devon NHS Foundation Trust",
      "TraceMedia",
      "Turning Point",
      "UK National Screening Committee",
      "Unicancer",
      "Universities of Brighton and Sussex",
      "University College London",
      "University College London Hospitals NHS Foundation Trust",
      "University Hospital Of South Manchester NHS Foundation Trust",
      "University Hospital Southampton NHS Foundation Trust",
      "University Hospitals Birmingham NHS Foundation Trust",
      "University Hospitals Bristol NHS Foundation Trust",
      "University Hospitals Coventry & Warwickshire NHS Trust",
      "University Hospitals of Derby and Burton NHS Foundation Trust",
      "University Hospitals of Leicester NHS Trust",
      "University Hospitals of North Midlands NHS Trust",
      "University of Aberdeen",
      "University of Adelaide",
      "University of Birmingham",
      "University of Bradford",
      "University of Brighton",
      "University of Bristol",
      "University of Cambridge",
      "University of Cardiff",
      "University of Coventry",
      "University of East Anglia",
      "University of Edinburgh",
      "University of Exeter",
      "University of Glasgow",
      "University of Huddersfield",
      "University of Hull",
      "University of Kent",
      "University of Leeds",
      "University of Leicester",
      "University of Liverpool",
      "University of London",
      "University of Manchester",
      "University of Maryland",
      "University of Nottingham",
      "University of Oxford",
      "University of Plymouth",
      "University of Portsmouth",
      "University of Sheffield",
      "University of Southampton",
      "University of Surrey",
      "University of Sussex",
      "University of Warwick",
      "University of Wolverhampton",
      "University of York",
      "Université de Montréal",
      "Unknown Organisation",
      "Velalar College of Engineering and Technology",
      "Wales Cancer Trials Unit",
      "Walton Centre NHS Foundation Trust",
      "Wellcome Sanger Institute",
      "Welsh Cancer Intelligence and Surveillance Unit",
      "West Sussex County Council",
      "Wirral Council",
      "Wirral Intelligence Service",
      "Wirral University Teaching Hospital NHS Foundation Trust",
      "Worcestershire Acute Hospitals NHS Trust",
      "pH Associates",
      "test_live"
    ]
  end
end
