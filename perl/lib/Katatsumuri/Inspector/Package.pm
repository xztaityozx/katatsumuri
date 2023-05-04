package Katatsumuri::Inspector::Package;

use strictures 2;
use Function::Return;
use Function::Parameters;
use Types::Standard -types;
use Carp qw(croak);

use Katatsumuri::Result::Package;
use Katatsumuri::Inspector::Methods;
use Katatsumuri::Inspector::Properties;

use PPI;

method _get_superclasses (Str $class_name) : Return(ArrayRef[Str]) {
    no strict 'refs';
    my @superclasses = @{ $class_name . '::ISA' };
    use strict 'refs';

    return \@superclasses;
}

# inspect は $file_name に渡された Perl のソースコードを解析して
# 定義されているパッケージ/クラス情報の配列返す
method inspect ($class : Str | ScalarRef $file_name) : Return(ArrayRef[InstanceOf['Katatsumuri::Result::Package']]) {
    my $document = PPI::Document->new($file_name) or croak("failed to load $file_name");

    my $package_nodes = $document->find('PPI::Statement::Package');

    my @result;
    foreach my $package_node (@{$package_nodes}) {
        my @namespace = split(/::/x, $package_node->namespace);
        my $name = pop @namespace;

        push @result,
          Katatsumuri::Result::Package->new(
            name          => $name,
            namespace     => \@namespace,
            super_classes => $class->_get_superclasses($package_node->namespace),
            methods       => Katatsumuri::Inspector::Methods->inspect($package_node, $document),
            properties    => Katatsumuri::Inspector::Properties->inspect($package_node),
            file_name     => $file_name,
          );
    }

    return \@result;
}

1;
