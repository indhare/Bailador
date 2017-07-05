use v6.c;

use Bailador::Route;

class Bailador::Route::Simple does Bailador::Route {
    has $.code is rw;

    method execute(Match $match) {
        $.code.(| $match.list);
    }
}
