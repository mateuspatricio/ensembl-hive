#!/usr/bin/env perl

# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


use strict;
use warnings;

use Test::More;
use Data::Dumper;
use File::Temp qw{tempdir};

use Bio::EnsEMBL::Hive::Utils qw(dbc_to_cmd);
use Bio::EnsEMBL::Hive::Utils::Test qw(init_pipeline runWorker);

# eHive needs this to initialize the pipeline (and run db_cmd.pl)
$ENV{'EHIVE_ROOT_DIR'} = File::Basename::dirname( File::Basename::dirname( File::Basename::dirname( Cwd::realpath($0) ) ) );

my $dir = tempdir CLEANUP => 1;
chdir $dir;

my @pipeline_urls = (
    'sqlite:///ehive_test_pipeline_db',
    $ENV{'EHIVE_MYSQL_PIPELINE_URL'} ? ( $ENV{'EHIVE_MYSQL_PIPELINE_URL'} ) : (),
);

foreach my $long_mult_version (qw(LongMult_conf LongMultSt_conf LongMultWf_conf)) {
  foreach my $with_beekeeper (0..1) {
    foreach my $pipeline_url (@pipeline_urls) {
        my $hive_dba = init_pipeline('Bio::EnsEMBL::Hive::PipeConfig::'.$long_mult_version, [-pipeline_url => $pipeline_url, -hive_force_init => 1]);
        my $job_adaptor = $hive_dba->get_AnalysisJobAdaptor;


        if ($with_beekeeper) {
            my @beekeeper_cmd = ($ENV{'EHIVE_ROOT_DIR'}.'/scripts/beekeeper.pl', '-url', $hive_dba->dbc->url, '-loop', '-local');
            # beekeeper can take a while and has its own DBConnection, it
            # is better to close ours to avoid "MySQL server has gone away"
            $hive_dba->dbc->disconnect_if_idle;
            system(@beekeeper_cmd);
            ok(!$?, 'beekeeper exited with the return code 0');
            is(scalar(@{$job_adaptor->fetch_all('status != "DONE"')}), 0, 'All the jobs could be run');
        } else {
            runWorker($hive_dba, { can_respecialize => 1 });
            is(scalar(@{$job_adaptor->fetch_all('status != "DONE"')}), 0, 'All the jobs could be run');
        }

        my $results = $hive_dba->dbc->db_handle->selectall_arrayref('SELECT * FROM final_result');
        ok(scalar(@$results), 'There are some results');
        ok($_->[0]*$_->[1] eq $_->[2], sprintf("%s*%s=%s", $_->[0], $_->[1], $_->[0]*$_->[1])) for @$results;

        system( @{ dbc_to_cmd($hive_dba->dbc, undef, undef, undef, 'DROP DATABASE') } );
    }
  }
}

done_testing();