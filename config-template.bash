# Uncomment to use native executables
#USE_NATIVE=1

# ------------------------------------------------------------------------

# The function, `notice_regions`, is used to define the regions for the
# analysis. It's arguments are the same as `cat`, so it can read
# directly from a file or serve as an sink. E.g,
#
#     notice_regions regions.gff
#     fgrep '	gene	' genome.gff | notice_regions


GENOME=.../path/to/genome
ACCESSION=NC_XXXXXX

fgrep '	gene	' ${GENOME}/${ACCESSION}.gff | notice_regions

# ------------------------------------------------------------------------

# The function, `count_profiles`, takes a list of genomic profiles
# generated using the Filiatrault2010 scripts and produces a count
# table that will be used as input for the DESeq2 runs. Each profile
# specified put be prefixed with a unique label and a ":". The label
# is used when specifying the replicates in each condition. E.g.,
#
#     count_profiles wt1:.../wt1.profile wt2:.../wt2.profile \ 
#         exp1:.../exp1.profile exp2:.../exp2.profile \ 
#         exp3:.../exp3.profile
#
# Be sure to specify all profiles that will be used in instances of
# `run_deseq2`.

PROFILES=.../path/to/profiles

count_profiles \
    ctrl_rep1:${PROFILES}/${ACCESSION}_ctrl_rep1.sinister.profile \
    ctrl_rep2:${PROFILES}/${ACCESSION}_ctrl_rep2.sinister.profile \
    ctrl_rep3:${PROFILES}/${ACCESSION}_ctrl_rep3.sinister.profile \
    trmt1_rep1:${PROFILES}/${ACCESSION}_trmt1_rep1.sinister.profile \
    trmt1_rep2:${PROFILES}/${ACCESSION}_trmt1_rep2.sinister.profile \
    trmt1_rep3:${PROFILES}/${ACCESSION}_trmt1_rep3.sinister.profile \
    trmt2_rep1:${PROFILES}/${ACCESSION}_trmt2_rep1.sinister.profile \
    trmt2_rep2:${PROFILES}/${ACCESSION}_trmt2_rep2.sinister.profile \
    trmt2_rep3:${PROFILES}/${ACCESSION}_trmt2_rep3.sinister.profile

# ------------------------------------------------------------------------

# The function, `run_deseq2`, takes a list of replicate labels and
# performs differential analysis using DESeq2. Each replication is
# prefaced with a label denoting the condition to which it
# belongs. E.g.,
#
#     run_deseq1 wt:wt1 wt:wt2 exp:exp1 exp:exp2 exp:exp3

run_deseq2 ctrl:ctrl_rep1 ctrl:ctrl_rep2 ctrl:ctrl_rep3 \
	   trmt1:trmt1_rep1 trmt1:trmt1_rep2 trmt1:trmt1_rep3
# trmt2:trmt2_rep3 - don't use 'trmt2_rep3'! bad quality!
run_deseq2 ctrl:ctrl_rep1 ctrl:ctrl_rep2 ctrl:ctrl_rep3 \
	   trmt2:trmt2_rep1 trmt2:trmt2_rep2 #trmt2:trmt2_rep3

# ------------------------------------------------------------------------

# The function, `make_gffs`, is used to produce Artemis loadable GFF files. The first two arguments to `make_gffs` are the two conditions specified by a previous call to `run_deseq2`. The next argument is the accession for which to produce GFF files. E.g.,
#
#     make_gffs wt exp NC_XXXXXX
#
# By default a fold change cutoff of 2.0 is used. This can be changed
# by adding a list of fold changes cutoffs at the end of the
# invocation, after "--". E.g.,
#
#     make_gffs wt exp NC_XXXXXX -- 10.0 2.0 1.5
#
# A set of GFF files are produced for each cutoff specified.

CHANGE_CUTOFFS=
CHANGE_CUTOFFS+=" 2.0"
# CHANGE_CUTOFFS+=" 1.5"

make_gffs ctrl trmt1 ${ACCESSION} -- ${CHANGE_CUTOFFS}
make_gffs ctrl trmt2 ${ACCESSION} -- ${CHANGE_CUTOFFS}

