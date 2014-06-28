use 5.010;
use strict;
use locale;


my $LUA_PATH_DEFAULT = q(#define LUA_PATH_DEFAULT  \\
    ".\\\\?.lua;" LUA_LDIR"?.lua;" LUA_LDIR"?\\\\init.lua;" \\
    ".\\\\?.bin;" LUA_LDIR"?.bin;" LUA_LDIR"?\\\\init.bin;");

my $LUA_CPATH_DEFAULT = q(#define LUA_CPATH_DEFAULT \\
  ".\\\\?.dll;" \\
  LUA_CDIR"?.dll;" \\
  LUA_CDIR"lib\\\\?.dll;" \\
  LUA_CDIR"loadall.dll" \\
  ".\\\\lua\\\\?.dll;" \\
  ".\\\\lua\\\\lib\\\\?.dll;");

my $__MARKER__ = qq(\n/* patched version luaconf.h [8840F93DAD6BC85D5C72D6750ED62525] */\n);

my $luaconf = fileGetContents("luaconf.h");

die "file already marked as patched: $__MARKER__\n" if $luaconf =~ m/\Q$__MARKER__\E/s;

filePutContents(createBackupName('luaconf.h.origin'), $luaconf, 'binmode');

$luaconf =~ s{\n[\x20\x09]*#[\x20\x09]*define\s+LUA_PATH_DEFAULT\b([^\n]+(\\\n))*.*?(?=\n)}{
    "\n$LUA_PATH_DEFAULT"
}es;

$luaconf =~ s{\n[\x20\x09]*#[\x20\x09]*define\s+LUA_CPATH_DEFAULT\b([^\n]+(\\\n))*.*?(?=\n)}{
    "\n$LUA_CPATH_DEFAULT"
}es;

filePutContents("luaconf.h", $luaconf . $__MARKER__);

sub fileGetContents {
    my ($filename, $binmode) = @_;
    local *file;
    open(*file, $filename) or return undef;
    binmode *file if $binmode;
    my $string;
    sysread(*file, $string, -s *file);
    close(*file);
    return $string;
}

sub filePutContents {
    my ($filename, $contents, $binmode) = @_;
    local *file;
    open(*file, "+>$filename");
    binmode *file if $binmode;
    syswrite(*file, $contents, length $contents);
    close(*file);
}

sub createBackupName {
    my ($fn, $dirname) = @_;

    $dirname = $dirname || '.';

    unless (-e <$dirname/*.backup>) {
        return $fn . '.backup';
    }

    local *dirhande;
    opendir(*dirhande, $dirname) or die;
    my @files = readdir(*dirhande);
    closedir(*dirhande);

    my $filename = '';
    my $number = -2;

    my $re = qr/(?:\.n(\d+))?\.backup$/;

    for ( grep { /^([^\n]+$re)/ } @files ) {
        /$re/;
        my $currnum = $1 || -1;
        if ($currnum > $number) {
            $number = $currnum;
            $filename = $_;
        }
    };

    return $fn . '.backup' if $filename eq '';

    $filename =~ s{ $re } {
        '.n' . (1 + ($1 || 1)) . '.backup'
    }xe;

    return $filename;
}

