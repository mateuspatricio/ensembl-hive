=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

=pod

=head1 NAME

Bio::EnsEMBL::Hive::Cacheable - base class to cache collections

=cut

package Bio::EnsEMBL::Hive::Cacheable;

use strict;
use warnings;

use Bio::EnsEMBL::Hive::Utils ('stringify');
use Bio::EnsEMBL::Hive::Utils::Collection;

our %cache_by_class;    # global Hash-of-Hashes


sub collection {
    my $class = shift @_;

    if(@_) {
        $cache_by_class{$class} = shift @_;
    }

    return $cache_by_class{$class};
}


sub unikey {    # to be redefined by individual Cacheable classes
    return undef;
}


1;
