const CodeSting = require('./ASM/SyntaxAnalyser');
const Listing = require('./ASM/Listing');
const readline = require('readline');
const fs = require('fs');

//ASM file//////////////////////
const filepath = './test.asm';
//For syntax analyser///////////
let lexemes = [];
let equList = {};
let lineCounter = 0;
////////////////////////////////

const rd = readline.createInterface({
    input: fs.createReadStream(filepath),
    output: process.stdout,
    console: false
});


rd.on('line', function(line) {
    line.length !== 0 && lexemes.push(new CodeSting(line, lineCounter++, equList));
});


rd.on('close', function () {
    //Output lexical/syntax analysis result
    console.log('\n\n\n')
    for(let l of lexemes) {
        console.log(l.toString())
    }
    //Generate listing
    const lst = new Listing(lexemes, equList);
    lst.buildListing();
});
