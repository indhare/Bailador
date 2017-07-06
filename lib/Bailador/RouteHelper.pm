use v6.c;

use Bailador::Route;
use Bailador::Route::Prefix;
use Bailador::Route::Simple;
use Bailador::Route::StaticFile;

unit module Bailador::RouteHelper;

multi sub make-prefix-route(Str $path) is export {
    my @method = <GET PUT POST HEAD PUT DELETE TRACE OPTIONS CONNECT PATCH>;
    my $regex  = route_to_regex($path);
    Bailador::Route::Prefix.new( :@method, :path($regex), :path-str($path) );
}
multi sub make-prefix-route(Regex $path) is export {
    my @method = <GET PUT POST HEAD PUT DELETE TRACE OPTIONS CONNECT PATCH>;
    Bailador::Route::Prefix.new( :@method, :$path, :path-str($path.perl) );
}
multi sub make-prefix-route($path, Callable $code) is export {
    my $route = make-prefix-route($path);
    $route.set-prefix-enter($code);
    return $route;
}

sub make-simple-route(*@a, *%a) is export {
    Bailador::Route::Simple.new(|@a, |%a);
}

sub make-static-dir-route(Pair $x) is export {
    my $path = $x.key;
    my IO $directory = $x.value ~~ IO ?? $x.value !! $*PROGRAM.parent.child($x.value.Str);
    return Bailador::Route::StaticFile.new(path => $x.key, directory => $directory);
}

my sub route_to_regex($route) {
    my $regex = $route.split('/').map({
        my $r = $_;
        if $_.substr(0, 1) eq ':' {
           $r = q{(<-[\/\.]>+)};
        }
        $r
    }).join("'/'");
    $regex = q{/ ^} ~ $regex ~ q{ [ $ || <?before '/' > ] /};
    return $regex.EVAL;
}

