const fs = require('fs');

const mdPath = process.argv[2];
const mdContent = fs.readFileSync(mdPath).toString();


const markdownOutput = mdContent.split('\n\n').map(function (block) {
    let tmp = block;
    if (!block.match(/^\s/) && !block.match(/^\`\`\`/)) {
        tmp = tmp.replace(/\\([a-z0-9])/ig, '\\textbackslash{}$1');
    };
    tmp = tmp.replace(/^(\#+\s?)/, '$1 ');
    tmp = tmp.replace(/\{%\s?note info::(.+?)\s?%\}/, '\\mdmacroNoteInfo{$1}');
    return tmp;
}).join('\n\n');


fs.writeFileSync(mdPath, markdownOutput);
