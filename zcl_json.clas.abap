class ZCL_JSON definition
  public
  final
  create public .

public section.

  data INCLUDE_EMPTY_VALUES type FLAG value 'X' ##NO_TEXT.
  data PRETTY_PRINT type FLAG .
  data LOWERCASE_NAMES type FLAG value 'X' ##NO_TEXT.
  data USE_CONVERSION_EXITS type FLAG value 'X' ##NO_TEXT.

  class-methods CLASS_CONSTRUCTOR .
  methods ENCODE
    importing
      value(NAME) type CLIKE optional
      value(VALUE) type ANY
    returning
      value(JSON) type STRING .
  methods DECODE
    importing
      value(JSON) type CLIKE
    changing
      value(VALUE) type ANY .
protected section.
private section.

  class-data CR type C .
  class-data LF type C .

  class-methods PRETTY_PRINT_JSON
    importing
      value(JSON_IN) type CLIKE
    returning
      value(JSON_OUT) type STRING .
  class-methods DATE_SAP_TO_ISO
    importing
      value(DATE) type DATS
    returning
      value(RESULT) type STRING .
  class-methods DATE_ISO_TO_SAP
    importing
      value(DATE) type CLIKE
    returning
      value(RESULT) type DATS .
  class-methods TIME_SAP_TO_ISO
    importing
      value(TIME) type TIMS
    returning
      value(RESULT) type STRING .
  class-methods TIME_ISO_TO_SAP
    importing
      value(TIME) type CLIKE
    returning
      value(RESULT) type TIMS .
  class-methods TIMESTAMP_SAP_TO_ISO
    importing
      value(TIMESTAMP) type TIMESTAMP
    returning
      value(RESULT) type STRING .
  class-methods TIMESTAMP_ISO_TO_SAP
    importing
      value(TIMESTAMP) type CLIKE
    returning
      value(RESULT) type TIMESTAMP .
  class-methods ESCAPE_STRING
    importing
      value(INPUT) type CLIKE
    returning
      value(RESULT) type STRING .
  methods ENCODE_ANYTHING
    importing
      value(NAME) type CLIKE optional
      value(VALUE) type ANY
    returning
      value(JSON) type STRING .
  methods ENCODE_OBJECT
    importing
      value(NAME) type CLIKE optional
      !TYPE type ref to CL_ABAP_TYPEDESCR
      value(VALUE) type ANY
    returning
      value(JSON) type STRING .
  methods ENCODE_STRUCTURE
    importing
      value(NAME) type CLIKE optional
      !TYPE type ref to CL_ABAP_TYPEDESCR
      value(VALUE) type ANY
    returning
      value(JSON) type STRING .
  methods ENCODE_TABLE
    importing
      value(NAME) type CLIKE optional
      !TYPE type ref to CL_ABAP_TYPEDESCR
      value(VALUE) type ANY
    returning
      value(JSON) type STRING .
  methods ENCODE_FIELD
    importing
      value(NAME) type CLIKE
      !TYPE type ref to CL_ABAP_TYPEDESCR
      value(VALUE) type ANY
    returning
      value(JSON) type STRING .
  methods DECODE_ANYTHING
    importing
      !JSON type STRING
      !LENGTH type INT4
    changing
      !POSITION type INT4
      !VALUE type ANY .
  methods DECODE_OBJECT
    importing
      !NAME type CLIKE
      !JSON type STRING
      !LENGTH type INT4
    changing
      !POSITION type INT4
      !VALUE type ANY .
  methods DECODE_ARRAY
    importing
      !NAME type CLIKE
      !JSON type STRING
      !LENGTH type INT4
    changing
      !POSITION type INT4
      !VALUE type ANY .
  methods DECODE_FIELD
    importing
      !NAME type CLIKE
      !JSON type CLIKE
      !LENGTH type INT4
    changing
      !VALUE type ANY
      !POSITION type INT4 .
  methods DECODE_STRING
    importing
      !JSON type CLIKE
      !LENGTH type INT4
    changing
      !POSITION type INT4
      value(STRING) type STRING .
  methods DECODE_KEYWORD
    importing
      !JSON type CLIKE
      !LENGTH type INT4
    changing
      !POSITION type INT4
      value(STRING) type STRING .
  methods DECODE_NUMBER
    importing
      !JSON type CLIKE
      !LENGTH type INT4
    changing
      !POSITION type INT4
      value(STRING) type STRING .
  methods CALL_CONVERSION_EXIT
    importing
      value(DIRECTION) type DIRECTION
      value(TYPE) type ref to CL_ABAP_TYPEDESCR
      value(VALUE) type ANY
    changing
      value(RESULT) type ANY .
ENDCLASS.



CLASS ZCL_JSON IMPLEMENTATION.


method call_conversion_exit.
    data: ddic_objects  type dd_x031l_table,
          function_name type string,
          cstr_value    type c length 255.
    field-symbols: <ddic> like line of ddic_objects.

    "// Call conversion exit function
    type->get_ddic_object(
      receiving p_object = ddic_objects
      exceptions others = 8
    ).
    read table ddic_objects index 1 assigning <ddic>.
    if sy-subrc = 0 and <ddic>-convexit is not initial.
      cstr_value = value.
      if direction = 1.
        concatenate 'CONVERSION_EXIT_' <ddic>-convexit '_OUTPUT'
          into function_name.
      else.
        concatenate 'CONVERSION_EXIT_' <ddic>-convexit '_INPUT'
          into function_name.
      endif.
      try.
        call function function_name
          exporting
            input  = cstr_value
          importing
            output = result
          exceptions
            others = 8.
      catch cx_root.
      endtry.
    endif.
  endmethod.


method CLASS_CONSTRUCTOR.
  "// Initialize static attributes
  field-symbols <x> type x.

  assign cr to <x> casting. <x> = 13.
  assign lf to <x> casting. <x> = 10.
endmethod.


method DATE_ISO_TO_SAP.
  data: year(4) type n,
        month(2) type n,
        day(2) type n.

  "// ISO-8601 allowed formats:
  "//  YYYY-MM-DD or YYYYMMDD or YYYY-MM
  find regex '(\d{4})-?(\d{2})-?(\d{2})?' in date
    submatches year month day.
  if year is initial and
     month is initial and
     day is initial.
    return.
  endif.
  if day is initial.
    day = 1.
  endif.

  concatenate year month day into result.
endmethod.


method DATE_SAP_TO_ISO.
  concatenate date(4) '-' date+4(2) '-' date+6(2) into result.
endmethod.


method DECODE.
  data: decode_string type string,
        decode_length type i,
        decode_pos type i.

  "// Prepare decoding
  decode_string = json.
  condense decode_string.
  decode_length = strlen( decode_string ).
  decode_pos = 0.

  clear value.

  "// Decode JSON string into value object
  decode_anything(
    exporting
      json = decode_string
      length = decode_length
    changing
      position = decode_pos
      value = value
  ).
endmethod.


method DECODE_ANYTHING.
  data: name type string,
        string_value type string,
        has_name type flag.

  "// Skip padding characters
  skip_to_next_character.
  check position < length.

  "// Member has a name?
  if json+position(1) = '"'.
    has_name = 'X'.
    decode_string(
      exporting
        json = json
        length = length
      changing
        position = position
        string = name
    ).
  endif.

  "// Skip padding characters
  skip_to_next_character.
  check position < length.

  "// Check if this is a single value or an attribute
  if has_name = 'X'.
    case json+position(1).
      when ','.
        value = name.
        add 1 to position.
        return.
      when ':'.
        add 1 to position.
      when  ']' or '}'.
        value = name.
        return.
    endcase.
  endif.

  "// Skip padding characters
  skip_to_next_character.
  check position < length.

  "// Decode member value
  case json+position(1).
    when '"'. "// begin string
      decode_field(
        exporting
          name = name
          json = json
          length = length
        changing
          position = position
          value = value
      ).

    when '{'.
      "// begin object => structure
      decode_object(
        exporting
          name = name
          json = json
          length = length
        changing
          position = position
          value = value
      ).

    when '['.
      "// begin array => table
      decode_array(
        exporting
          name = name
          json = json
          length = length
        changing
          position = position
          value = value
      ).

    when others.
      "// begin keyword or number
      decode_field(
        exporting
          name = name
          json = json
          length = length
        changing
          position = position
          value = value
      ).

  endcase.

  "// Check if object/array has just ended
  skip_to_next_character.
  check position < length.

  if json+position(1) na ']}'.
    add 1 to position.
  endif.
endmethod.


method DECODE_ARRAY.
  data: abap_name type string,
        typekind type c,
        dummy type table of syst,
        ld_line type ref to data.

  field-symbols: <table> type any table,
                 <struct> type any.

  abap_name = name. translate abap_name to upper case.
  describe field value type typekind.
  if typekind = cl_abap_typedescr=>typekind_table.
    assign value to <table>.
  else.
    assign component abap_name of structure value to <table>.
    if sy-subrc <> 0.
      assign dummy to <table>.
    endif.
  endif.

  add 1 to position.

  "// Decode member value
  while position < length and
        json+position(1) <> ']'.

    create data ld_line like line of <table>.
    assign ld_line->* to <struct>.

    decode_anything(
      exporting
        json = json
        length = length
      changing
        position = position
        value = <struct>
    ).

    insert <struct> into table <table>.

    "// Skip padding characters
    skip_to_next_character.
    check position < length.
  endwhile.
  add 1 to position.
endmethod.


method decode_field.
  data: abap_name type string,
        str_value type string,
        type type ref to cl_abap_typedescr,
        relative_name type string.
  field-symbols: <field> type any.

  "// Skip padding characters
  skip_to_next_character.
  check position < length.

  "// Decode field value
  case json+position(1).
    when '"'. "// String
      decode_string(
        exporting
          json = json
          length = length
        changing
          position = position
          string = str_value
      ).
    when 't' or 'f' or 'n'. "// Keyword
      decode_keyword(
        exporting
          json = json
          length = length
        changing
          position = position
          string = str_value
      ).
    when others. "// Numbers
      decode_number(
        exporting
          json = json
          length = length
        changing
          position = position
          string = str_value
      ).
  endcase.

  abap_name = name. translate abap_name to upper case.
  assign component abap_name of structure value to <field>.
  if sy-subrc <> 0.
    return.
  endif.

  "// Get type kind
  type ?= cl_abap_typedescr=>describe_by_data( <field> ).

  "// Timestamp? (becomes ISO-8601)
  relative_name = type->get_relative_name( ).
  if relative_name = 'TIMESTAMP'.
    <field> = timestamp_iso_to_sap( str_value ).
  else.
    case type->type_kind.
        "// Date fields (become ISO-8601)
        when cl_abap_typedescr=>typekind_date.
          <field> = date_iso_to_sap( str_value ).

        "// Time fields (become ISO-8601)
        when cl_abap_typedescr=>typekind_time.
          <field> = time_iso_to_sap( str_value ).

      "// Anything else gets the default SAP input conversion
      when others.
        <field> = str_value.
        if me->use_conversion_exits is not initial.
          call_conversion_exit(
            exporting direction = 2
                      type = type
                      value = str_value
            changing result = <field>
          ).
        endif.
    endcase.
  endif.
endmethod.


method decode_keyword.
  data: first_char type c.

  first_char = json+position(1).
  while position < length.
    if json+position(1) na 'truefalsn'. "// true, false and null
      exit.
    endif.
    add 1 to position.
  endwhile.

  case first_char.
    when 't'. "// true
      string = 'X'.
    when 'f'. "// false
      string = space.
    when 'n'. "// null
      string = ''.
  endcase.
endmethod.


method decode_number.
  data: characters type table of c.

  while position < length.
    if json+position(1) na '0123456789.+-eE'.
      exit.
    else.
      append json+position(1) to characters.
    endif.
    add 1 to position.
  endwhile.

  concatenate lines of characters into string respecting blanks.
endmethod.


method DECODE_OBJECT.
  data: abap_name type string,
        dummy type syst.
  field-symbols: <struct> type any.

  if name is initial.
    assign value to <struct>.
  else.
    abap_name = name. translate abap_name to upper case.
    assign component abap_name of structure value to <struct>.
    if sy-subrc <> 0.
      assign dummy to <struct>.
    endif.
  endif.

  add 1 to position.

  "// Decode member value
  while position < length and
        json+position(1) <> '}'.

    decode_anything(
      exporting
        json = json
        length = length
      changing
        position = position
        value = <struct>
    ).

    "// Skip padding characters
    skip_to_next_character.
    check position < length.
  endwhile.
  add 1 to position.
endmethod.


method decode_string.
  data: characters      type table of c,
        unicode_hexc(4) type c,
        unicode_hex(4)  type x.

  field-symbols: <unicode_char> type c.

  add 1 to position.
  while position < length.
    case json+position(1).
      when '\'. "// Escaped character
        add 1 to position.
        case json+position(1).
          when '"'.
            append '"' to characters.
          when '\'.
            append '\' to characters.
          when '/'.
            append '/' to characters.
          when 'r'.
            append cr to characters.
          when 'n'.
            append lf to characters.
          when 'u'.
            add 1 to position.
            unicode_hexc = json+position(4).
            translate unicode_hexc to upper case.
            unicode_hex = unicode_hexc.
            assign unicode_hex to <unicode_char> casting.
            append <unicode_char> to characters.
            add 3 to position.
        endcase.
      when '"'. "// Finished string
        exit.
      when others.
        append json+position(1) to characters.
    endcase.

    add 1 to position.
  endwhile.
  add 1 to position.

  concatenate lines of characters into string respecting blanks.
endmethod.


method ENCODE.
  "// Encode passed data object to normal JSON
  json = encode_anything(
    name = name
    value = value
  ).

  "// Format generated JSON string
  if json is not initial.
    "// Apply indented style
    if me->pretty_print is not initial.
      json = pretty_print_json( json ).
    endif.
  else.
    if name is not initial.
      concatenate name ': {}' into json.
    else.
      json = '{}'.
    endif.
  endif.
endmethod.


method ENCODE_ANYTHING.
  data: type type ref to cl_abap_typedescr,
        contents_json type string.

  "// Check if this should be included
  check value is not initial or me->include_empty_values is not initial.

  "// Get data object type
  type = cl_abap_typedescr=>describe_by_data( value ).

  case type->type_kind.
    "// Object references
    when cl_abap_typedescr=>typekind_oref.
      json = encode_object(
        name = name
        type = type
        value = value
      ).

    "// Structures
    when cl_abap_typedescr=>typekind_struct1 or
         cl_abap_typedescr=>typekind_struct2.
      json = encode_structure(
        name = name
        type = type
        value = value
      ).

    "// Tables
    when cl_abap_typedescr=>typekind_table.
      json = encode_table(
        name = name
        type = type
        value = value
      ).

    "// Fields
    when others.
      json = encode_field(
        name = name
        type = type
        value = value
      ).
  endcase.
endmethod.


method encode_field.
  data: formatted_value type string,
        relative_name   type string.

  "// Timestamp? (becomes ISO-8601)
  relative_name = type->get_relative_name( ).
  if relative_name = 'TIMESTAMP'.
    formatted_value = timestamp_sap_to_iso( value ).
  else.
    case type->type_kind.
        "// Date fields (become ISO-8601)
      when cl_abap_typedescr=>typekind_date.
        formatted_value = date_sap_to_iso( value ).

        "// Time fields (become ISO-8601)
      when cl_abap_typedescr=>typekind_time.
        formatted_value = time_sap_to_iso( value ).

        "// Static fields (don't need conversion)
      when cl_abap_typedescr=>typekind_num or
           cl_abap_typedescr=>typekind_hex or
           cl_abap_typedescr=>typekind_string or
           cl_abap_typedescr=>typekind_xstring.
        formatted_value = value.

        "// Numeric fields
      when cl_abap_typedescr=>typekind_packed or
           cl_abap_typedescr=>typekind_float or
           cl_abap_typedescr=>typekind_int or
           cl_abap_typedescr=>typekind_int1 or
           cl_abap_typedescr=>typekind_int2 or
           cl_abap_typedescr=>typekind_numeric.
        formatted_value = value.
        translate formatted_value using '- + '.
        condense formatted_value no-gaps.
        if value < 0.
          concatenate '-' formatted_value into formatted_value.
        endif.

        "// Anything else gets the default SAP output conversion
      when others.
        formatted_value = value.
        if me->use_conversion_exits is not initial.
          call_conversion_exit(
            exporting direction = 1
                      type = type
                      value = value
            changing result = formatted_value
          ).
        endif.

    endcase.
  endif.
  formatted_value = escape_string( formatted_value ).

  "// Build JSON string
  if me->lowercase_names is not initial.
    translate name to lower case.
  endif.
  concatenate '"' name '": "' formatted_value '"' into json.
endmethod.


method ENCODE_OBJECT.
  data: ref type ref to cl_abap_refdescr,
        obj type ref to cl_abap_objectdescr,
        attributes_json type table of string,
        attribute_name type string,
        json_line type string.

  field-symbols: <attribute_descr> like line of obj->attributes,
                 <attribute> type any.

  "// Encode all obj attributes
  ref ?= type.
  obj ?= ref->get_referenced_type( ).

  loop at obj->attributes assigning <attribute_descr>
      where visibility = cl_abap_classdescr=>public.
    concatenate 'value->' <attribute_descr>-name into attribute_name.
    assign (attribute_name) to <attribute>.
    if sy-subrc = 0.
      json_line = encode_anything(
        name = <attribute_descr>-name
        value = <attribute>
      ).
      if json_line is not initial.
        append json_line to attributes_json.
      endif.
    endif.
  endloop.

  "// Build JSON string
  concatenate lines of attributes_json into json
    separated by ','.
  if name is not initial.
    if me->lowercase_names is not initial.
      translate name to lower case.
    endif.
    concatenate '"' name '": {' json '}' into json.
  else.
    concatenate '{' json '}' into json.
  endif.
endmethod.


method ENCODE_STRUCTURE.
  data: struct type ref to cl_abap_structdescr,
        fields_json type table of string,
        field_name type string,
        json_line type string.

  field-symbols: <component> like line of struct->components,
                 <field> type any.

  "// Encode all class attributes
  struct ?= type.

  loop at struct->components assigning <component>.
    assign component <component>-name of structure value
      to <field>.
    if sy-subrc = 0.
      json_line = encode_anything(
        name = <component>-name
        value = <field>
      ).
      if json_line is not initial.
        append json_line to fields_json.
      endif.
    endif.
  endloop.

  "// Build JSON string
  concatenate lines of fields_json into json
    separated by ','.
  if name is not initial.
    if me->lowercase_names is not initial.
      translate name to lower case.
    endif.
    concatenate '"' name '": {' json '}' into json.
  else.
    concatenate '{' json '}' into json.
  endif.
endmethod.


method ENCODE_TABLE.
  data: table type ref to cl_abap_tabledescr,
        lines_json type table of string,
        json_line type string.

  field-symbols: <table> type any table,
                 <line> type any.

  "// Encode all table lines
  table ?= type.

  assign value to <table>.
  loop at <table> assigning <line>.
    json_line = encode_anything(
      value = <line>
    ).
    if json_line is not initial.
      append json_line to lines_json.
    endif.
  endloop.

  "// Build JSON string
  concatenate lines of lines_json into json
    separated by ','.
  if name is not initial.
    if me->lowercase_names is not initial.
      translate name to lower case.
    endif.
    concatenate '"' name '": [' json ']' into json.
  else.
    concatenate '[' json ']' into json.
  endif.
endmethod.


method ESCAPE_STRING.
  data: cr type c,
        lf type c.

  field-symbols <x> type x.

  assign cr to <x> casting. <x> = 13.
  assign lf to <x> casting. <x> = 10.

  result = input.
  replace regex '\s+$' in result with ''.
  replace all occurrences of '\' in result with '\\'.
  replace all occurrences of cr in result with '\r'.
  replace all occurrences of lf in result with '\n'.
  replace all occurrences of '"' in result with '\"'.
endmethod.


method PRETTY_PRINT_JSON.
  data: input_length type i,
        input_pos type i,
        prev_input_char type c,
        input_char type c,
        next_input_pos type i,
        next_input_char type c,
        in_string type flag,
        skip_chars type i,
        result_pos type i,
        indent_level type i,
        start_new_line_before type flag,
        start_new_line_after type flag,
        result type table of string,
        result_line(1024) type c.

  "// Go through the input string and ident it, creating a line table
  input_length = strlen( json_in ).
  do input_length times.
    input_char = json_in+input_pos(1).
    next_input_pos = input_pos + 1.
    if next_input_pos < input_length.
      next_input_char = json_in+next_input_pos(1).
    else.
      clear next_input_char.
    endif.

    if skip_chars = 0.
      case input_char.
        "// Escaped character
        when '\'.
          skip_chars = 1.
          if next_input_char = 'u'.
            skip_chars = 5.
          endif.

        "// String
        when '"'.
          if in_string is initial.
            in_string = 'X'.
          else.
            clear in_string.
          endif.

        "// Opening blocks
        when '{' or '['.
          if in_string is initial.
            add 1 to indent_level.
            if next_input_char <> '}' and
               next_input_char <> ']'.
              start_new_line_after = 'X'.
            endif.
          endif.

        "// Closing blocks
        when '}' or ']'.
          if in_string is initial.
            subtract 1 from indent_level.
            if prev_input_char <> '{' and
               prev_input_char <> '['.
              start_new_line_before = 'X'.
            endif.
          endif.

        "// Between members
        when ','.
          if in_string is initial.
            start_new_line_after = 'X'.
          endif.
      endcase.
    else.
      subtract 1 from skip_chars.
    endif.

    if start_new_line_before is not initial.
      clear start_new_line_before.
      append result_line to result.
      clear result_line.
      result_pos = indent_level * 2.
    endif.

    result_line+result_pos = input_char.
    add 1 to result_pos.

    if start_new_line_after is not initial.
      clear start_new_line_after.
      append result_line to result.
      clear result_line.
      result_pos = indent_level * 2.
    endif.

    prev_input_char = input_char.
    input_pos = next_input_pos.
  enddo.
  append result_line to result.

  "// Glue the lines together
  concatenate lines of result into json_out
    separated by %_cr_lf.
endmethod.


method TIMESTAMP_ISO_TO_SAP.
  data: date_iso type string,
        time_iso type string,
        tsc(14) type c.

  split timestamp at 'T' into date_iso time_iso.
  check sy-subrc = 0.

  tsc(8) = date_iso_to_sap( date_iso ).
  tsc+8(6) = time_iso_to_sap( time_iso ).
  result = tsc.
endmethod.


method TIMESTAMP_SAP_TO_ISO.
  data: begin of ts_split,
          date type datum,
          time type uzeit,
        end of ts_split,
        tsc(14) type n,
        date_iso type string,
        time_iso type string.

  ts_split = tsc = timestamp.
  date_iso = date_sap_to_iso( ts_split-date ).
  time_iso = time_sap_to_iso( ts_split-time ).

  concatenate date_iso 'T' time_iso into result.
endmethod.


method TIME_ISO_TO_SAP.
  data: hour(2) type n,
        min(2) type n,
        sec(2) type n.

  "// ISO-8601 allowed formats:
  "//  hh:mm:ss or hh:mm or hhmmss or hhmm or hh
  find regex '(\d{2}):?(\d{2})?:?(\d{2})?' in time
    submatches hour min sec.

  concatenate hour min sec into result.
endmethod.


method TIME_SAP_TO_ISO.
  concatenate time(2) ':' time+2(2) ':' time+4(2) into result.
endmethod.
ENDCLASS.
