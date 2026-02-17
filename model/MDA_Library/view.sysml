package MDA_View {
    
    private import Views::*;
    private import MDA_Structure::*;

    view def <ElementTableProfile> 'Element Table Profile' {
        render asElementTable;
    }

    view def <TreeDiagramProfile> 'Tree Diagram Profile' {
        render asTreeDiagram;
    }

    view def <TextualNotationProfile> 'Textual Notation Profile' {
        render asTextualNotation;
    }
}
