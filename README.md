## ABAP-JSON

A JSON encoder/parser in ABAP.


### Features

* Pure ABAP (ECC6 compatible)
* Support for deep ABAP structures and tables (unlimited levels)
* Output compact or pretty printed JSON
* Output lower case or upper case field names
* Correctly outputs/parses dates, times and timestamps
* Uses conversion exits for input and output based on dynamic typing


### Installation

Install the ZCL_JSON class as a global class.


### Usage

#### Methods

<table>
  <tr>
    <td>encode</td>
    <td>
      Import parameters:<br>
      CLIKE name (optional) - Object name<br>
      ANY value - ABAP value to be encoded<br>
      <br>
      Return: STRING - JSON string.
    </td>
    <td>
      Encodes an ABAP variable to JSON (recursively).<br>
      <br>
      Simple variables will generate a JSON field (without enclosing brackets).<br>
      Structures will generate a JSON object.<br>
      Tables will generate a JSON array.
    </td>
  </tr>
  <tr>
    <td>decode</td>
    <td>
      Import parameters:<br>
      CLIKE json - JSON string<br>
      <br>
      Changing parameters:<br>
      ANY value - ABAP value to be set with the JSON content.
    </td>
    <td>
      Parses a JSON string into an ABAP variable (recursively).<br>
      <br>
      Simple JSON fields should be parsed into simple ABAP variables.<br>
      JSON objects should be parsed into ABAP structures.<br>
      JSON arrays should be parsed into ABAP tables.<br>
      <br>
      JSON fields that are not found in the ABAP variable will be ignored.<br>
      JSON fields that are not compatible with the corresponding ABAP variable (eg. a JSON array matching an ABAP structure) will also be ignored.<br>
      Conversion errors are not supported.
    </td>
  </tr>
</table>

#### Properties

<table>
  <tr>
    <td>include_empty_values</td>
    <td>
      When generating JSON, include ABAP fields that have no value.<br>
      The statement IS INITIAL is used to determine if an ABAP field is empty.
    </td>
  </tr>
  <tr>
    <td>pretty_print</td>
    <td>
      Generates human-friendly JSON, organized in lines and indented.<br>
      This causes a serious performance impact, so it should only be used if the resulting JSON really needs to be read by a human.
    </td>
  </tr>
  <tr>
    <td>lowercase_names</td>
    <td>
      When generating JSON, output field names in lower case. Field values are not affected by this.<br>
      This is not applicable to JSON parsing, as ABAP variable names are not case sensitive.
    </td>
  </tr>
  <tr>
    <td>use_conversion_exits</td>
    <td>
      When generating ou parsing JSON, use corresponding conversion exits for ABAP variables that have it defined in the ABAP dictionary.<br>
      ABAP runtime type services (RTTS) is used to read Dictionary information for ABAP fields.<br>
      ABAP variables must be correctly typed for this feature to work. Generically typed fields will not be converted.
    </td>
  </tr>
</table>


### Code Example

``` abap
data: s_vendor type vmds_ei_extern,
      o_json   type ref to zcl_json,
      v_json   type string.

cl_erp_vendor_api=>read_vendor(
  exporting iv_lifnr = '0004000000'
  importing es_vendor = s_vendor
).

create object o_json.
o_json->lowercase_names = abap_true.
o_json->include_empty_values = abap_false.
o_json->pretty_print = abap_true.

v_json = o_json->encode( s_vendor ).
```

Output:
```
{
  "header": {
    "object_instance": {
      "lifnr": "4000000"
    },
    "object_task": "C"
  },
  "central_data": {
    "central": {
      "data": {
        "ktokk": "VV04",
        "adrnr": "71207"
      }
    },
    "address": {
      "postal": {
        "data": {
          "from_date": "0001-01-01",
          "to_date": "9999-12-31",
          "name": "BLACK HAT EVENTS REGISTRATION DEPT.",
          "city": "SAN FRAN",
          "district": "Suite 900 South Tower",
          "postl_cod1": "99999-9999",
          "street": "303 2ND STREET",
          "house_no": "SN",
          "country": "US",
          "countryiso": "US",
          "langu": "EN",
          "langu_iso": "EN",
          "region": "CA",
          "sort1": "BLACK HAT",
          "time_zone": "PST",
          "langu_cr": "PT",
          "langucriso": "PT"
        }
      },
      "remark": {
        "current_state": "X"
      },
      "communication": {
        "phone": {
          "current_state": "X"
        },
        "fax": {
          "current_state": "X"
        },
        "ttx": {
          "current_state": "X"
        },
        "tlx": {
          "current_state": "X"
        },
        "smtp": {
          "current_state": "X",
          "smtp": [
            {
              "contact": {
                "data": {
                  "std_no": "X",
                  "e_mail": "EMAIL@EMAIL",
                  "email_srch": "EMAIL@EMAIL",
                  "home_flag": "X",
                  "consnumber": "001"
                }
              },
              "remark": {
                "current_state": "X"
              }
            }
          ]
        },
        "rml": {
          "current_state": "X"
        },
        "x400": {
          "current_state": "X"
        },
        "rfc": {
          "current_state": "X"
        },
        "prt": {
          "current_state": "X"
        },
        "ssf": {
          "current_state": "X"
        },
        "uri": {
          "current_state": "X"
        },
        "pager": {
          "current_state": "X"
        }
      },
      "version": {
        "current_state": "X"
      }
    },
    "text": {
      "current_state": "X"
    },
    "vat_number": {
      "current_state": "X"
    },
    "tax_grouping": {
      "current_state": "X"
    },
    "bankdetail": {
      "current_state": "X"
    },
    "subrange": {
      "current_state": "X"
    }
  },
  "company_data": {
    "current_state": "X",
    "company": [
      {
        "data_key": {
          "bukrs": "21"
        },
        "data": {
          "akont": "21011001",
          "zwels": "BCEGMOPRTU",
          "zterm": "D007",
          "fdgrv": "V3",
          "reprf": "X"
        },
        "dunning": {
          "current_state": "X"
        },
        "wtax_type": {
          "current_state": "X"
        },
        "texts": {
          "current_state": "X"
        }
      },
      {
        "data_key": {
          "bukrs": "29"
        },
        "data": {
          "akont": "21011001",
          "zwels": "BCEGMOPRTU",
          "zterm": "D007",
          "fdgrv": "V3",
          "reprf": "X"
        },
        "dunning": {
          "current_state": "X"
        },
        "wtax_type": {
          "current_state": "X"
        },
        "texts": {
          "current_state": "X"
        }
      }
    ]
  },
  "purchasing_data": {
    "current_state": "X",
    "purchasing": [
      {
        "data_key": {
          "ekorg": "VV01"
        },
        "data": {
          "waers": "USD",
          "zterm": "D007"
        },
        "functions": {
          "current_state": "X"
        },
        "texts": {
          "current_state": "X"
        },
        "purchasing2": {
          "current_state": "X"
        }
      }
    ]
  }
}
```


### Contributors

* Guilherme Maeda (http://abap.ninja)


### License

This code is distributed under the MIT License, meaning you can freely and unrestrictedly use it, change it, share it, distribute it and package it with your own programs as long as you keep the copyright notice, license and disclaimer.
