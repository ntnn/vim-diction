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
