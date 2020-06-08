Node Classes
- DataItem
  An item for a dataset. Has one XmlType to restrict content
  e.g node.name: BasisOfCancerDiagnosis. XmlType allows values of ["0", "1", "2", "4", "5", "6", "7", "9"]
- Entity
  Used to from a section of Nodes.
  e.g node.name: Diagnosis which can contain child nodes of different types
- Group
  A way for a node to share a reference to a group of other nodes
  e.g node.name: DiagnosisGroup. a BreastDiagnosis Nodes::Entity references this as well as a CNSDiagnosis Nodes::Entity
- Choice
  Allows us to build a choice into the tree. A choice can be between an Entity(s) or Item(s)
  e.g Imaging in COSD desires a choice between two items or a group of items.
- CategoryChoice
  A special node currently for COSD only. Where we traverse the tree multiple times for each category.
  This denotes a point in the tree we need to iterate over from for each category.
  e.g
  COSD header then a choice or Breast Record or CNS Record.
  Nodes can belong to categories. At the moment it's seeded to be on Nodes::Entity only. If we traverse our tree for a category
  when building, we know whether or not to create for the node. No categories means the node applies to all.

COSD example.
Categories apply to COSD where we would build a CategoryRecord tree for each category and include/exclude nodes as required
Nodes::CategoryChoice is used once for this situation at the moment - a special kind of choice.

A DataItem must have an XmlType which will define the allowed value format for it.
This could have a list of values (EnumerationValue), or an allowed format.

Ruby Class                     Example Node Name           XmlType class (has_one on    Enumeration Values     Category         
                                                           Nodes::DataItem only)        (If Applicable)
=====================          ==========================  ============================ =====================  ============
Nodes::Entity                  COSD                                                                           
---------------------------------------------------------------------------------------------------------------------------
  Nodes::Group                 COSDGroup                                                                      
  Nodes::DataItem              Id                          Id                                                 
  Nodes::DataItem              RecordCount                 RecordCount                                        
  Nodes::DataItem              ReportingPeriodStartDate    ST_PHE_Date                                        
  Nodes::DataItem              ReportingPeriodEndDate      ST_PHE_Date                                        
  Nodes::DataItem              FileCreationDateTime        ST_PHE_DateTime                                    
  Nodes::CategoryChoice        Record Group Choice                                                            
--------------------------------------------------------------------------------------------------------------------------
    Nodes::Entity              Record                                                                         
      Nodes::Group             RecordId                                                                       
        Nodes::DataItem        Id                          Id                                                
--------------------------------------------------------------------------------------------------------------------------
    Nodes::Entity              LinkagePatientId            
      Nodes::Group             LinkagePatientIdGroup
        Nodes::Choice          PatientIdentifier
          Nodes::DataItem      NHSNumber                   NHSNumber
          Nodes::DataItem      LocalPatientIdExtended      LocalPatientIdExtended
        Nodes::DataItem        NHSNumberStatusIndicator    NHSNumberStatusIndicator    01 02 03 04 05 06 07 08
        Nodes::DataItem        Birthdate                   ST_PHE_Date
--------------------------------------------------------------------------------------------------------------------------
    Nodes::Entity              Imaging
      Nodes::Group             ImagingGroup
        Nodes::DataItem        ProcedureDate               ST_PHE_Date
        Nodes::Choice          ImagingChoice
          Nodes::Entity        ImagingDetails
            Nodes::Group       ImagingDetailsGroup
              Nodes::DataItem  ImagingAnatomicalSide       ImagingAnatomicalSide
              Nodes::DataItem  CancerImagingModality       CancerImagingModality
              Nodes::DataItem  ImagingAnatomicalSite       ImagingAnatomicalSite
          Nodes::DataItem      NICIPCode                   NICIPCode
          Nodes::DataItem      ImagingCodeSNOMEDCT         ImagingCodeSNOMEDCT
      Nodes::Entity            ImagingCNS                                                                      CNS
        Nodes::Group           ImagingCNSGroup
          Nodes::DataItem      NumberOfLesions             NumberOfLesions
          Nodes::DataItem      LesionLocation              LesionLocation
          Nodes::DataItem      DiagnosticImagingType       DiagnosticImagingType"]]

REPRESENTING LEGACY NHS SCHEMAS
To recreate the duplication of NHS generated schemas the duplication has been recreated (!)
i.e CategoryChoice concept does not apply
A node tree would look something like:

COSD
- FILE HEADER
- COSDRecord
  - Breast
    - BreastCore
      - BreastLinkagePatient
        - CORE LINKAGE ITEMS
  - CNS
    - CNSCore
      - CNSLinkagePatient
        - CORE LINKAGE ITEMS
        
Schema diff'ing will now map these duplicates to the new single occurrence of the core node.
