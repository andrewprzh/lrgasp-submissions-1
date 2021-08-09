if [ "$(uname -s)" = "Darwin" ] ; then
    sed=gsed
else
    sed=sed
fi

# remove map id
${sed} --in-place -e '/transcript_100.nnic/d' $1/iso_detect_de_novo_darwin/pbCapTrapES/read_model_map.tsv
