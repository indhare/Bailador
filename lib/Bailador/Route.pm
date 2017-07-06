use v6.c;

use Bailador::Exceptions;
use Bailador::Request;

role Bailador::Route { ... }

role Bailador::Routing {
    ## !! those two members are *actually* private, due to
    ## https://rt.perl.org/Public/Bug/Display.html?id=131707
    ## https://rt.perl.org/Public/Bug/Display.html?id=130690
    ## they can not be private :-(
    ## change that as soon as possible.
    ## has Bailador::Route $!prefix-route;
    has Bailador::Route @.routes;
    has Bailador::Route $.prefix-route is rw;

    ## Route Dispatch Stuff
    method recurse-on-routes(Str $method, Str $uri) {
        for @.routes -> $r {
            if $r!match: $method, $uri -> $match {
                my $result = $r.execute($match);

                if $result ~~ Failure {
                    $result.exception.throw;
                }
                elsif $result eqv True {
                    try {
                        # work around a bug in perl6
                        # https://github.com/rakudo/rakudo/commit/c04b8b5cc9
                        # <moritz> ufobat: fix pushed
                        my $postmatch =
                            $match.to == $match.from ??
                            $uri.substr($match.to) !!
                            $match.postmatch;
                        return $r.recurse-on-routes($method, $postmatch);
                        CATCH {
                            when X::Bailador::NoRouteFound {
                                # continue with the next route
                            }
                        }
                    }
                }
                elsif $result eqv False {
                    # continue with the next route
                }
                else {
                    return $result;
                }
            }
        }
        die X::Bailador::NoRouteFound.new;
    }

    method !match (Str $method, Str $path) {
        if @.method {
            return False if @.method.any ne $method
        }

        my Match $match = $path ~~ $.path;
        if @.routes {
            # we have children routes -- so this is a prefixroute
            # its okay not to match the whole regular expression.

            return $match if $match;
        } else {
            return $match if $match and $match.postmatch eq '';
        }
        return False;
    }

    ## Add Routes#
    multi method add_route(Bailador::Route $route) {
        my $curr = self!get_current_route();
        # avoid obvious duplicate routes
        my $matches = $curr.routes.grep({ $_.method.Str eq $route.method.Str and $_.path.perl eq $route.path.perl });
        die "duplicate route: {$route.method.Str} {$route.path.perl}" if $matches;
        $curr.routes.push($route);
    }

    ## Prefix Route Stuff
    method !get-prefix-route {
        return $.prefix-route
    }

    method !set-prefix-route(Bailador::Route $prefix-route) {
        $.prefix-route = $prefix-route;
    }

    method !del_current_route {
        if not $.prefix-route {
            # nothing to do
        }
        elsif $.prefix-route and not $.prefix-route!get-prefix-route {
            my $route = $.prefix-route;
            $.prefix-route = Bailador::Route:U;
            self.add_route($route);
        }
        else {
            $.prefix-route!del_current_route()
        }
    }
    method !get_current_route {
        return $.prefix-route!get_current_route() if $.prefix-route;
        return self;
    }

     method prefix(Bailador::Route $prefix, Callable $code) {
        my $curr = self!get_current_route();
        $curr!set-prefix-route( $prefix );
        $code.();
        self!del_current_route();
    }

    method prefix-enter(Callable $code) {
        my $curr = self!get_current_route();
        $curr.set-prefix-enter: $code;
    }
}

subset HttpMethod of Str where {$_ eq any <GET PUT POST HEAD PUT DELETE TRACE OPTIONS CONNECT PATCH> }

role Bailador::Route does Bailador::Routing {
    has HttpMethod @.method;
    has Str $.path-str;        # string representation of route path
    has Regex $.path;

    method execute(Match $match) { ... }

}
