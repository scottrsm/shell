## sbee 

**DESCRIPTION:** A generalization of the NYT Spelling Bee mini-puzzle.
                 A maximum score is generated for the problem in accordance with the NYT puzzle's rules.

- A string of letters with length less than *min_word_length* provides no points.
- A string of letters with length equal to *min_word_length* yields one point.
- A string of letters greater than *min_word_length*(default 4) gives a number of points equal to the length of the string.
- If all letters from the may-use and must-use lists are used in a word, an additional 7 points are allotted.

              
**Usage:** sbee [-h] [-b] [-v] [-m min-word-length(4)]  may-use-letters   must-use-letters

**Options:**

-         h -- Help message.
-         b -- Use British English.
-         m -- Set the minimum word length for this puzzle.
-         v -- Verbose mode: Show the expanded may-use and must-use lists.

**Args   :**

-          may-use-letters : Letters a user *may* use to create a word.
-          must-use-letters: Letters a user *must* use to create a word.

*NOTE:* A user may use any letter more than once.

**Example 1:** sbee oavtle g

    Find all words from the alphabet, "oavtle" + "g", where "g" must be used.
    Uses default minimum word length of 4.
    There is one special word, "voltage" -- special here means
    a word that uses all the letters.

**Example 2:** sbee -m 5 clodym ef

    Set the minimum word length to 5.

**Example 3:** sbee -v [a-i] oy[r-v]

    Use the range syntax, [<X>-<Y>], to describe the letter lists.
    Here the expanded may-use and must-use lists are: abcdefghi and orstuvy.

**Example 4:** sbee -v [a-i]k[l-n] oy[r-v]

    Here the expanded may-use and must-use lists are: abcdefghiklmn and orstuvy.

**Example 5:** sbee [a-z] able

    This is an example of how to trick *sbee* into creating words
    from a list, forcing it to use ALL the letters from the list: able,
    for each word it produces. 

**Example 6:** sbee a able

    This is an example of how to trick *sbee* into creating words
    from a list, forcing it to use ALL and ONLY the letters
    from the list: able.

 **Example 7:** sbee [a-z] aeiouy

    Find all words that use every vowel including 'y'.



## find_word_part 
              

**DESCRIPTION:** Find all words in a file that contain a given word or word part.<br>
    By default, matches ignore case and are ordered by
    number of occurrences, and secondarily ordered lexically.

**RATIONALE  :** Useful for finding how word fragments are used in screen plays.

**USAGE  :** find_word_part [-h] [-c] [-f] [-p] [-u] [-w] [-x] file word_part

**Options:**

-         h -- Help message.
-         c -- Use strict case matching.
-         f -- After match, fold cases into lower case.
-         p -- Look only for words that strictly contain <word_part>.
-         u -- Display the unique matches ordered lexically.
-         w -- Look for words that fully match <word_part>.
-         x -- Assume input file is an html file.

**Args   :**

-          file     : The file, text or html, to process.
-          word_part: A word or word fragment.

**EXAMPLE:**  find_word_part -c -f -p -u -x ~/movie_plays/theapartment.html wise

    The screen play for the for "The Apartment" is processed (-x) as an HTML file, finding matches
    in words *strictly* containing the word part, "wise" (-p).
    The matching for "wise" is done using case sensitive matching (-c).
    The unique (-u), case folded (-f), matches are
    listed in lexical order.


## find_dup_label 
              
**DESCRIPTION:** Finds duplicate labels in a latex source tree reporting duplicates
             along with associated files and line numbers.

**RATIONALE  :** A LaTeX project spanning a directory tree with multiple authors
             makes finding duplicate labels difficult as the LaTeX log file
             does not indicate which files/lines are responsible for the duplications.

**USAGE      :** find_dup_label [-h] [-d directory-tree  (default .    )]
                            [-p latex-ext-pat]  (default *.tex)]

**Options    :**

-             h -- Help message.
-             d -- Directory path of LaTeX project.
-             p -- LaTeX glob pattern describing LaTeX file extension used in project.

**Args       :** NONE

**EXAMPLE 1  :** cd ~/proj/latex_proj; find_dup_label

**EXAMPLE 2  :** find_dup_label -d ~/proj/latex_proj

**EXAMPLE 3  :** find_dup_label -d ~/proj/latex_proj -p *.tex

**EXAMPLE 4  :** find_dup_label -d ~/proj/latex_proj -p *.[lt]*

## Version
1.0.5

