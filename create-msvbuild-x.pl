use 5.010;
use strict;
use locale;
use POSIX;

my $msvcrtDirName = shift || 'msvcrt';
my $currpath = POSIX::getcwd();
my $msvcrtPath = getparentdir(findFileSlopUp($msvcrtDirName . '\\msvcrt.lib', $currpath));

my $text = fileGetContents('msvcbuild.bat');

$text = conditionized($text, 'LJCOMPILE', 'LJLINK', 'LJDLLNAME', 'LJLIBNAME');

filePutContents('msvcbuild-x.bat', qq(\@call "%VS90COMNTOOLS%/vsvars32.bat"\n$text));

my $comipleSetting = qq(
    set MSVCRT_WINXP=$msvcrtPath\\msvcrt_winxp.obj
    set MSVCRT_LIB=$msvcrtPath\\msvcrt.lib

    set LJCOMPILE=cl /nologo /c /O2 /W3 /D_CRT_SECURE_NO_DEPRECATE /D_MSC_VER=1399
    set LJLINK=link /nologo /nodefaultlib /OPT:REF /OPT:ICF "%MSVCRT_WINXP%" "%MSVCRT_LIB%" "Kernel32.lib"
);

createBAT('build(liblua.dll).bat', qq(
    $comipleSetting
    set LJDLLNAME=liblua.dll
    set LJLIBNAME=liblua.lib

    call "msvcbuild-x.bat"
));

createBAT('build(lua5.1).bat', qq(
    $comipleSetting
    set LJDLLNAME=lua5.1.dll
    set LJLIBNAME=lua5.1.lib

    call "msvcbuild-x.bat"
));

createBAT('build(lua51).bat', qq(
    $comipleSetting
    set LJDLLNAME=lua51.dll
    set LJLIBNAME=lua51.lib

    call "msvcbuild-x.bat"
));

createBAT('@uninst-bat.bat', q(
    move luaconf.h.origin.backup luaconf.h
    del "build(*).bat", "msvcbuild-x.bat", "@uninst-bat.bat"
));

require 'patch-luaconf.h.pl';

sub conditionized {
    my $text = shift;
    while (my $varname = shift) {
        $text =~ s`^\s*\@?(set\s+$varname\s*=.*?)\s*$`\@if "%$varname%"=="" $1`m;
    }
    return $text;
}

sub createBAT {
    my ($filename, $text) = @_;
    $text =~ s/\n[\x20\x09]+/\n/g;
    $text =~ s/\n(\w+)/\n\@$1/g;
    $text =~ s/^\s*/\n/s;
    filePutContents($filename, $text);
}

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

sub findFileSlopUp {
    my ($searched, $path) = @_;
    my $separator = ($path =~ /([\/\\])/)[0] || '/';
    for (1..10000) {
        my $filename = $path . $separator . $searched;
        return $filename if -e $filename;
        return unless $path !~ /^\w:[\/\\]*$/ && -d $path;
        $path = getparentdir($path);
    }
    return "err >> $path"
}

sub getparentdir {
    my $path = shift;
    $path =~ s/[\\\/]+[^\\\/]+[\\\/]*$//;
    return $path;
}

