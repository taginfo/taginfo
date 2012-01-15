#!/usr/bin/perl
#------------------------------------------------------------------------------
#
#  Taginfo source: DB
#
#  update_characters.pl
#
#------------------------------------------------------------------------------
#
#  Copyright (C) 2012  Jochen Topf <jochen@remote.org>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with this program; if not, write to the Free Software Foundation, Inc.,
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#------------------------------------------------------------------------------

use DBI;

my $dir = $ARGV[0] || '.';

my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/taginfo-db.db", '', '');
$dbh->{unicode} = 1;
#$dbh->{sqlite_unicode} = 1;

my @regexes = (
    ['plain',   qr{^[a-z]([a-z_]*[a-z])?$}],
    ['colon',   qr{^[a-z][a-z_:]*[a-z]$}],
    ['letters', qr{^[\p{L}\p{M}]([\p{L}\p{M}\p{N}_:]*[\p{L}\p{M}\p{N}])?$}],
    ['space',   qr{[\s\p{Z}]}],
    ['problem', qr{[=+/&<>;\@'"?%#\\,\p{C}]}]
);

my %keys;
my $results = $dbh->selectcol_arrayref('SELECT key FROM keys');

ROW: foreach my $key (@$results) {
    $keys{$key} = 'rest';
    foreach my $r (@regexes) {
        if ($key =~ $r->[1]) {
            $keys{$key} = $r->[0];
            next ROW;
        }
    }
}

$dbh->do('BEGIN TRANSACTION');

foreach my $key (keys %keys) {
    $dbh->do('UPDATE keys SET characters=? WHERE key=?', undef, $keys{$key}, $key);
}

$dbh->do('COMMIT');


#-- THE END -------------------------------------------------------------------
