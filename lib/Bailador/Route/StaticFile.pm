use v6.c;

use Bailador::Route;

class Bailador::Route::StaticFile does Bailador::Route {
    has $.directory is required;

    method execute(Match $path) {
        my $file = $.directory.child($path.Str);
        return $file if $file.f;
        return False;
    }

    method Str() {
        "{self.^name} $.directory"
    }
}
