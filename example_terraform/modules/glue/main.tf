resource "aws_glue_catalog_database" "single_glue_database" {
  name = "${var.prefix}-mycatalogdatabase"
}

/*
resource "aws_glue_catalog_table" "single_glue_table" {
  name          = "${var.prefix}-mycatalogtable"
  database_name = "${var.prefix}-mycatalogdatabase"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
  }

  storage_descriptor {
    location      = "arn:aws:s3:::jhoh-test-bucket/20221201-20230101/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "my-stream"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "field.delim" = ","
      }
    }

    columns {
        name = "identity/lineitemid"
        type = "string"
    }
    columns {
        name = "identity/timeinterval"
        type = "string"
    }
    columns {
        name = "bill/invoiceid"
        type = "string"
    }
    columns {
        name = "bill/invoicingentity"
        type = "string"
    }
    columns {
        name = "bill/billingentity"
        type = "string"
    }
    columns {
        name = "bill/billtype"
        type = "string"
    }
    columns {
        name = "bill/payeraccountid"
        type = "bigint"
    }
    columns {
        name = "bill/billingperiodstartdate"
        type = "string"
    }
    columns {
        name = "bill/billingperiodenddate"
        type = "string"
    }
    columns {
        name = "lineitem/usageaccountid"
        type = "bigint"
    }
    columns {
        name = "lineitem/lineitemtype"
        type = "string"
    }
    columns {
        name = "lineitem/usagestartdate"
        type = "string"
    }
    columns {
        name = "lineitem/usageenddate"
        type = "string"
    }
    columns {
        name = "lineitem/productcode"
        type = "string"
    }
    columns {
        name = "lineitem/usagetype"
        type = "string"
    }
    columns {
        name = "lineitem/operation"
        type = "string"
    }
    columns {
        name = "lineitem/availabilityzone"
        type = "string"
    }
    columns {
        name = "lineitem/resourceid"
        type = "string"
    }
    columns {
        name = "lineitem/usageamount"
        type = "double"
    }
    columns {
        name = "lineitem/normalizationfactor"
        type = "string"
    }
    columns {
        name = "lineitem/normalizedusageamount"
        type = "string"
    }
    columns {
        name = "lineitem/currencycode"
        type = "string"
    }
    columns {
        name = "lineitem/unblendedrate"
        type = "double"
    }
    columns {
        name = "lineitem/unblendedcost"
        type = "double"
    }
    columns {
        name = "lineitem/blendedrate"
        type = "double"
    }
    columns {
        name = "lineitem/blendedcost"
        type = "double"
    }
    columns {
        name = "lineitem/lineitemdescription"
        type = "string"
    }
    columns {
        name = "lineitem/taxtype"
        type = "string"
    }
    columns {
        name = "lineitem/netunblendedrate"
        type = "double"
    }
    columns {
        name = "lineitem/netunblendedcost"
        type = "double"
    }
    columns {
        name = "lineitem/legalentity"
        type = "string"
    }
    columns {
        name = "product/productname"
        type = "string"
    }
    columns {
        name = "product/accesstype"
        type = "string"
    }
    columns {
        name = "product/accountassistance"
        type = "string"
    }
    columns {
        name = "product/alarmtype"
        type = "string"
    }
    columns {
        name = "product/architecturalreview"
        type = "string"
    }
    columns {
        name = "product/architecturesupport"
        type = "string"
    }
    columns {
        name = "product/attachmenttype"
        type = "string"
    }
    columns {
        name = "product/availability"
        type = "string"
    }
    columns {
        name = "product/availabilityzone"
        type = "string"
    }
    columns {
        name = "product/bestpractices"
        type = "string"
    }
    columns {
        name = "product/bitrate"
        type = "string"
    }
    columns {
        name = "product/bundle"
        type = "string"
    }
    columns {
        name = "product/bundledescription"
        type = "string"
    }
    columns {
        name = "product/bundlegroup"
        type = "string"
    }
    columns {
        name = "product/cacheengine"
        type = "string"
    }
    columns {
        name = "product/capacitystatus"
        type = "string"
    }
    columns {
        name = "product/caseseverityresponsetimes"
        type = "string"
    }
    columns {
        name = "product/category"
        type = "string"
    }
    columns {
        name = "product/citype"
        type = "string"
    }
    columns {
        name = "product/classicnetworkingsupport"
        type = "string"
    }
    columns {
        name = "product/clientlocation"
        type = "string"
    }
    columns {
        name = "product/clockspeed"
        type = "string"
    }
    columns {
        name = "product/cloudsearchversion"
        type = "string"
    }
    columns {
        name = "product/contenttype"
        type = "string"
    }
    columns {
        name = "product/countsagainstquota"
        type = "string"
    }
    columns {
        name = "product/cputype"
        type = "string"
    }
    columns {
        name = "product/currentgeneration"
        type = "string"
    }
    columns {
        name = "product/customerserviceandcommunities"
        type = "string"
    }
    columns {
        name = "product/datatransferquota"
        type = "string"
    }
    columns {
        name = "product/databaseengine"
        type = "string"
    }
    columns {
        name = "product/datatransferout"
        type = "string"
    }
    columns {
        name = "product/dedicatedebsthroughput"
        type = "string"
    }
    columns {
        name = "product/deploymentoption"
        type = "string"
    }
    columns {
        name = "product/description"
        type = "string"
    }
    columns {
        name = "product/directorysize"
        type = "string"
    }
    columns {
        name = "product/directorytype"
        type = "string"
    }
    columns {
        name = "product/directorytypedescription"
        type = "string"
    }
    columns {
        name = "product/dominantnondominant"
        type = "string"
    }
    columns {
        name = "product/durability"
        type = "string"
    }
    columns {
        name = "product/ecu"
        type = "string"
    }
    columns {
        name = "product/edition"
        type = "string"
    }
    columns {
        name = "product/endpointtype"
        type = "string"
    }
    columns {
        name = "product/enginecode"
        type = "string"
    }
    columns {
        name = "product/enhancednetworkingsupported"
        type = "string"
    }
    columns {
        name = "product/executionfrequency"
        type = "string"
    }
    columns {
        name = "product/executionlocation"
        type = "string"
    }
    columns {
        name = "product/feecode"
        type = "string"
    }
    columns {
        name = "product/feedescription"
        type = "string"
    }
    columns {
        name = "product/framerate"
        type = "string"
    }
    columns {
        name = "product/freeoverage"
        type = "string"
    }
    columns {
        name = "product/freetrial"
        type = "string"
    }
    columns {
        name = "product/frequencymode"
        type = "string"
    }
    columns {
        name = "product/fromlocation"
        type = "string"
    }
    columns {
        name = "product/fromlocationtype"
        type = "string"
    }
    columns {
        name = "product/fromregioncode"
        type = "string"
    }
    columns {
        name = "product/group"
        type = "string"
    }
    columns {
        name = "product/groupdescription"
        type = "string"
    }
    columns {
        name = "product/includedservices"
        type = "string"
    }
    columns {
        name = "product/input"
        type = "string"
    }
    columns {
        name = "product/inputmode"
        type = "string"
    }
    columns {
        name = "product/instance"
        type = "string"
    }
    columns {
        name = "product/instancefamily"
        type = "string"
    }
    columns {
        name = "product/instancetype"
        type = "string"
    }
    columns {
        name = "product/instancetypefamily"
        type = "string"
    }
    columns {
        name = "product/intelavx2available"
        type = "string"
    }
    columns {
        name = "product/intelavxavailable"
        type = "string"
    }
    columns {
        name = "product/intelturboavailable"
        type = "string"
    }
    columns {
        name = "product/launchsupport"
        type = "string"
    }
    columns {
        name = "product/license"
        type = "string"
    }
    columns {
        name = "product/licensemodel"
        type = "string"
    }
    columns {
        name = "product/location"
        type = "string"
    }
    columns {
        name = "product/locationtype"
        type = "string"
    }
    columns {
        name = "product/logsdestination"
        type = "string"
    }
    columns {
        name = "product/marketoption"
        type = "string"
    }
    columns {
        name = "product/maxiopsburstperformance"
        type = "string"
    }
    columns {
        name = "product/maxiopsvolume"
        type = "string"
    }
    columns {
        name = "product/maxthroughputvolume"
        type = "string"
    }
    columns {
        name = "product/maxvolumesize"
        type = "string"
    }
    columns {
        name = "product/maximumstoragevolume"
        type = "string"
    }
    columns {
        name = "product/memory"
        type = "string"
    }
    columns {
        name = "product/memorygib"
        type = "string"
    }
    columns {
        name = "product/memorytype"
        type = "string"
    }
    columns {
        name = "product/messagedeliveryfrequency"
        type = "string"
    }
    columns {
        name = "product/messagedeliveryorder"
        type = "string"
    }
    columns {
        name = "product/meteringtype"
        type = "string"
    }
    columns {
        name = "product/minvolumesize"
        type = "string"
    }
    columns {
        name = "product/minimumstoragevolume"
        type = "string"
    }
    columns {
        name = "product/networkperformance"
        type = "string"
    }
    columns {
        name = "product/normalizationsizefactor"
        type = "string"
    }
    columns {
        name = "product/operatingsystem"
        type = "string"
    }
    columns {
        name = "product/operation"
        type = "string"
    }
    columns {
        name = "product/operationssupport"
        type = "string"
    }
    columns {
        name = "product/origin"
        type = "string"
    }
    columns {
        name = "product/output"
        type = "string"
    }
    columns {
        name = "product/outputmode"
        type = "string"
    }
    columns {
        name = "product/overagetype"
        type = "string"
    }
    columns {
        name = "product/parametertype"
        type = "string"
    }
    columns {
        name = "product/physicalprocessor"
        type = "string"
    }
    columns {
        name = "product/pipeline"
        type = "string"
    }
    columns {
        name = "product/platofeaturetype"
        type = "string"
    }
    columns {
        name = "product/platopricingtype"
        type = "string"
    }
    columns {
        name = "product/platostoragetype"
        type = "string"
    }
    columns {
        name = "product/platousagetype"
        type = "string"
    }
    columns {
        name = "product/preinstalledsw"
        type = "string"
    }
    columns {
        name = "product/pricingunit"
        type = "string"
    }
    columns {
        name = "product/proactiveguidance"
        type = "string"
    }
    columns {
        name = "product/processorarchitecture"
        type = "string"
    }
    columns {
        name = "product/processorfeatures"
        type = "string"
    }
    columns {
        name = "product/productfamily"
        type = "string"
    }
    columns {
        name = "product/programmaticcasemanagement"
        type = "string"
    }
    columns {
        name = "product/provisioned"
        type = "string"
    }
    columns {
        name = "product/queuetype"
        type = "string"
    }
    columns {
        name = "product/recipient"
        type = "string"
    }
    columns {
        name = "product/region"
        type = "string"
    }
    columns {
        name = "product/regioncode"
        type = "string"
    }
    columns {
        name = "product/requestdescription"
        type = "string"
    }
    columns {
        name = "product/requesttype"
        type = "string"
    }
    columns {
        name = "product/reservetype"
        type = "string"
    }
    columns {
        name = "product/resolution"
        type = "string"
    }
    columns {
        name = "product/resourceendpoint"
        type = "string"
    }
    columns {
        name = "product/resourcetype"
        type = "string"
    }
    columns {
        name = "product/rootvolume"
        type = "string"
    }
    columns {
        name = "product/routingtarget"
        type = "string"
    }
    columns {
        name = "product/routingtype"
        type = "string"
    }
    columns {
        name = "product/runningmode"
        type = "string"
    }
    columns {
        name = "product/servicecode"
        type = "string"
    }
    columns {
        name = "product/servicename"
        type = "string"
    }
    columns {
        name = "product/sku"
        type = "string"
    }
    columns {
        name = "product/softwareincluded"
        type = "string"
    }
    columns {
        name = "product/steps"
        type = "string"
    }
    columns {
        name = "product/storage"
        type = "string"
    }
    columns {
        name = "product/storageclass"
        type = "string"
    }
    columns {
        name = "product/storagemedia"
        type = "string"
    }
    columns {
        name = "product/storagetype"
        type = "string"
    }
    columns {
        name = "product/subscriptiontype"
        type = "string"
    }
    columns {
        name = "product/technicalsupport"
        type = "string"
    }
    columns {
        name = "product/tenancy"
        type = "string"
    }
    columns {
        name = "product/thirdpartysoftwaresupport"
        type = "string"
    }
    columns {
        name = "product/throughput"
        type = "string"
    }
    columns {
        name = "product/tiertype"
        type = "string"
    }
    columns {
        name = "product/tolocation"
        type = "string"
    }
    columns {
        name = "product/tolocationtype"
        type = "string"
    }
    columns {
        name = "product/toregioncode"
        type = "string"
    }
    columns {
        name = "product/trafficdirection"
        type = "string"
    }
    columns {
        name = "product/training"
        type = "string"
    }
    columns {
        name = "product/transfertype"
        type = "string"
    }
    columns {
        name = "product/usagetype"
        type = "string"
    }
    columns {
        name = "product/uservolume"
        type = "string"
    }
    columns {
        name = "product/vcpu"
        type = "string"
    }
    columns {
        name = "product/version"
        type = "string"
    }
    columns {
        name = "product/videoquality"
        type = "string"
    }
    columns {
        name = "product/volumeapiname"
        type = "string"
    }
    columns {
        name = "product/volumetype"
        type = "string"
    }
    columns {
        name = "product/vpcnetworkingsupport"
        type = "string"
    }
    columns {
        name = "product/whocanopencases"
        type = "string"
    }
    columns {
        name = "pricing/leasecontractlength"
        type = "string"
    }
    columns {
        name = "pricing/offeringclass"
        type = "string"
    }
    columns {
        name = "pricing/purchaseoption"
        type = "string"
    }
    columns {
        name = "pricing/ratecode"
        type = "string"
    }
    columns {
        name = "pricing/rateid"
        type = "bigint"
    }
    columns {
        name = "pricing/currency"
        type = "string"
    }
    columns {
        name = "pricing/publicondemandcost"
        type = "double"
    }
    columns {
        name = "pricing/publicondemandrate"
        type = "double"
    }
    columns {
        name = "pricing/term"
        type = "string"
    }
    columns {
        name = "pricing/unit"
        type = "string"
    }
    columns {
        name = "reservation/amortizedupfrontcostforusage"
        type = "string"
    }
    columns {
        name = "reservation/amortizedupfrontfeeforbillingperiod"
        type = "string"
    }
    columns {
        name = "reservation/effectivecost"
        type = "string"
    }
    columns {
        name = "reservation/endtime"
        type = "string"
    }
    columns {
        name = "reservation/modificationstatus"
        type = "string"
    }
    columns {
        name = "reservation/netamortizedupfrontcostforusage"
        type = "string"
    }
    columns {
        name = "reservation/netamortizedupfrontfeeforbillingperiod"
        type = "string"
    }
    columns {
        name = "reservation/neteffectivecost"
        type = "string"
    }
    columns {
        name = "reservation/netrecurringfeeforusage"
        type = "string"
    }
    columns {
        name = "reservation/netunusedamortizedupfrontfeeforbillingperiod"
        type = "string"
    }
    columns {
        name = "reservation/netunusedrecurringfee"
        type = "string"
    }
    columns {
        name = "reservation/netupfrontvalue"
        type = "string"
    }
    columns {
        name = "reservation/normalizedunitsperreservation"
        type = "string"
    }
    columns {
        name = "reservation/numberofreservations"
        type = "string"
    }
    columns {
        name = "reservation/recurringfeeforusage"
        type = "string"
    }
    columns {
        name = "reservation/reservationarn"
        type = "string"
    }
    columns {
        name = "reservation/starttime"
        type = "string"
    }
    columns {
        name = "reservation/subscriptionid"
        type = "bigint"
    }
    columns {
        name = "reservation/totalreservednormalizedunits"
        type = "string"
    }
    columns {
        name = "reservation/totalreservedunits"
        type = "string"
    }
    columns {
        name = "reservation/unitsperreservation"
        type = "string"
    }
    columns {
        name = "reservation/unusedamortizedupfrontfeeforbillingperiod"
        type = "string"
    }
    columns {
        name = "reservation/unusednormalizedunitquantity"
        type = "string"
    }
    columns {
        name = "reservation/unusedquantity"
        type = "string"
    }
    columns {
        name = "reservation/unusedrecurringfee"
        type = "string"
    }
    columns {
        name = "reservation/upfrontvalue"
        type = "string"
    }
    columns {
        name = "discount/sppdiscount"
        type = "double"
    }
    columns {
        name = "discount/totaldiscount"
        type = "double"
    }
    columns {
        name = "savingsplan/totalcommitmenttodate"
        type = "string"
    }
    columns {
        name = "savingsplan/savingsplanarn"
        type = "string"
    }
    columns {
        name = "savingsplan/savingsplanrate"
        type = "string"
    }
    columns {
        name = "savingsplan/usedcommitment"
        type = "string"
    }
    columns {
        name = "savingsplan/savingsplaneffectivecost"
        type = "string"
    }
    columns {
        name = "savingsplan/amortizedupfrontcommitmentforbillingperiod"
        type = "string"
    }
    columns {
        name = "savingsplan/recurringcommitmentforbillingperiod"
        type = "string"
    }
    columns {
        name = "savingsplan/netsavingsplaneffectivecost"
        type = "string"
    }
    columns {
        name = "savingsplan/netamortizedupfrontcommitmentforbillingperiod"
        type = "string"
    }
    columns {
        name = "savingsplan/netrecurringcommitmentforbillingperiod"
        type = "string"
    }
    columns {
        name = "resourcetags/aws =createdby"
        type = "string"
    }

  }
}   */