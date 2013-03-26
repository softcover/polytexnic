
## Math

### Inline math

	pandoc -s spec/fixtures/inline_math.tex --mathjax -o tmp/inline_math.html

### Math environments

    pandoc -s spec/fixtures/math_environments --mathjax -o tmp/math_environments.html

Pandoc handles equation environments wrong; it converts

    \begin{equation}
      \varphi^2 = \varphi + 1.
    \end{equation}

into the non-equivalent

    \[
      \varphi^2 = \varphi + 1.
    \]


## Verbatim environments

Pandoc does well with inline verbatim text like `\verb+$x$+`, but it doesn't handle nested verbatim environments properly. In particular, it chokes on

    \begin{verbatim}
      \begin{verbatim}
        This is verbatim text.
      \end{verbatim}
    \end{verbatim}
    
## Tables

Pandoc doesn't handle tables at all.

## Sections with cross-references

Pandoc doesn't handle cross-references.