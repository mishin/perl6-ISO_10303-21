use v6;
use ISO_10303_21::Grammar;

class ISO_10303_21::Record {
    has $.keyword;
    has @.parameters;
    
    method entity_instances {
        sub extract-instances($_) {
            when ISO_10303_21::Record { $_.entity_instances; }
            when List                 { $_.map(-> $i { extract-instances($i) }); }
            when /^'#'(\d+)/          { $_; }
            default                   { Nil; }
        }
        
        @.parameters.map({ extract-instances($_) });
    }
}

class ISO_10303_21::Actions {
    has %.entities;
    
    method parameter($/) {
        if $<typed_parameter> {
            make $<typed_parameter>.ast;
        } elsif $<untyped_parameter> {
            make $<untyped_parameter>.ast;
        } else {
            make ~$/;
        }
    }
    method untyped_parameter($/) {
        if $<list_of_parameters> {
            make $<list_of_parameters>.ast;
        } else {
            make ~$/;
        }
    }
    method typed_parameter($/) { 
        make ISO_10303_21::Record.new(:keyword($<keyword>),
                                      :parameters($<parameter>.ast)); 
    }
    method list_of_parameters($/)   { make @($<parameter>)».ast.Array }
    method parameter_list($/)       { make @($<parameter>)».ast.Array }

    method simple_record($/) {
        # bit awkward, but this way works in both Rakudo and Niecza
        if $<parameter_list> {
            my $parameter_list = $<parameter_list>;
            $parameter_list = $parameter_list[0] if $parameter_list ~~ Parcel;
            make ISO_10303_21::Record.new(:keyword(~$<keyword>),
                                          :parameters($parameter_list.ast // []));
        } else {
            make ISO_10303_21::Record.new(:keyword(~$<keyword>),
                                          :parameters([]));
        }
    }
    method subsuper_record($/) { make $<simple_record>».ast }
    method simple_entity_instance($/)  { %.entities{$<entity_instance_name>} = $<simple_record>.ast }
    method complex_entity_instance($/) { %.entities{$<entity_instance_name>} = $<subsuper_record>.ast }
}