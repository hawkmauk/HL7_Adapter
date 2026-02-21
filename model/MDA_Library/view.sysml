package MDA_View {
    
    private import Views::*;
    private import MDA_Structure::*;

    rendering asTypeScript : TextualRendering[1] :> renderings {
        doc
        /*
         * asTypeScript renders a View into a TypeScript code format.
         */
    }

    rendering asLaTeX : TextualRendering[1] :> renderings {
        doc
        /*
         * asLaTeX renders a View into a LaTeX code format.
         */
    }

    rendering asPython : TextualRendering[1] :> renderings {
        doc
        /*
         * asPython renders a View into a Python code format.
         */
    }

    view def <ElementTableProfile> 'Element Table Profile' {
        render asElementTable;
    }

    view def <TreeDiagramProfile> 'Tree Diagram Profile' {
        render asTreeDiagram;
    }

    view def <TextualNotationProfile> 'Textual Notation Profile' {
        render asTextualNotation;
    }

    view def <TypeScriptProfile> 'TypeScript Profile' {
        render asTypeScript;
    }

    view def <LaTeXProfile> 'LaTeX Profile' {
        render asLaTeX;
    }

    view def <PythonProfile> 'Python Profile' {
        render asPython;
    }
}
