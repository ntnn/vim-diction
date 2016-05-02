# Version: 4
Add unit tests
Works over newlines in code comments

## To Dos:
* Allow ranges to check for bad diction

# Version: 3
Major speed improvements (~8s on 400 lines down to less then half
a second) by using `searchpos()` instead of `match()`.

Use a dictionary instead of a simple, global list, with a buflocal and
global variable to define the active set of databases.

## New Commands:
* `DictionIndex`
* `DictionAdd`
* `LDictionAdd`
* `DictionSet`

## New Options:
* `diction_open_window`
* `diction_db_sets`
* `diction_active_set`

## Removed Options:
* `diction_databases`

## To Dos:
* Allow ranges to check for bad diction

# Version: 2
Rewrite. Doesn't use `diction` anymore.
Using a similar database format (tsv) is simpler than parsing the output
of diction and also enables vim-diction to ship with multiple databases
by default.

## New Commands:
* `DictionLog`

## New Options:
* `diction_databases`

## To Dos:
* Allow ranges to check for bad diction
* Command to add to existing qf/loclist
* Allow blacklisting shipped databases

## Removed:
* `diction_options`
* `diction_suggest`


# Version: 1
## Commands:
* `Diction`
* `LDiction`

## Mappings:
* `<Plug>Diction`
* `<Plug>LDiction`

## Options:
* `diction_options`
* `diction_suggest`
* `diction_debug`

## To Dos:
* Allow ranges to pass those through to diction via stdin.
      In that case an offset has to be given to calculate_lnumcol
* Allow different / multiple files
* Some annotations are extremely long. Make those
      multiline
* For some reason the calculated lnum/col are a few characters
      off, sometimes positive, sometimes negative
* Better way to remove leading and trailing whitespace
