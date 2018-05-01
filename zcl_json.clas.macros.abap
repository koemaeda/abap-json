*"* use this source file for any macro definitions you need
*"* in the implementation part of the class

define skip_to_next_character.
  while position < length and
        json+position(1) na '",:{}[]tfn0123456789.+-eE'.
    add 1 to position.
  endwhile.
end-of-definition.
