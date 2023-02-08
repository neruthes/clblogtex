const fs = require('fs');

const texPath = process.argv[2];
const texContent = fs.readFileSync(texPath).toString();


// {% note info::本文的最終目的是編寫出能調用 Webpack 來施行構建流程的 Kotlin Build Script。 %}
let tmpOutput = texContent.replace(/\n\\\{\\% note info::(.+?)\s?\\%\\\}\n/g, '\n\\mdmacroNoteInfo{$1}\n');


fs.writeFileSync(texPath, tmpOutput);
