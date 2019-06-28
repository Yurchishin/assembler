const Lex = require('./LexicalAnalyser');

class SyntaxAnalyser {

    constructor(lexeme, line, equ) {
        this.line = line;
        this.origin = lexeme;
        this.src = lexeme.toUpperCase();
        this.type = 'unknown';
        this.operands = [];
        this.operandTypes = {};
        this.label = '';
        this.equ = equ;
        this.findLexType();
    }

    getType() {
        return this.type;
    }

    findLexType() {
        switch (true) {
            case Lex.strType(Lex.textVarDecl, this.src): this.parseTxtVarDeclar(); break;
            case Lex.strType(Lex.eqDecl, this.src): this.parseEq(); break;
            case Lex.strType(Lex.varDecl, this.src): this.parseVarDeclar(); break;
            case Lex.strType(Lex.vSegStart, this.src): this.processSegStart(); break;
            case Lex.strType(Lex.vSegEnd, this.src): this.parseSegEnd(); break;
            case Lex.strType(Lex.label, this.src): this.parseLabel(); break;
            case Lex.strType(Lex.vLabelEnd, this.src): this.parseLabelEnd(); break;
            case Lex.isFunc(this.src): this.parseFunc(); break;

            case Lex.strType(Lex.vIf, this.src): this.parseIf(); break;
            case Lex.strType(Lex.vElse, this.src): this.type = 'else-directive'; break;
            case Lex.strType(Lex.vEndIf, this.src): this.type = 'endif-directive'; break;
            default: this.type = 'unknown';
        }
    }

    parseFunc() {
        for(let reg in Lex.c) {
            if(Lex.strType(Lex.c[reg](), this.src)) {
                this.type = 'func';
                this.label = Lex.isFunc(this.src, true)[1];
                this.operands = Lex.expand(Lex.c[this.label](), this.src).filter(e => e).slice(2);
                this.operandTypes = this.operands.map(o => Lex.getType(o));
                return;
            }
        }
    }

    parseLabel() {
        this.operands = Lex.expand(Lex.label, this.src).slice(1);
        this.type = 'label';
        this.label = this.operands[0];
        this.operandTypes = ['ident'];
    }

    parseLabelEnd() {
        this.operands = ['END', ...Lex.expand(Lex.vLabelEnd, this.src).slice(1)];
        this.type = 'label-end';
        this.label = this.operands[0];
        this.operandTypes = ['end_directive', 'ident' ]
    }

    processSegStart() {
        this.operands = [...Lex.expand(Lex.vSegStart, this.src).slice(1), 'SEGMENT'];
        this.type = 'seg-start';
        this.label = this.operands[0];
        this.operandTypes = ['ident', 'seg_directive' ]
    }

    parseSegEnd() {
        this.operands = [...Lex.expand(Lex.vSegEnd, this.src).slice(1), 'SEGMENT'];
        this.type = 'seg-end';
        this.label = this.operands[0];
        this.operandTypes = ['ident', 'seg_directive' ]
    }

    parseIf() {
        this.type = 'if-directive';
        this.operands = Lex.expand(Lex.vIf, this.src).slice(1);
        this.operandTypes = this.operands.map(o => Lex.getType(o))
    }

    parseEq() {
        this.type = 'eq-declar';
        const r = Lex.expand(Lex.eqDecl, this.src);
        this.equ[r[1]] = r[3];
    }

    parseTxtVarDeclar() {
        this.operands = Lex.expand(Lex.textVarDecl, this.src).slice(1);
        this.type = 'txt_declar';
        this.label = this.operands[0];
        this.operandTypes = ['ident', 'size', 'constant']
    }

    parseVarDeclar() {
        this.operands = Lex.expand(Lex.varDecl, this.src).slice(1);
        this.type = 'var_declar';
        this.label = this.operands[0];
        this.operandTypes = ['ident', 'size', 'constant']
    }

    toString() {
        let s = `${this.line}) ${this.src} -> ${this.type}`;
        this.operands.map((e, i) => {
            s += `\n\t${i+1}) ${e} ${this.operandTypes[i]} (Length: ${e.length})`;
        });
        return s;
    }

}

module.exports = SyntaxAnalyser;