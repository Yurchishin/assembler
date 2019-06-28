//CONST TYPES
const binVar = `[0|1]{8}B`;
const hexVar = `[A-F0-9]+H`;
const decVar  = `[0-9]+`;
const ident = `[A-Z][A-Z0-9]{1,8}`;
const IMM = `${binVar}|${hexVar}|${decVar}|${ident}`;

//Registers
const reg8 = `[ABCD][HL]`;
const reg32 = `(?:EAX|EBX|ECX|EDX|ESI|EDI|ESP|EBP)`;
const REG = `${reg8}|${reg32}`;
const prefix = `(DS|CS|ES|SS|GS|FS):`;

//LABEL
const label = `^\\s*([A-Z][A-Z0-9]{1,8}):\\s*$`;

// DECLARATION STRING
const varDecl = `^\\s*(${ident})\\s+(DB|DW|DD)\\s+(${binVar}|${hexVar}|${decVar})\\s*$`;
const textVarDecl = `^\\s*(${ident})\\s+(DB)\\s+\\'([A-Z0-9\\s]*)'\\s*$`;
const eqDecl = `^\\s*(${ident})\\s+(EQU)\\s+(${binVar}|${hexVar}|${decVar})\\s*$`;

//DIRECTIVES
const vSegStart = `^\\s*(${ident})\\s+SEGMENT\\s*$`;
const vIf = `^\\s*IF\\s+(${ident})\\s*$`;
const vElse = `^\\s*ELSE\\s*$`;
const vEndIf = `^\\s*ENDIF\\s*$`;
const vSegEnd = `^\\s*(${ident})\\s+ENDS\\s*$`;
const vLabelEnd = `^\\s*END\\s*$`;

//Memory
const MEM = `(?:\\s*(DWORD|WORD|BYTE)\\s+(PTR)|)\\s*(?:DS\:|CS:|SS:|GS:|FS:|ES\:|)\\s*(${ident})\\s*\\[\\s*(${reg32})\\s*\\+\\s*(${reg32})\\s*\\]\\s*`;

function strType(what, target) {
    return new RegExp(what, 'g').test(target);
}

function expand(kindOf, target) {
    return new RegExp(kindOf, 'g').exec(target);
}

function mCommand(command, op1 = null, op2 = null) {
    if(op2) {
        return () => `^\\s*(${command})\\s+(${op1})\\s*,\\s*(${op2})\\s*$`;
    } else if(op1) {
        return () => `^\\s*(${command})\\s+(${op1})\\s*$`;
    } else {
        return () => `^\\s*(${command})\\s*$`;
    }
}

const c = {
    CLI: mCommand('CLI'),
    INC: mCommand('INC', REG),
    DEC: mCommand('DEC', MEM),
    ADD: mCommand('ADD', REG, REG),
    CMP: mCommand('CMP', REG, MEM),
    AND: mCommand('AND', MEM, REG),
    MOV: mCommand('MOV', REG, IMM),
    OR: mCommand('OR', MEM, IMM),
    JBE: mCommand('JBE', ident),
    JE: mCommand('JE', ident)
};


function getType(target) {
    switch (true) {
        //mem
        case new RegExp(MEM, 'g').test(target): return 'mem';
        case new RegExp(reg32, 'g').test(target): return 'reg32';
        case new RegExp(reg8, 'g').test(target): return 'reg8';
        case new RegExp(ident, 'g').test(target): return 'ident';
        case new RegExp(binVar, 'g').test(target): return 'binConst';
        case new RegExp(hexVar, 'g').test(target): return 'hexConst';
        case new RegExp(decVar, 'g').test(target): return 'decConst';
        default: return 'unknown';
    }
}

function isFunc(line, exec = false) {
    return exec
        ? new RegExp(`^\\s*(CLI|INC|DEC|ADD|CMP|AND|MOV|OR|JBE|JE)`, 'g').exec(line)
        : new RegExp(`^\\s*(CLI|INC|DEC|ADD|CMP|AND|MOV|OR|JBE|JE)`, 'g').test(line);
}


module.exports = {
    reg8, reg32, vIf, vElse, vEndIf, eqDecl, label, c,
    varDecl, textVarDecl, vSegStart, vSegEnd, vLabelEnd,
    strType, getType, expand, isFunc, prefix
};
