# Files
1. File names below `gta2/data`, like maps, must never be longer than 22
   characters total (including the file extension) as it causes a buffer
   overflow with unpredictable crashes.

# Scripts
1. When using `THREAD_WAIT_FOR_CHAR_IN_AREA_ANY_MEANS` the sum of `width` and
   `height` must not be > 125

# Mapping
1. If you fall through solid slopes, check if the sloped block has another
   sloped block beneath it, which can sometimes cause this.
