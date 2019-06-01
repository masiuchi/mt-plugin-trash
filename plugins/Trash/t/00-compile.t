use strict;
use warnings;

use lib qw( lib extlib plugins/Trash/lib );

use Test::More;

use_ok 'Trash::CMS';
use_ok 'Trash::Callback';
use_ok 'Trash::L10N';
use_ok 'Trash::L10N::ja';

done_testing;

