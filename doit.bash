#! /bin/bash

# ------------------------------------------------------------------------
# set up the runtime environment
# ------------------------------------------------------------------------

# exit on error
set -e

if [ "$PVSE" ] ; then
    # In order to help test portability, I eliminate all of my
    # personalizations from the PATH.
    export PATH=/usr/local/bin:/usr/bin:/bin
fi

# ------------------------------------------------------------------------
# Check the config file
# ------------------------------------------------------------------------

THIS_DIR=$(dirname $BASH_SOURCE)
CONFIG_SCRIPT=$THIS_DIR/config.bash
if [ ! -e "$CONFIG_SCRIPT" ] ; then
    echo 1>&2 Cannot find "$CONFIG_SCRIPT"
    exit 1
fi

# ------------------------------------------------------------------------
# These functions implement the computation.
# ------------------------------------------------------------------------

function setup_variables {
    [ "$ROOT_DIR" ] || ROOT_DIR=$(./scripts/find-closest-ancester-dir $THIS_DIR)
    if [ -z "$USE_NATIVE" ] ; then
	# use docker
	[ "$HOWTO" ] || HOWTO="./scripts/howto -f packages.yaml -m $ROOT_DIR"
    else
	# go native
	HOWTO=
    fi

}

function notice_regions {
    cat "$@" > temp/regions.gff
}

function count_profiles {
    (
	set -x
	cat temp/regions.gff \
	    | ./scripts/make-deseq-counts "$@" \
					  > temp/counts.txt
    )
}

function condition_names {
    (
	for s in  "$@" ; do
	    echo $s | sed 's/:.*//'
	done
    ) | uniq
}

function run_deseq2 {
    setup_variables
    (
	declare -a L
	L=( $( condition_names "$@" ) )
	if [ ${#L[*]} -ne 2 ] ; then
	    echo 1>&2 foo: expected exactly two labels
	    exit
	fi
	TAG=_${L[0]}-${L[1]}
	(
	    set -x
	    ./scripts/prep-deseq -x -s ./scripts -d temp -t ${TAG} -c temp/counts.txt "$@"

	    ${HOWTO} -m .. -c __deseq2__ \
		     Rscript ./scripts/run-deseq2 temp/params${TAG}.R

	    cat temp/output-extended${TAG}.txt \
		| ./scripts/deseq-output2results > results/results${TAG}.txt
	)
    )
}

function make_gffs_usage {
    echo 1>&2 "make_gffs: invalid arguments. check the function call"
    exit 1
}

# make_gffs CONDITION1 CONDITION2 ACCESSION1 ACCESSION2 ... (-- CHANGE_CUTOFF1 CHANGE_CUTOFF2 ...)
function make_gffs {

    # process the function parameters
    if [ -z "$1" ] ; then make_gffs_usage ; fi
    CONDITION1="$1" ; shift
    if [ -z "$1" ] ; then make_gffs_usage ; fi
    CONDITION2="$1" ; shift
    if [ -z "$1" ] ; then make_gffs_usage ; fi
    ACCESSIONS=""
    while [ -n "$1" -a "$1" != "--" ] ; do
	ACCESSIONS+=" $1"
	shift 1
    done
    if [ "$1" = "--" ] ; then shift 1 ; fi
    CHANGE_CUTOFFS="$*"
    if [ -z "$CHANGE_CUTOFFS" ] ; then
	CHANGE_CUTOFFS=2.0
    fi

    TAG=_${CONDITION1}-${CONDITION2}

    for ACCESSION in ${ACCESSIONS} ; do
	for CHANGE_CUTOFF in ${CHANGE_CUTOFFS} ; do
	    (
		set -x
		cat temp/output${TAG}.txt \
		    | ./scripts/deseq-output2gff ${ACCESSION} ${CHANGE_CUTOFF} \
						 > results/${ACCESSION}_results${TAG}_${CHANGE_CUTOFF}.gff
		cat results/${ACCESSION}_results${TAG}_${CHANGE_CUTOFF}.gff \
		    | egrep '; colour [23];' > results/${ACCESSION}_changed${TAG}_${CHANGE_CUTOFF}.gff
	    )
	done
    done
}

# ------------------------------------------------------------------------
# create empty `results` and `temp` directories
# ------------------------------------------------------------------------

(
    set -x
    cd $THIS_DIR
    rm -rf results #temp
    mkdir results #temp
)

# ------------------------------------------------------------------------
# Read the config file, which performs the actual computation.
# ------------------------------------------------------------------------

. "$CONFIG_SCRIPT"

# ------------------------------------------------------------------------
# Done.
# ------------------------------------------------------------------------
