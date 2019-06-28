//***FS***
const fs = require('fs');
//********
const { prefix, expand } = require('./LexicalAnalyser');

class Listing {

    constructor(lexemes, equ) {
        this.lexemes = lexemes;
        //specific data
        this.variables = {};
        this.labels = {};
        this.shift = 0;
        this.currentSegment = '';
        this.segments = {};
        this.equ = equ;
        //listing content
        this.listing = 'Listing:';

        this.ifElseStatus = 0; // 0 - no opened if/else; 1 - if returned true; 2 - if returned false; 3 - skip lexemes

    }

    getShift() {
        return this.shift
            .toString(16)
            .toUpperCase()
            .padStart(4, 0);
    }

    buildListing() {
        for (let l of this.lexemes) {
            if(this.ifElseStatus == 1 && l.type == 'else-directive') {
                this.ifElseStatus = 3;
                continue;
            } else if(this.ifElseStatus == 3 && l.type == 'else-directive') {
                this.ifElseStatus = 2;
                continue;
            }  else if(this.ifElseStatus == 3 && l.type != 'endif-directive') {
                continue;
            }

            this.listing += `\n${this.getShift()}   ${l.origin}`;
            switch (l.type) {
                case 'var_declar': case 'txt_declar' : this.processVar(l); break;
                case 'func': this.processFunc(l); break;
                case 'seg-start': this.processSegStart(l); break;
                case 'seg-end': this.processSegEnd(l); break;
                case 'label': this.processLabel(l); break;
                case 'if-directive': this.processIf(l); break;
                case 'endif-directive': this.ifElseStatus = 0; break;
                case 'label-end': case 'eq-declar' : break;
                default: this.listing += ` # Error! Bad code`;
            }
            if(l.type == 'label-end') {
                break;
            }
        }
        this.addSegmentSizes();
        fs.writeFile('listing.lst', this.listing, (err) => {
            err && console.log('Cant write listing')
        });
        console.log(`\n${'.'.repeat(40)}\n${this.listing}`);

    }

    /////////////////////////////////////////////
    // PROCESS DIRECTIVES                     //
    ///////////////////////////////////////////
    processSegStart(l) {
        if(this.currentSegment != '' ) {
            this.listing += ` # Error! No ENDS directive for '${this.currentSegment}'`;
            return;
        }
        this.currentSegment = l.label;
    }

    /**
     * Process IF
     * @param l
     */
    processIf(l) {
        if(l.operands[0] in this.equ && this.equ[l.operands[0]] != 0) {
            this.listing += ` | True`;
            this.ifElseStatus = 1;
        } else {
            this.listing += ` | False`;
            this.ifElseStatus = 3;
        }
    }

    /**
     * Process Segment ENDS
     * @param l
     */
    processSegEnd(l) {
        this.segments[this.currentSegment] = this.getShift();
        this.shift = 0;
        this.currentSegment = '';
    }

    /**
     * Process Variable declarations
     * @param l
     */
    processVar(l) {
        if(l.type == 'var_declar') {
            switch (l.operands[1]) {
                case 'DB': this.shift += 1; break;
                case 'DW': this.shift += 2; break;
                case 'DD': this.shift += 4; break;
            }
        } else {
            this.shift += l.operands[2].length
        }
        if(l.label in this.variables) {
            this.listing += ` | Warrning! '${l.label}' already declarated. Previous content will be overwritten`
        }
        this.variables[l.label] = { type: l.type.slice(0,3), size: l.operands[1], segment: this.currentSegment }
    }

    /**
     * Process Label declaration
     * @param l
     */
    processLabel(l) {
        this.labels[l.label] = this.shift
    }


    /////////////////////////////////////////////
    // HELPERS                                //
    ///////////////////////////////////////////
    addSegmentSizes() {
        this.listing += `\n\nSEGMENTS`;
        for(let s in this.segments) {
            this.listing += `\nName: ${s}, Size: ${this.segments[s]};`;
        }
    }

    generateSegPrefix(addr, ident, base, index) {
        const iSeg = this.variables[ident]['segment'];
        if(expand(prefix, addr)) {
            const seg = expand(prefix, addr)[1];
            if(seg == 'DS') {
                if(base == 'EBP' || base == 'ESP' || index == 'ESP' || index == 'ESP' || iSeg != 'DATA') {
                    this.shift++;
                }
            } else if (seg == 'SS') {
                if(base != 'EBP' && base != 'ESP' && index != 'ESP' || index != 'ESP') {
                    this.shift++;
                }
            } else if (seg == 'CS') {
                if(iSeg != 'CODE') {
                    this.shift++;
                }
            } else {
                this.shift++;
            }
        } else if(iSeg != 'DATA' || base == 'EBP' || base == 'ESP' || index == 'ESP') {
            this.shift++;
        }
    }

    /////////////////////////////////////////////
    // CALC SHIFT FOR COMMANDS                //
    ///////////////////////////////////////////
    processFunc(l) {
        switch (l.label) {
            case 'INC': this.calcInc(l); break; // +
            case 'DEC': this.calcDec(l); break; // +
            case 'ADD': this.calcAdd(l); break; // +
            case 'CLI': this.calcCli(l); break; // +
            case 'AND': this.calcAnd(l); break; // +
            case 'CMP': this.calcCmp(l); break; // +
            case 'MOV': this.calcMov(l); break; // +
            case 'OR': this.calcOr(l); break;
            case 'JBE': case 'JE': this.calcJmp(l); break;
        }
    }

    /**
     * Calc shift for INC
     * @param l
     */
    calcInc(l) {
        this.shift += l.operandTypes[0] == 'reg8' ? 2 : 1;
    }

    /**
     * Calc shift for DEC
     * @param l
     */
    calcDec(l) {
        if(!(l.operands[1] in this.variables)) {
            this.listing += ` # Error! What is '${l.operands[1]}' ?`;
            return;
        }
        this.shift += this.variables[l.operands[1]].size == 'DW'
            ? 8
            : 7;
        this.generateSegPrefix(...l.operands)
    }

    /**
     * Calc shift for ADD
     * @param l
     */
    calcAdd(l) {
        this.shift += 2;
    }

    /**
     * Calc shift for CLI
     * @param l
     */
    calcCli(l) {
        this.shift += 1;
    }

    /**
     * Calc shift for AND
     * @param l
     */
    calcAnd(l) {
        if(!(l.operands[1] in this.variables)) {
            this.listing += ` | Error! What is '${l.operands[1]}' ?`;
            return;
        }
        this.shift += 7;
        this.generateSegPrefix(...l.operands)
    }

    /**
     * Calc shift for CMP
     * @param l
     */
    calcCmp(l) {
        if(!(l.operands[2] in this.variables)) {
            this.listing += ` | Error! What is '${l.operands[2]}' ?`;
            return;
        }
        this.shift += 7;
        this.generateSegPrefix(...l.operands.slice(1))
    }

    /**
     * Calc shift for MOV
     * @param l
     */
    calcMov(l) {
        if(l.operandTypes[1] == 'ident') {
            if(l.operands[1] in this.equ) {
                l.operands[1] = this.equ[l.operands[1]];
            } else {
                this.listing += ` # Error! What is '${l.operands[1]}' ?`;
                return null;
            }
        }
        this.shift += l.operandTypes[0] == 'reg8' ? 2 : 5;
    }

    /**
     * Calc shift for JMP
     * @param l
     */
    calcJmp(l) {
        if(l.operands[0] in this.labels && (this.shift - this.labels[l.operands[0]]) <= 127) {
            this.shift += 2;
        } else {
            this.shift += 6;
        }
    }

    /**
     * Calc shift for OR
     * @param l
     */
    calcOr(l) {
        if(l.operandTypes[4] == 'ident') {
            if(l.operands[4] in this.equ) {
                l.operands[4] = this.equ[l.operands[4]];
            } else {
                this.listing += ` | Error! What is '${l.operands[4]}' ?`;
                return null;
            }
        }
        if(!(l.operands[1] in this.variables)) {
            this.listing += ` | Error! What is '${l.operands[1]}' ?`;
            return;
        }
        switch (this.variables[l.operands[1]].size) {
            case 'DB': this.shift += 8; break;
            case 'DW': this.shift += 10; break;
            case 'DD': this.shift += 11; break;
        }
        this.generateSegPrefix(...l.operands)
    }
}

module.exports = Listing;
