use strictures 2;
use Katatsumuri::Inspector::Package;

my $result = Katatsumuri::Inspector::Package->inspect('./lib/My/Namespace/B.pm');

foreach my $package (@$result) {
    print $package->to_json_string;
}


