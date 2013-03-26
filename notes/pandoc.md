Inline math:

    pandoc --standalone inline_math.tex --mathjax -o inline_math.html

Math environments:

    pandoc --standalone inline_math.tex --mathjax -o inline_math.html

Pandoc handles equation environments wrong; it converts

    \begin{equation}
      \varphi^2 = \varphi + 1.
    \end{equation}

into the non-equivalent

    \[
      \varphi^2 = \varphi + 1.
    \]

This means we will have to pre-process equation environments and their ilk. This is really just subset of handling verbatim environments.