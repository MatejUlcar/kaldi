#!/bin/bash

. ./path.sh || exit 1
. ./cmd.sh || exit 1

stage=9
nj_train=16 # number of parallel jobs
nj_test=8
lm_order=3 # language model order (n-gram quantity)

# Safety mechanism (possible running this script with modified arguments)
. utils/parse_options.sh || exit 1
[[ $# -ge 1 ]] && { echo "Wrong arguments!"; exit 1; }
train_cmd=run.pl
decode_cmd=run.pl
if [ $stage -le 0 ]; then
    # Removing previously created data (from last run.sh execution)
    rm -rf exp mfcc data/train/spk2utt data/train/cmvn.scp data/train/feats.scp data/train/split1 data/test/spk2utt data/test/cmvn.scp \ 
    data/test/feats.scp data/test/split1 data/local/lang data/lang data/lang_big data/local/tmp data/local/dict/lexiconp.txt
fi

if [ $stage -le 2 ]; then
    echo
    echo "===== PREPARING ACOUSTIC DATA ====="
    echo

    # Needs to be prepared by hand (or using self written scripts):
    #
    # spk2gender  [<speaker-id> <gender>]
    # wav.scp     [<uterranceID> <full_path_to_audio_file>]
    # text           [<uterranceID> <text_transcription>]
    # utt2spk     [<uterranceID> <speakerID>]
    # corpus.txt  [<text_transcription>]

    # Making spk2utt files
    utils/utt2spk_to_spk2utt.pl data/train/utt2spk > data/train/spk2utt
    utils/utt2spk_to_spk2utt.pl data/dev/utt2spk > data/dev/spk2utt
    utils/utt2spk_to_spk2utt.pl data/test/utt2spk > data/test/spk2utt
fi

if [ $stage -le 1 ]; then
    echo
    echo "===== FEATURES EXTRACTION ====="
    echo

    # Making feats.scp files
    mfccdir=mfcc
    # Uncomment and modify arguments in scripts below if you have any problems with data sorting
    #utils/validate_data_dir.sh data/train     # script for checking prepared data - here: for data/train directory
    #utils/validate_data_dir.sh data/dev
    utils/fix_data_dir.sh data/train          # tool for data proper sorting if needed - here: for data/train directory
    utils/fix_data_dir.sh data/dev
    steps/make_mfcc.sh --nj $nj_train --cmd "$train_cmd" data/train exp/make_mfcc/train $mfccdir || exit 1
    steps/make_mfcc.sh --nj $nj_train --cmd "$train_cmd" data/dev exp/make_mfcc/dev $mfccdir || exit 1
    steps/make_mfcc.sh --nj $nj_train --cmd "$train_cmd" data/test exp/make_mfcc/test $mfccdir || exit 1
    # add-deltas scp:data/train/feats.scp ark:data/train/delta-feats.ark
    # Making cmvn.scp files
    steps/compute_cmvn_stats.sh data/train exp/make_mfcc/train $mfccdir || exit 1
    steps/compute_cmvn_stats.sh data/dev exp/make_mfcc/dev $mfccdir || exit 1
    steps/compute_cmvn_stats.sh data/test exp/make_mfcc/test $mfccdir || exit 1
fi

if [ $stage -le 3 ]; then
    echo
    echo "===== PREPARING LANGUAGE DATA ====="
    echo

    # Needs to be prepared by hand (or using self written scripts):
    #
    # lexicon.txt           [<word> <phone 1> <phone 2> ...]
    # nonsilence_phones.txt    [<phone>]
    # silence_phones.txt    [<phone>]
    # optional_silence.txt  [<phone>]

    # Preparing language data
    utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang || exit 1
    cp -r data/lang data/lang_big
    echo
    echo "===== LANGUAGE MODEL CREATION ====="
    echo "===== MAKING lm.arpa ====="
    echo 

    loc=`which ngram-count`;
    if [ -z $loc ]; then
       if uname -a | grep 64 >/dev/null; then
               sdir=$KALDI_ROOT/tools/srilm/bin/i686-m64
       else
                       sdir=$KALDI_ROOT/tools/srilm/bin/i686
       fi
       if [ -f $sdir/ngram-count ]; then
                       echo "Using SRILM language modelling tool from $sdir"
                       export PATH=$PATH:$sdir
       else
                       echo "SRILM toolkit is probably not installed.
                               Instructions: tools/install_srilm.sh"
                       exit 1
       fi
    fi

    local=data/local
    mkdir $local/tmp
    ngram-count -order $lm_order -write-vocab $local/tmp/vocab-full.txt -wbdiscount -text $local/corpus.txt -lm $local/tmp/lm.arpa

    echo
    echo "===== MAKING G.fst ====="
    echo 
    lang=data/lang
    arpa2fst --disambig-symbol=#0 --read-symbol-table=$lang/words.txt $local/tmp/lm.arpa $lang/G.fst
    
    #lang_big=data/lang_big
    #arpa2fst --disambig-symbol=#0 --read-symbol-table=$lang_big/words.txt $local/ccGigafida-Moses-LM.arpa $lang_big/G.fst

fi

if [ $stage -le 4 ]; then

    echo
    echo "===== MONO ====="
    echo 
    utils/subset_data_dir.sh --shortest data/train 20000 data/train_short
    utils/subsed_data_dir.sh data/dev 2000 data/dev_mini
    #train
    steps/train_mono.sh --boost-silence 1.25 --nj $nj_train --cmd "$train_cmd" data/train_short data/lang exp/mono  || exit 1
    # steps/train_mono.sh --boost-silence 1.25 --totgauss 10000 --nj $nj_train --num-threads $nj_train --cmd "$train_cmd" data/train data/lang exp/mono  || exit 1
    #decode
    #utils/mkgraph.sh --mono data/lang_mini exp/mono exp/mono/graph || exit 1
    #steps/decode.sh --config conf/decode.config --nj $nj_test --cmd "$decode_cmd" exp/mono/graph data/dev_mini exp/mono/decode
    #rescore
    #steps/lmrescore.sh --cmd "$decode_cmd" data/lang data/lang_big data/test exp/mono/decode exp/mono/decode2
    #align
    steps/align_si.sh --boost-silence 1.25 --nj $nj_train --cmd "$train_cmd" data/train data/lang exp/mono exp/mono_ali || exit 1

    # echo 
    # echo "=== MONO2/full ==="
    # echo
    # steps/train_mono.sh --boost-silence 1.15 --totgauss 20000 --nj $nj --cmd "$train_cmd" data/train data/lang exp/mono2 || exit 1
    # utils/mkgraph.sh --mono data/lang exp/mono2 exp/mono2/graph || exit 1
    # steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" exp/mono2/graph data/test exp/mono2/decode

fi

if [ $stage -le 5 ]; then
    echo
    echo "===== TRI1 (first triphone pass) ====="
    echo
    #train
    steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" 2000 12000 data/train data/lang exp/mono_ali exp/tri1 || exit 1
    #decode
    #utils/mkgraph.sh data/lang exp/tri1 exp/tri1/graph || exit 1
    #steps/decode.sh --config conf/decode.config --nj $nj_test --cmd "$decode_cmd" exp/tri1/graph data/test exp/tri1/decode
    #align
    steps/align_si.sh --nj $nj_train --cmd "$train_cmd" --use-graphs true data/train data/lang exp/tri1 exp/tri1_ali
fi

if [ $stage -le 6 ]; then
    echo
    echo "===== TRI2b ====="
    echo

    # train and decode tri2b [LDA+MLLT]
    steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" 3000 20000 data/train data/lang exp/tri1_ali exp/tri2b || 
exit 1
    # utils/mkgraph.sh data/lang exp/tri2b exp/tri2b/graph || exit 1
    # steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" exp/tri2b/graph data/test exp/tri2b/decode || exit 1
    # steps/lmrescore.sh --cmd "$decode_cmd" data/lang data/lang_big data/test exp/tri2b/decode exp/tri2b/decode2
    # Align all data with LDA+MLLT system (tri2b)
    steps/align_si.sh --nj $nj_train --cmd "$train_cmd" --use-graphs true data/train data/lang exp/tri2b exp/tri2b_ali || exit 1
fi

if [ $stage -le 7 ]; then   
    echo
    echo "===== LDA+MLLT+SAT (tri3b) ====="
    echo

    ## Do LDA+MLLT+SAT, and decode.
    steps/train_sat.sh --cmd "$train_cmd" 3500 30000 data/train data/lang exp/tri2b_ali exp/tri3b || exit 1

fi
if [ $stage -le 8 ]; then
    utils/mkgraph.sh data/lang exp/tri3b exp/tri3b/graph || exit 1
    steps/decode_fmllr.sh --config conf/decode.config --nj $nj_test --num-threads 8 --cmd "$decode_cmd" \
      exp/tri3b/graph data/dev_mini exp/tri3b/decode || exit 1
    #steps/lmrescore.sh --cmd "$decode_cmd" data/lang data/lang_big data/test exp/tri3b/decode exp/tri3b/decode2 || exit 1
    # Align all data with LDA+MLLT+SAT system (tri3b)
    steps/align_fmllr.sh --nj $nj_train --cmd "$train_cmd" --use-graphs true \
       data/train data/lang exp/tri3b exp/tri3b_ali || exit 1
fi

if [ $stage -le 9 ]; then
    echo "compute pronunciation and silence probabilities, re-create lang directory"
    steps/get_prons.sh --cmd "$train_cmd" data/train data/lang exp/tri3b
    utils/dict_dir_add_pronprobs.sh --max-normalize true \
        data/local/dict \
        exp/tri3b/pron_counts_nowb.txt exp/tri3b/sil_counts_nowb.txt \
        exp/tri3b/pron_bigram_counts_nowb.txt data/local/dict_sp
    utils/prepare_lang.sh data/local/dict_sp "<UNK>" data/local/lang_tmp data/lang_sp
    cp data/lang/G.fst data/lang_sp/
    steps/align_fmllr.sh --nj $nj_train --cmd "$train_cmd" data/train data/lang_sp exp/tri3b exp/tri3b_ali_train_sp
    utils/mkgraph.sh data/lang_sp exp/tri3b exp/tri3b/graph_sp
    steps/decode_fmllr.sh --nj $nj_test --cmd "$decode_cmd" \
        exp/tri3b/graph_sp data/dev_mini exp/tri3b/decode_sp
fi
#train_cmd=slurm.pl
if [ $stage -le 10 ]; then
    echo
    echo "===== NNET ====="
    echo
    #local/run_nnet2.sh || exit 1
    #local/chain/run_tdnn.sh --stage 0 || exit 1
fi

wait

if [ $stage -le 11 ]; then
    echo
    echo "===== RNNLM ====="
    echo
    #local/rnnlm/run_rnnlm.sh || exit 1
fi

echo
echo "===== run.sh script is finished ====="
echo
