use strictures 2;

use Katatsumuri::Inspector::Package;
use JSON::XS;

my $result = Katatsumuri::Inspector::Package->inspect('./lib/My/Namespace/B.pm');

foreach my $package (@$result) {
    print JSON::XS->new->pretty(1)->canonical(1)->encode($package->to_json_schema);
}

#use DDP;
#use Katatsumuri::Type;
#use Types::Standard -types;
#use JSON::XS;

#my @types = (
    #Int, Str,
    #Int | Str,
    #Int & Str,
    #Enum ["a", "b", "c"],
    #ArrayRef [Int],
    #ArrayRef [Int | Str],
    #ArrayRef [Int | Str | Enum ["a", "b", "c"]],
    #ArrayRef [Enum ["a", "b", 1]],
    #ArrayRef [Int, 1],
    #ArrayRef [Int, 0, 100],
    #Enum [1, 2, 3],
    #ArrayRef [Enum [1, 2, 3]],
    #ArrayRef,
    #Optional [Int],
    #Optional [Str],
    #Optional [Int | Str],
    #Optional [Enum ["a", "b", "c"]],
    #Optional [Int & Num],
    #Tuple [Int, Str],
    #Tuple [Int, Str, Slurpy[Int]],
    #Dict [
        #name     => Str,
        #id       => Int,
        #age      => Num,
        #optional => Optional [Int],
        #enum     => Enum ["a", "b", "c"],
        #tuple    => Tuple [Int, Str],
        #array    => ArrayRef,
        #maybe => Maybe [Int],
        #instanceOf => InstanceOf ['My::Class'],
        #intersect => Int & Str,
    #],
    #Map [Str, Int],
    #Map [Int, Enum ["a", "b", "c"]],
    #HashRef,
    #HashRef [Int],
    #HashRef [Str | Int],
    #HashRef [Str | Int | Enum ["a", "b", "c"]],
    #Ref ["HASH"],
    #Ref ["ARRAY"],
    #Ref ["CODE"],
    #ScalarRef [Int],
    #ScalarRef [Str],
    #ScalarRef [Str | Int],
    #InstanceOf [Int],
    #InstanceOf ['My::Class'],
    #Maybe[Int],
    #Maybe,
    #Maybe[Str],
    #Maybe[Int | Str],
    #Maybe[Enum ["a", "b", "c"]],
    #'Int', 'Str',
    #'My::Class',
    #[Int, "Str", Enum ["a", "b", "c"]],
    #Any,
#);

#foreach my $type (@types) {
    #my $kt = Katatsumuri::Type->new(type => $type);
    #my $info = +{
        #type => $type,

        ##json => JSON::XS->new()->pretty(1)->canonical(1)->encode($kt->to_json_schema_type_specification()),
        #json => $kt->to_json_schema_type_specification(),
    #};
    #p $info;
#}
