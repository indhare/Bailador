use v6.c;

use Bailador::Route;

class Bailador::Route::Simple does Bailador::Route {
    has Callable $.code is rw;

    method execute(Match $match) {
        $.code.(| $match.list);
    }

    sub route_to_regex($route) {
        $route.split('/').map({
            my $r = $_;
            if $_.substr(0, 1) eq ':' {
               $r = q{(<-[\/\.]>+)};
            }
            $r
        }).join("'/'");
    }

    multi submethod new(Str @method, Regex $path, Callable $code, Str $path-str = $path.perl) {
        self.bless(:@method, :$path, :$code, :$path-str);
    }
    multi submethod new(Str $method, Regex $path, Callable $code, Str $path-str = $path.perl) {
        my Str @methods = $method eq 'ANY'
        ?? <GET PUT POST HEAD PUT DELETE TRACE OPTIONS CONNECT PATCH>
        !! ($method);
        self.new(@methods, $path, $code, $path-str);
    }
    multi submethod new(Str $method, Str $path, Callable $code, Str $path-str = $path.perl) {
        my $regex = "/ ^ " ~ route_to_regex($path) ~ " [ \$ || <?before '/' > ] /";
        self.new($method, $regex.EVAL, $code, $path-str);
    }
    multi submethod new($meth, Pair $route) {
        self.new($meth, $route.key, $route.value, $route.key.perl);
    }
}
