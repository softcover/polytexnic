
## Math

### Inline math

    pandoc --standalone inline_math.tex --mathjax -o inline_math.html

### Math environments

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

## Verbatim environments

Pandoc does well with inline verbatim text, but it doesn't handle nested verbatim environments properly. In particular, it chokes on

    \begin{verbatim}
      \begin{verbatim}
        This is verbatim text.
      \end{verbatim}
    \end{verbatim}

That's OK; we already have the code to handle this case properly. We'll probably want to match Pandoc's convention of converting

    \begin{verbatim}
      foo bar
    \end{verbatim}

to

    <pre><code>
      foo bar
    </pre></code>