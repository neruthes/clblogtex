#!/bin/bash

volid="$1"
if [[ -n "$2" ]]; then
    for i in "$@"; do
        bash "$0" "$i"
    done
    exit 0
fi



function convert_latex() {
    ts="$1"
    mdfn="$2"
    echo "[INFO] Working on $mdfn"
    yaml="vol$volid/metadata/$ts.yaml"
    doc_title="$(yq -r .title "$yaml" | safepandoc latex)"
    doc_date="$(yq -r .date "$yaml" | cut -c1-10)"
    # doc_cats="$(yq -r '.categories | join("|")' "$yaml" | while IFS='|' read -d '|' -r catname; do echo -n "\\iartcat{$catname}"; done)"
    # doc_tags="$(yq -r '.tags | join("|")' "$yaml" | while IFS='|' read -d '|' -r tagname; do echo -n "\\iarttag{$tagname}"; done)"
    echo '\iarticle'"{$doc_date}{$doc_title}{$doc_cats}{$doc_tags}" > "vol$volid/articles/$ts.1.tex"

    # sed -E -i 's|\\([a-zA-Z])|\\textbackslash{}\1|g' "vol$volid/metadata/$ts.md"

    pandoc \
        --wrap=none \
        --listings \
        --no-highlight \
        --shift-heading-level-by=-1 \
        -i "vol$volid/metadata/$ts.md" \
        -t latex \
        -o "vol$volid/articles/$ts.2.tex"

    node src/mdmacro.js "vol$volid/articles/$ts.2.tex" &

    DOC_REFLIST_RAW="$(yq -r '.references' "$yaml")"
    export DOC_REFLIST_RAW
    lines_count="$(wc -l <<< "$DOC_REFLIST_RAW" | cut -d' ' -f1)"
    if [[ "$lines_count" -gt 2 ]]; then
        (
            echo '\articlereflist{'
            node -e 'console.log(JSON.parse(process.env.DOC_REFLIST_RAW).map( x => x.url + "|" + x.title ).join("\n"))' | while read -r line; do
                ref_url="$(cut -d'|' -f1 <<< "$line" | safepandoc latex)"
                ref_title="$(cut -d'|' -f2- <<< "$line" | safepandoc latex)"
                echo '\reflistitem'"{$ref_url}{$ref_title}"
            done
            echo '}'
        )> "vol$volid/articles/$ts.3.tex"
    else
        echo "" > "vol$volid/articles/$ts.3.tex"
    fi
}
function process_file() {
    ts="$1"
    mdfn="$2"
    ### Extraxt YAML header
    f_yaml_state=init
    while IFS='' read -r line; do
        if [[ "$line" == '---' ]]; then
            if  [[ "$f_yaml_state" == init ]]; then
                f_yaml_state=main
            else
                if  [[ "$f_yaml_state" == main ]]; then
                    break
                fi
            fi
        else
            printf "%s\n" "$line"
        fi
    done < "$mdfn" | sed 's|\t|  |g' > "vol$volid/metadata/$ts.yaml"

    ### Extraxt Markdown body
    f_yaml_state=init
    sed -E 's|\t|    |g' "$mdfn" | while IFS='' read -r line; do
        if [[ "$line" == '---' ]]; then
            if  [[ "$f_yaml_state" == init ]]; then
                f_yaml_state=main
            else
                if  [[ "$f_yaml_state" == main ]]; then
                    f_yaml_state=ending
                fi
            fi
        fi
        if [[ "$f_yaml_state" == over ]]; then
            case "$line" in
                ' '*)
                    printf ''
                    ;;
                *)
                    line="$(sed -E 's|\\([a-zA-Z])|\\textbackslash{}\1|g' <<< "$line")"
                    ;;
            esac
            printf "%s\n" "$line"
        fi
        if [[ "$f_yaml_state" == ending ]]; then
            f_yaml_state=over
        fi
    done > "vol$volid/metadata/$ts.md"

    convert_latex "$ts" "$mdfn"
}

function build_index() {
    mdfn="$1"
    ts="$(TZ=UTC date --date="$(grep '^date:' "$mdfn" | head -n1 | cut -d' ' -f2-)" +%s)"
    echo "$ts|$mdfn" >> "vol$volid/db.txt"
}


mkdir -p "vol$volid"/{articles,metadata}

printf '' > "vol$volid/db.txt"


case $volid in
    1)
        year_range='201[0-9]'
        ;;
    2)
        year_range='202[0-9]'
        ;;
esac
find data/posts -name '*.md' | sort | grep -E "^data/posts/$year_range" | while read -r mdfn; do
    build_index "$mdfn"
done

sort -u "vol$volid/db.txt" -o "vol$volid/db.txt"




while read -r dbline; do
    ts="$(cut -d'|' -f1 <<< "$dbline")"
    mdfn="$(cut -d'|' -f2 <<< "$dbline")"
    process_file "$ts" "$mdfn"
done < "vol$volid/db.txt"

find vol$volid/articles -name '*.tex' | sort | while read -r texfn; do
    echo '\input'"{$texfn}"
done > "vol$volid/list.tex"
